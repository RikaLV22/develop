class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :update, :destroy]

  def index
    transactions = Transaction
      .where(organization_id: @current_user.organization_id)
      .order(date: :desc)
      .includes(:user)

    render json: transactions.map { |t| transaction_json(t) }
  end

  def show
    render json: transaction_json(@transaction)
  end

  def create
    transaction = Transaction.new(transaction_params)
    transaction.user_id = @current_user.id
    transaction.organization_id = @current_user.organization_id

    if transaction.save
      render json: transaction_json(transaction), status: :created
    else
      render json: { errors: transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @transaction.update(transaction_params)
      render json: transaction_json(@transaction), status: :ok
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    render json: { message: '削除しました' }
  end

  private

  def transaction_json(t)
    t.as_json(
      except: [:created_at, :updated_at, :organization_id, :user_id]
    )
    .merge(
      user_name: t.user&.username || "不明"
    )
  end

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