class Wallet < ApplicationRecord
  # La dirección debe estar presente y ser única
  validates :address, presence: true, uniqueness: true, format: { with: /\A[0-9a-f]{64}\z/, message: "debe tener 64 caracteres hexadecimales" }

  # La llave pública hexadecimal debe estar presente
  validates :public_key_hex, presence: true

  # El balance no puede ser negativo, a menos que sea la billetera maestra
  validates :balance, numericality: { greater_than_or_equal_to: 0 }, unless: :is_master?

  # El balance puede ser negativo si es la billetera maestra
  validates :balance, numericality: { allow_nil: true }, if: :is_master?

  # Los contadores de transacciones deben ser números enteros no negativos
  validates :incoming_tx_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :outcoming_tx_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # El último nonce debe ser un número entero no negativo (o -1)
  validates :last_nonce, numericality: { only_integer: true, greater_than_or_equal_to: -1 }

  # --- Métodos de Clase ---
  # Método para encontrar una billetera por su dirección, o crearla si no existe
  def self.find_or_create_by_address(address, public_key_hex: nil)
    wallet = find_by(address: address)
    unless wallet
      # Una billetera "existe" solo después de haber recibido dinero por primera vez.
      # Por ahora, la creamos con los valores por defecto si no existe.
      # La public_key_hex solo es conocida si es el remitente.
      wallet = create!(address: address, public_key_hex: public_key_hex || "unknown") # Usamos 'unknown' si no tenemos la PK
    end
    wallet
  end

  # --- Lógica para la billetera Maestra ---
  # Método de clase para obtener la billetera maestra
  def self.master_wallet
    # Busca la billetera maestra. Si no existe, la crea.
    # En un entorno real, esta se inicializaría una sola vez, quizás en un seeder o setup inicial.
    # Por simplicidad para la prueba, la crearemos si no la encontramos.
    # La dirección y llave pública de la maestra son arbitrarias para este ejemplo,
    # pero en una implementación real serían fijas y conocidas.
    find_or_create_by(is_master: true) do |wallet|
      wallet.address = ENV.fetch("MASTER_WALLET_ADDRESS", "0000000000000000000000000000000000000000000000000000000000000000") # Usar una dirección dummy o desde ENV
      wallet.public_key_hex = ENV.fetch("MASTER_WALLET_PUBLIC_KEY_HEX", "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000") # dummy o desde ENV
      wallet.balance = 0.0 # O un balance inicial si la master empieza con fondos
    end
  end
end
