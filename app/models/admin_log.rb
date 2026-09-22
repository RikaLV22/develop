class AdminLog < ApplicationRecord
  belongs_to :admin, class_name: "User"

  validates :action, presence: true
  validates :message, presence: true
  validates :status, presence: true
end
