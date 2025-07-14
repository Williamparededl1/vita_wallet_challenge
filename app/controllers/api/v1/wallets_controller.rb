# app/controllers/api/v1/wallets_controller.rb
module Api
  module V1
    class WalletsController < ApplicationController
      # GET /api/v1/addresses/:address
      def show
        # Buscar la billetera por la dirección proporcionada en los parámetros de la URL
        @wallet = Wallet.find_by(address: params[:address])

        if @wallet
          # Si la billetera existe, devolver su información en formato JSON
          render json: {
            address: @wallet.address,
            public_key_hex: @wallet.public_key_hex,
            balance: @wallet.balance,
            is_master: @wallet.is_master,
            incoming_tx_count: @wallet.incoming_tx_count,
            outcoming_tx_count: @wallet.outcoming_tx_count,
            last_nonce: @wallet.last_nonce,
            created_at: @wallet.created_at,
            updated_at: @wallet.updated_at
          }, status: :ok # Código de estado HTTP 200 OK
        else
          # Si la billetera no se encuentra, devolver un error 404 Not Found
          render json: { error: "Billetera no encontrada" }, status: :not_found
        end
      end
    end
  end
end
