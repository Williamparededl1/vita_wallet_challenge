
require "base64"
require "ecdsa"
require "digest/sha3"

class TransactionProcessor
  class ValidationError < StandardError; end

  def initialize(signed_transaction_b64)
    @signed_transaction_b64 = signed_transaction_b64
    @errors = []
    @transaction_data = nil
  end


  def process
    ApplicationRecord.transaction do
      decode_signed_transaction
      validate_transaction_format
      verify_signature
      validate_balance_and_nonce
      create_and_update_wallets
      create_transaction_record
    end


    @new_transaction
  rescue ValidationError => e
    @errors << e.message
    nil
  rescue => e
    @errors << "Error inesperado al procesar la transacción: #{e.message}"
    Rails.logger.error "TransactionProcessor Error: #{e.message}\n#{e.backtrace.join("\n")}"
    nil
  end


  def errors
    @errors
  end

  private


  def decode_signed_transaction
    parts = @signed_transaction_b64.split("_")
    raise ValidationError, "Formato de transacción firmada inválido" unless parts.length == 2

    @raw_transaction_message_b64 = parts[0]
    @signature_b64 = parts[1]

    @raw_transaction_message = Base64.decode64(@raw_transaction_message_b64)
    @signature = Base64.decode64(@signature_b64)


    msg_parts = @raw_transaction_message.split(";")
    raise ValidationError, "Formato del mensaje de transacción inválido" unless msg_parts.length == 4

    @sender_public_key_hex = msg_parts[0]
    @receiver_address = msg_parts[1]
    @amount_raw = msg_parts[2]
    @nonce_raw = msg_parts[3]


    @amount = convert_amount_from_vitcoin_format(@amount_raw)
    @nonce = @nonce_raw.to_i


    @sender_address = self.class.derive_address_from_public_key(@sender_public_key_hex)

    @transaction_data = {
      sender_public_key_hex: @sender_public_key_hex,
      sender_address: @sender_address,
      receiver_address: @receiver_address,
      amount: @amount,
      nonce: @nonce,
      raw_transaction_message: @raw_transaction_message,
      signature: @signature
    }
  rescue ArgumentError => e
    raise ValidationError, "Error al decodificar Base64: #{e.message}"
  end


  def validate_transaction_format
    raise ValidationError, "La dirección del remitente no cumple con el formato hexagonal de 64 caracteres." unless @sender_address =~ /\A[0-9a-f]{64}\z/
    raise ValidationError, "La dirección del receptor no cumple con el formato hexagonal de 64 caracteres." unless @receiver_address =~ /\A[0-9a-f]{64}\z/
    raise ValidationError, "El monto debe ser un número entero positivo." unless @amount_raw.to_i.to_s == @amount_raw && @amount_raw.to_i > 0
    raise ValidationError, "El nonce debe ser un número entero no negativo." unless @nonce_raw.to_i.to_s == @nonce_raw && @nonce_raw.to_i >= 0
  end


  def verify_signature
    group = ECDSA::Group::Secp256k1
    public_key = ECDSA::Format::Point.decode(group, [ @sender_public_key_hex ].pack("H*"))


    raw_signature_der = @signature

    unless ECDSA::Verification.verify(public_key, Digest::SHA3.digest(256, @raw_transaction_message), raw_signature_der)
      raise ValidationError, "La firma de la transacción es inválida."
    end
  rescue ArgumentError => e
    raise ValidationError, "Error al procesar la llave pública o firma: #{e.message}"
  rescue ECDSA::DecodeError => e
    raise ValidationError, "Error al decodificar la llave pública o firma: #{e.message}"
  end


  def validate_balance_and_nonce
    @sender_wallet = Wallet.find_by(address: @sender_address)

    if @sender_wallet.nil?

      raise ValidationError, "La billetera del remitente no existe o no tiene balance." unless @amount == 0
    end


    if @sender_wallet

      unless @sender_wallet.is_master?
        raise ValidationError, "Balance insuficiente en la billetera de origen." if @sender_wallet.balance < @amount
      end


      expected_nonce = @sender_wallet.last_nonce + 1
      raise ValidationError, "Nonce incorrecto. Se esperaba #{expected_nonce} pero se recibió #{@nonce}." unless @nonce == expected_nonce
    end
  end



  def create_and_update_wallets
    @sender_wallet = Wallet.find_or_create_by_address(@sender_address, public_key_hex: @sender_public_key_hex)
    @sender_wallet.balance -= @amount
    @sender_wallet.outcoming_tx_count += 1
    @sender_wallet.last_nonce = @nonce
    @sender_wallet.save!


    @receiver_wallet = Wallet.find_or_create_by_address(@receiver_address)
    @receiver_wallet.balance += @amount
    @receiver_wallet.incoming_tx_count += 1
    @receiver_wallet.save!
  end


  def create_transaction_record
    @new_transaction = Transaction.create!(
      uuid: SecureRandom.uuid,
      sender_address: @sender_address,
      receiver_address: @receiver_address,
      amount: @amount,
      nonce: @nonce,
      raw_transaction_message: @raw_transaction_message,
      signature: Base64.encode64(@signature).strip,
      status: "confirmed"
    )
  end


  def convert_amount_from_vitcoin_format(amount_str)
    BigDecimal(amount_str) / BigDecimal("1_000_000") # 6 decimales
  rescue ArgumentError
    raise ValidationError, "Monto con formato inválido: #{amount_str}"
  end


  def self.derive_address_from_public_key(public_key_hex)
    public_key_bytes = [ public_key_hex ].pack("H*")


    sha3_256_hash_bytes = Digest::SHA3.digest(256, public_key_bytes)


    sha3_224_hex = sha3_256_hash_bytes.unpack("H*").first

    sha3_224_hex
  rescue ArgumentError => e

    Rails.logger.error "Error al derivar dirección de llave pública: #{e.message}"
    raise ValidationError, "Formato de llave pública inválido para derivación de dirección."
  end
end
