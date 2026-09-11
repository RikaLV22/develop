class MaintenanceSetting < ApplicationRecord
  validates :maintenance_message, length: { maximum: 500 }, allow_blank: true

  def self.current
    first_or_create!
  end
end