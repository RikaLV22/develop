class AccountsController < ApplicationController
  before_action :logged_in_user

  def index
    accounts = Account.includes(:bank).all
    render json: accounts.as_json(include: :bank)
  end

  def show
    account = Account.find(params[:id])
    render json: account.as_json(include: :bank)
  end

  def create
    account = Account.new(account_params)

    if account.save
      render json: account.as_json(include: :bank), status: :created
    else
      render json: {
        errors: account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def add_balance
    account = Account.find(params[:id])
    amount = params[:amount].to_f

    if amount <= 0
      render json: { error: '金額は1円以上で入力してください' }, status: :unprocessable_entity
      return
    end

    account.balance += amount

    if account.save
      render json: account.as_json(include: :bank)
    else
      render json: {
        errors: account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def subtract_balance
    account = Account.find(params[:id])
    amount = params[:amount].to_f

    if amount <= 0
      render json: { error: '金額は1円以上で入力してください' }, status: :unprocessable_entity
      return
    end

    account.balance -= amount

    if account.save
      render json: account.as_json(include: :bank)
    else
      render json: {
        errors: account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def transfer
    from_account = Account.find(params[:from_account_id])
    to_account = Account.find(params[:to_account_id])
    amount = params[:amount].to_f

    if from_account.id == to_account.id
      render json: {
        error: '同じ口座には移動できません'
      }, status: :unprocessable_entity
      return
    end

    if amount <= 0
      render json: {
        error: '金額は1円以上で入力してください'
      }, status: :unprocessable_entity
      return
    end

    if from_account.balance < amount
      render json: {
        error: '移動元の口座残高が不足しています'
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
      message: '口座間の資金移動が完了しました',
      from_account: from_account.as_json(include: :bank),
      to_account: to_account.as_json(include: :bank)
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: '口座が見つかりません'
    }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: e.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  private

  def account_params
    params.require(:account).permit(
      :bank_id,
      :account_number,
      :balance
    )
  end
end
