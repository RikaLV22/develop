class TransactionsController < ApplicationController
    before_action :set_transaction, only: [:show, :update, :destroy]

    def index
        transactions = Transaction
            .where(user_id: @current_user.id)
            .order(date: :desc)

        render json: transactions
    end

    def show
        render json: @transaction
    end

    def create
        transaction = Transaction.new(transaction_params)
        transaction.user_id = @current_user.id
        transaction.organization_id = @current_user.organization_id

        if transaction.save
            render json: transaction, status: :created
        else
            render json: { errors: transaction.errors.full_messages },
                    status: :unprocessable_entity
        end
    end

    def update
        if @transaction.update(transaction_params)
            render json: @transaction, status: :ok
        else
            render json: {errors: @transaction.errors.full_messages},
                    status: :unprocessable_entity
        end
    end

    def destroy
        @transaction.destroy
        render json: {message: '削除しました'}
    end

    private

    def set_transaction
        @transaction = Transaction.find_by(
            id: params[:id],
            user_id: @current_user.id
        )

        unless @transaction
            render json: { error: '権限がありません' }, status: :forbidden
        end
    end

    def transaction_params
        params.require(:transaction).permit(
            :transaction_type,
            :category,
            :amount,
            :date,
            :payment_method,
            :card_number
        )
    end
end