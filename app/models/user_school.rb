class UserSchool < ApplicationRecord
  belongs_to :user
  belongs_to :school
  
  # Validations
  validates :user_id, presence: true
  validates :school_id, presence: true
  validates :user_id, uniqueness: { scope: :school_id }
end