class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :update, :destroy]

  def index
    transactions = Transaction
      .where(organization_id: @current_user.organization_id)
      .where(
        transaction_scope: params[:transaction_scope].presence || "organization"
      )
      .order(date: :desc)
      .includes(:user)

    if params[:transaction_scope] == "personal"
      transactions = transactions.where(user_id: @current_user.id)
    end

    render json: transactions.map { |t| transaction_json(t) }
  end

  def summary
    year = params[:year].presence&.to_i || Date.current.year

    organization_transactions = Transaction.where(
      organization_id: @current_user.organization_id,
      transaction_scope: "organization"
    )

    organization_member_transactions =
      organization_transactions.where(
        user_id: @current_user.id
      )

    personal_transactions = Transaction.where(
      organization_id: @current_user.organization_id,
      user_id: @current_user.id,
      transaction_scope: "personal"
    )

    users = User.where(
      organization_id: @current_user.organization_id
    )

    render json: {
      organization: build_summary(
        organization_transactions
      ),

      organization_member: build_summary(
        organization_member_transactions
      ),

      personal: build_summary(
        personal_transactions
      ),

      users: users.map do |user|
        user_transactions =
          organization_transactions.where(
            user_id: user.id
          )

        {
          user_id: user.id,
          user_name: user.username,

          trends: {
            week: build_daily_summary(
              user_transactions,
              Date.current.beginning_of_week(:monday),
              Date.current.beginning_of_week(:monday) + 6.days
            ),

            month: build_daily_summary(
              user_transactions,
              Date.current.beginning_of_month,
              Date.current.end_of_month
            ),

            year: build_monthly_summary(
              user_transactions,
              year
            )
          }
        }
      end
    }
  end

  def history_summary
    year = params[:year].presence&.to_i || Date.current.year

    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)

    organization_transactions = Transaction.where(
      organization_id: @current_user.organization_id,
      transaction_scope: "organization",
      date: start_date..end_date
    )

    organization_member_transactions =
      organization_transactions.where(
        user_id: @current_user.id
      )

    personal_transactions = Transaction.where(
      organization_id: @current_user.organization_id,
      user_id: @current_user.id,
      transaction_scope: "personal",
      date: start_date..end_date
    )

    users = User.where(
      organization_id: @current_user.organization_id
    )

    render json: {
      year: year,

      organization: build_summary_for_year(
        organization_transactions,
        year
      ),

      organization_member: build_summary_for_year(
        organization_member_transactions,
        year
      ),

      personal: build_summary_for_year(
        personal_transactions,
        year
      ),

      users: users.map do |user|
        user_transactions =
          organization_transactions.where(
            user_id: user.id
          )

        {
          user_id: user.id,
          user_name: user.username,
          monthly: build_monthly_summary(
            user_transactions,
            year
          )
        }
      end,

      transactions: organization_transactions
        .includes(:user)
        .order(date: :desc)
        .map { |t| transaction_json(t) }
    }
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
      puts transaction.errors.full_messages

      render json: {
        errors: transaction.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @transaction.update(transaction_params)
      render json: transaction_json(@transaction), status: :ok
    else
      render json: {
        errors: @transaction.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy

    render json: {
      message: "削除しました"
    }
  end

  private

  def build_summary_for_year(transactions, year)
    {
      total: build_period_summary(transactions),

      monthly: build_monthly_summary(
        transactions,
        year
      ),

      category_expense: build_category_expense(
        transactions
      )
    }
  end

  def build_summary(transactions)
    today = Date.current

    current_month_transactions = transactions.where(
      date: today.beginning_of_month..today.end_of_month
    )

    current_year_transactions = transactions.where(
      date: today.beginning_of_year..today.end_of_year
    )

    {
      total: build_period_summary(
        transactions
      ),

      current_month: build_period_summary(
        current_month_transactions
      ),

      current_year: build_period_summary(
        current_year_transactions
      ),

      monthly: build_monthly_summary(
        transactions,
        today.year
      ),

      category_expense: build_category_expense(
        transactions
      )
    }
  end

  def build_period_summary(transactions)
    income = transactions
      .where(transaction_type: "income")
      .sum(:amount)

    expense = transactions
      .where(transaction_type: "expense")
      .sum(:amount)

    {
      income: income,
      expense: expense,
      balance: income - expense
    }
  end

  def build_monthly_summary(transactions, year)
    (1..12).map do |month|
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      monthly_transactions = transactions.where(
        date: start_date..end_date
      )

      summary = build_period_summary(
        monthly_transactions
      )

      {
        month: month,
        income: summary[:income],
        expense: summary[:expense],
        balance: summary[:balance]
      }
    end
  end

  def build_daily_summary(transactions, start_date, end_date)
    (start_date..end_date).map do |date|
      daily_transactions = transactions.where(
        date: date
      )

      summary = build_period_summary(
        daily_transactions
      )

      {
        date: date.to_s,
        income: summary[:income],
        expense: summary[:expense],
        balance: summary[:balance]
      }
    end
  end

  def build_category_expense(transactions)
    transactions
      .where(transaction_type: "expense")
      .group(:category)
      .sum(:amount)
      .map do |category, amount|
        {
          category: category,
          amount: amount
        }
      end
      .sort_by { |item| -item[:amount] }
  end

  def transaction_json(t)
    t.as_json(
      except: [
        :created_at,
        :updated_at,
        :organization_id
      ]
    ).merge(
      user_name: t.user&.username || "不明",
      account_name: t.account&.bank&.name,
      account_number: t.account&.account_number
    )
  end

  def set_transaction
    @transaction = Transaction.find_by(
      id: params[:id],
      user_id: @current_user.id
    )

    unless @transaction
      render json: {
        error: "権限がありません"
      }, status: :forbidden
    end
  end

  def transaction_params
    params.require(:transaction).permit(
      :transaction_type,
      :category,
      :amount,
      :date,
      :payment_method,
      :card_number,
      :account_id,
      :transaction_scope
    )
  end
end