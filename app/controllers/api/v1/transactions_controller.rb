# app/controllers/api/v1/transactions_controller.rb
module Api
  module V1
    class TransactionsController < ApplicationController
      # POST /api/v1/transactions
      def create
        # La transacción firmada viene en el cuerpo de la solicitud (body)
        signed_transaction_b64 = params[:signed_transaction]

        if signed_transaction_b64.blank?
          render json: { error: "Parámetro 'signed_transaction' faltante o vacío." }, status: :unprocessable_entity # 422
          return
        end

        # Usar el TransactionProcessor para manejar la lógica compleja
        processor = TransactionProcessor.new(signed_transaction_b64)
        @transaction = processor.process

        if @transaction
          render json: {
            uuid: @transaction.uuid,
            sender_address: @transaction.sender_address,
            receiver_address: @transaction.receiver_address,
            amount: @transaction.amount,
            nonce: @transaction.nonce,
            status: @transaction.status,
            created_at: @transaction.created_at
          }, status: :created # Código de estado HTTP 201 Created
        else
          # Si hay errores en el procesamiento (por ejemplo, validación fallida)
          render json: { errors: processor.errors }, status: :unprocessable_entity # 422 Unprocessable Entity
        end
      rescue StandardError => e
        # Captura errores inesperados para evitar que la aplicación se caiga
        Rails.logger.error "Error en TransactionsController#create: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { error: "Ocurrió un error inesperado al procesar la transacción." }, status: :internal_server_error # 500
      end

      # GET /api/v1/transactions/:uuid
      def show
        # Buscar la transacción por su UUID
        @transaction = Transaction.find_by(uuid: params[:uuid])

        if @transaction
          # Si la transacción existe, devolver su información en formato JSON
          render json: {
            uuid: @transaction.uuid,
            sender_address: @transaction.sender_address,
            receiver_address: @transaction.receiver_address,
            amount: @transaction.amount,
            nonce: @transaction.nonce,
            raw_transaction_message: @transaction.raw_transaction_message, # Puede ser útil para depurar
            signature: @transaction.signature, # Puede ser útil para depurar
            status: @transaction.status,
            created_at: @transaction.created_at,
            updated_at: @transaction.updated_at
          }, status: :ok # 200 OK
        else
          # Si la transacción no se encuentra, devolver un error 404 Not Found
          render json: { error: "Transacción no encontrada" }, status: :not_found
        end
      end
    end
  end
end
