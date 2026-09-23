class ApiMaintenanceSetting < ApplicationRecord
  validates :api_name,
            presence: true,
            uniqueness: true

  validates :enabled,
            inclusion: { in: [true, false] }
end