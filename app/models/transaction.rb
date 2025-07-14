class Transaction < ApplicationRecord
  # Relaciones (opcional, pero buena práctica)
  # Esto asume que tendríamos Wallet.id como llave foránea.
  # Por ahora, como usamos address como identificador, no son relaciones directas de AR.
  # belongs_to :sender_wallet, class_name: 'Wallet', foreign_key: :sender_address, primary_key: :address
  # belongs_to :receiver_wallet, class_name: 'Wallet', foreign_key: :receiver_address, primary_key: :address

  # UUID debe estar presente y ser único
  validates :uuid, presence: true, uniqueness: true

  # Direcciones de remitente y receptor deben estar presentes y tener el formato correcto
  validates :sender_address, presence: true, format: { with: /\A[0-9a-f]{64}\z/, message: "debe tener 64 caracteres hexadecimales" }
  validates :receiver_address, presence: true, format: { with: /\A[0-9a-f]{64}\z/, message: "debe tener 64 caracteres hexadecimales" }

  # El monto debe ser un número decimal positivo
  validates :amount, numericality: { greater_than: 0 }

  # Nonce, raw_transaction_message y signature deben estar presentes
  validates :nonce, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :raw_transaction_message, presence: true
  validates :signature, presence: true

  # El estado debe estar presente y ser uno de los permitidos
  validates :status, presence: true, inclusion: { in: %w[pending confirmed failed], message: "%{value} no es un estado válido" }

  # Callback para asignar un UUID antes de crear una transacción si no se ha asignado
  before_validation :assign_uuid, on: :create

  private

  def assign_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
