class PersonalTransactionChannel < ApplicationCable::Channel
  def subscribed
    stream_from "personal_transactions_#{current_user.id}"
  end

  def unsubscribed
  end
end