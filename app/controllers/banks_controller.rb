class BanksController < ApplicationController
  def index
    render json: Bank.select(:id, :name, :code)
  end
end