
module Api
  module V1
    class TransactionsController < ApplicationController
      def create
        signed_transaction_b64 = params[:signed_transaction]

        if signed_transaction_b64.blank?
          render json: { error: "Parámetro 'signed_transaction' faltante o vacío." }, status: :unprocessable_entity
          return
        end


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
          }, status: :created
        else

          render json: { errors: processor.errors }, status: :unprocessable_entity
        end
      rescue StandardError => e

        Rails.logger.error "Error en TransactionsController#create: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { error: "Ocurrió un error inesperado al procesar la transacción." }, status: :internal_server_error
      end


      def show
        @transaction = Transaction.find_by(uuid: params[:uuid])

        if @transaction

          render json: {
            uuid: @transaction.uuid,
            sender_address: @transaction.sender_address,
            receiver_address: @transaction.receiver_address,
            amount: @transaction.amount,
            nonce: @transaction.nonce,
            raw_transaction_message: @transaction.raw_transaction_message,
            signature: @transaction.signature,
            status: @transaction.status,
            created_at: @transaction.created_at,
            updated_at: @transaction.updated_at
          }, status: :ok
        else

          render json: { error: "Transacción no encontrada" }, status: :not_found
        end
      end
    end
  end
end
