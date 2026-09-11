class Admin::TransactionsController < ApplicationController
  before_action :admin_user
  before_action :set_transaction, only: [:show]

  def index
    transactions =
      Transaction
        .includes(
          :user,
          :organization
        )
        .order(
          date: :desc,
          id: :desc
        )

    if params[:q].present?
      keyword = "%#{params[:q].strip}%"

      transactions =
        transactions
          .joins(:user, :organization)
          .where(
            "users.username LIKE :keyword
             OR users.public_id LIKE :keyword
             OR organizations.name LIKE :keyword
             OR organizations.public_id LIKE :keyword
             OR transactions.category LIKE :keyword",
            keyword: keyword
          )
    end

    if params[:transaction_type].present?
      transactions =
        transactions.where(
          transaction_type:
            params[:transaction_type]
        )
    end

    if params[:transaction_scope].present?
      transactions =
        transactions.where(
          transaction_scope:
            params[:transaction_scope]
        )
    end

    if params[:organization_id].present?
      transactions =
        transactions.where(
          organization_id:
            params[:organization_id]
        )
    end

    if params[:user_id].present?
      transactions =
        transactions.where(
          user_id:
            params[:user_id]
        )
    end

    if params[:from_date].present?
      transactions =
        transactions.where(
          "date >= ?",
          params[:from_date]
        )
    end

    if params[:to_date].present?
      transactions =
        transactions.where(
          "date <= ?",
          params[:to_date]
        )
    end

    render json: transactions.map { |transaction|
      transaction_json(transaction)
    }
  end

  def show
    render json: transaction_json(
      @transaction,
      detailed: true
    )
  end

  private

  def set_transaction
    @transaction =
      Transaction
        .includes(
          :user,
          :organization
        )
        .find(params[:id])
  end

  def transaction_json(
    transaction,
    detailed: false
  )
    data = {
      id: transaction.id,
      transaction_type: transaction.transaction_type,
      transaction_scope: transaction.transaction_scope,
      category: transaction.category,
      amount: transaction.amount,
      date: transaction.date,
      payment_method: transaction.payment_method,
      account_linked: transaction.account_id.present?,
      user: transaction.user ? {
        id: transaction.user.id,
        username: transaction.user.username,
        public_id: transaction.user.public_id
      } : nil,
      organization: transaction.organization ? {
        id: transaction.organization.id,
        name: transaction.organization.name,
        public_id: transaction.organization.public_id
      } : nil
    }

    if detailed
      data[:created_at] = transaction.created_at
      data[:updated_at] = transaction.updated_at
    end

    data
  end
end