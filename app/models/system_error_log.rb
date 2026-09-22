class SystemErrorLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :error_code, presence: true
  validates :status_code, presence: true
  validates :request_method, presence: true
  validates :path, presence: true
  validates :message, presence: true
end