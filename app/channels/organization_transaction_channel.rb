class OrganizationTransactionChannel < ApplicationCable::Channel
  def subscribed
    organization_id = current_user.organization_id

    reject unless organization_id

    stream_from "organization_transactions_#{organization_id}"
  end

  def unsubscribed
  end
end