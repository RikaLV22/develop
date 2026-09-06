class OrganizationAccountsController < ApplicationController
  before_action :logged_in_user
  before_action :set_current_organization

  def index
    accounts =
      organization_accounts
        .includes(:bank)

    render json:
      accounts.map { |account| account_json(account) }
  end

  def show
    account =
      organization_accounts.find(params[:id])

    render json:
      account_json(account)
  end

  def create
    account =
      Account.new(account_params)

    account.user_id = nil
    account.organization_id =
      @current_organization.id
    account.account_scope =
      "organization"

    if account.save
      render json:
        account_json(account),
        status: :created
    else
      render json: {
        errors:
          account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def add_balance
    account =
      organization_accounts.find(params[:id])

    amount =
      params[:amount].to_f

    if amount <= 0
      render json: {
        error:
          "金額は1円以上で入力してください"
      }, status: :unprocessable_entity

      return
    end

    account.balance += amount

    if account.save
      render json:
        account_json(account)
    else
      render json: {
        errors:
          account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def subtract_balance
    account =
      organization_accounts.find(params[:id])

    amount =
      params[:amount].to_f

    if amount <= 0
      render json: {
        error:
          "金額は1円以上で入力してください"
      }, status: :unprocessable_entity

      return
    end

    account.balance -= amount

    if account.save
      render json:
        account_json(account)
    else
      render json: {
        errors:
          account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def transfer
    from_account =
      organization_accounts.find(
        params[:from_account_id]
      )

    to_account =
      organization_accounts.find(
        params[:to_account_id]
      )

    amount =
      params[:amount].to_f

    if from_account.id == to_account.id
      render json: {
        error:
          "同じ口座には移動できません"
      }, status: :unprocessable_entity

      return
    end

    if amount <= 0
      render json: {
        error:
          "金額は1円以上で入力してください"
      }, status: :unprocessable_entity

      return
    end

    if from_account.balance < amount
      render json: {
        error:
          "移動元の口座残高が不足しています"
      }, status: :unprocessable_entity

      return
    end

    Account.transaction do
      from_account.balance -= amount
      to_account.balance += amount

      from_account.save!
      to_account.save!
    end

    render json: {
      message:
        "口座間の資金移動が完了しました",

      from_account:
        account_json(from_account),

      to_account:
        account_json(to_account)
    }, status: :ok

  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "口座が見つかりません"
    }, status: :not_found

  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error:
        e.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  private

  def set_current_organization
    organization_id =
      params[:organization_id].presence ||
      @current_user.organization_id

    @current_organization =
      @current_user.organizations.find_by(
        id: organization_id
      )

    return if @current_organization

    render json: {
      error: "所属していない組織です"
    }, status: :forbidden
  end

  def organization_accounts
    Account.where(
      organization_id:
        @current_organization.id,
      account_scope:
        "organization"
    )
  end

  def account_json(account)
    transactions =
      account.transactions
            .where(
              organization_id:
                @current_organization.id,
              transaction_scope:
                "organization"
            )
            .order(
              date: :desc,
              id: :desc
            )
            .limit(10)

    account.as_json(
      include: :bank
    ).merge(
      transaction_count:
        account.transactions.where(
          organization_id:
            @current_organization.id,
          transaction_scope:
            "organization"
        ).count,

      registered_at:
        account.created_at,

      transactions:
        transactions.map do |transaction|
          {
            id: transaction.id,
            transaction_type:
              transaction.transaction_type,
            category:
              transaction.category,
            amount:
              transaction.amount,
            date:
              transaction.date.to_s,
            payment_method:
              transaction.payment_method
          }
        end
    )
  end

  def account_params
    params.require(:account).permit(
      :bank_id,
      :account_number,
      :balance
    )
  end
end