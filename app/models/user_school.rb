# app/models/user_school.rb
class UserSchool < ApplicationRecord
  belongs_to :user
  belongs_to :school
  
  # Validations
  validates :user_id, presence: true
  validates :school_id, presence: true
  
  # Remove the uniqueness validation that prevents changes
  # validates :user_id, uniqueness: { scope: :school_id }
  
  # Instead, add validation to ensure only one active mapping per user
  # (but allow updates to the existing one)
  validate :only_one_school_per_user, on: :create
  
  private
  
  def only_one_school_per_user
    if UserSchool.where(user_id: user_id).exists?
      errors.add(:user_id, "can only have one school. Use update to change schools.")
    end
  end
end