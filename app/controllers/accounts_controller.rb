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
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def add_balance
    account = Account.find(params[:id])
    amount = params[:amount].to_f
    account.balance += amount

    if account.save
      render json: account.as_json(include: :bank)
    else
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
    end
  end


  def subtract_balance
    account = Account.find(params[:id])
    amount = params[:amount].to_f
    account.balance -= amount

    if account.save
      render json: account.as_json(include: :bank)
    else
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:account).permit(:bank_id, :account_number, :balance)
  end
end