class PersonalTransactionsController < ApplicationController
  before_action :logged_in_user

  def index
    transactions =
      personal_transactions
        .includes(:user)
        .order(date: :desc, id: :desc)

    render json: transactions.as_json(
      include: {
        user: {
          only: [:id, :username]
        }
      }
    )
  end

  def show
    transaction =
      personal_transactions.find(params[:id])

    render json: transaction
  end

  def create
    transaction =
      @current_user.transactions.build(
        personal_transaction_params
      )

    transaction.organization_id =
      @current_user.organization_id

    transaction.transaction_scope =
      "personal"

    if transaction.save
      render json: transaction, status: :created
    else
      render json: {
        errors: transaction.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    transaction =
      personal_transactions.find(params[:id])

    if transaction.update(
      personal_transaction_params
    )
      render json: transaction
    else
      render json: {
        errors: transaction.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    transaction =
      personal_transactions.find(params[:id])

    transaction.destroy

    render json: {
      message: "取引を削除しました"
    }
  end

  def summary
    today = Date.current

    year =
      params[:year].presence&.to_i ||
      today.year

    transactions =
      personal_transactions

    render json: {
      personal:
        build_summary(
          transactions,
          year,
          today
        )
    }
  end

  def history_summary
    year =
      params[:year].presence&.to_i ||
      Date.current.year

    transactions =
      personal_transactions

    year_transactions =
      transactions.where(
        date: year_date_range(year)
      )

    transaction_list =
      year_transactions
        .includes(
          :user,
          account: :bank
        )
        .order(
          date: :desc,
          id: :desc
        )
        .map do |transaction|

      {
        id: transaction.id,

        user_name:
          transaction.user&.username || "不明",

        transaction_type:
          transaction.transaction_type,

        category:
          transaction.category,

        amount:
          transaction.amount,

        date:
          transaction.date.to_s,

        payment_method:
          transaction.payment_method,

        card_number:
          transaction.respond_to?(:card_number) ?
            transaction.card_number :
            nil,

        account_id:
          transaction.account_id,

        account_name:
          transaction.account&.bank&.name,

        account_number:
          transaction.account&.account_number
      }
    end

    render json: {
      year: year,

      personal:
        build_history_summary(
          transactions,
          year
        ),

      transactions: transaction_list
    }
  end

  private

  def personal_transactions
    Transaction.where(
      organization_id:
        @current_user.organization_id,
      user_id:
        @current_user.id,
      transaction_scope:
        "personal"
    )
  end

  def personal_transaction_params
    params
      .require(:transaction)
      .permit(
        :transaction_type,
        :category,
        :amount,
        :date,
        :payment_method,
        :account_id
      )
  end

  def year_date_range(year)
    Date.new(year, 1, 1)..Date.new(year, 12, 31)
  end

  def current_month_date_range(today)
    today.beginning_of_month..today.end_of_month
  end

  def build_summary(
    transactions,
    year,
    today
  )
    current_month_transactions =
      transactions.where(
        date:
          current_month_date_range(today)
      )

    year_transactions =
      transactions.where(
        date:
          year_date_range(year)
      )

    {
      total:
        build_period_summary(
          year_transactions
        ),

      current_month:
        build_period_summary(
          current_month_transactions
        ),

      current_year:
        build_period_summary(
          year_transactions
        ),

      monthly:
        build_monthly_summary(
          transactions,
          year
        ),

      category_expense:
        build_category_expense(
          year_transactions
        )
    }
  end

  def build_history_summary(
    transactions,
    year
  )
    year_transactions =
      transactions.where(
        date:
          year_date_range(year)
      )

    {
      total:
        build_period_summary(
          year_transactions
        ),

      monthly:
        build_monthly_summary(
          transactions,
          year
        ),

      category_expense:
        build_category_expense(
          year_transactions
        )
    }
  end

  def build_period_summary(
    transactions
  )
    income =
      transactions
        .where(
          transaction_type: "income"
        )
        .sum(:amount)

    expense =
      transactions
        .where(
          transaction_type: "expense"
        )
        .sum(:amount)

    {
      income: income,
      expense: expense,
      balance: income - expense
    }
  end

  def build_monthly_summary(
    transactions,
    year
  )
    (1..12).map do |month|
      start_date =
        Date.new(
          year,
          month,
          1
        )

      end_date =
        start_date.end_of_month

      month_transactions =
        transactions.where(
          date:
            start_date..end_date
        )

      summary =
        build_period_summary(
          month_transactions
        )

      {
        month: month,
        income: summary[:income],
        expense: summary[:expense],
        balance: summary[:balance]
      }
    end
  end

  def build_category_expense(
    transactions
  )
    transactions
      .where(
        transaction_type: "expense"
      )
      .group(:category)
      .sum(:amount)
      .map do |category, amount|
        {
          category: category,
          amount: amount
        }
      end
      .sort_by do |item|
        -item[:amount]
      end
  end
end