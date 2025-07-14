
module Api
  module V1
    class WalletsController < ApplicationController
      def show
        @wallet = Wallet.find_by(address: params[:address])

        if @wallet

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
          }, status: :ok
        else

          render json: { error: "Billetera no encontrada" }, status: :not_found
        end
      end
    end
  end
end
