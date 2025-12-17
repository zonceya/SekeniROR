# app/models/shop.rb
class Shop < ApplicationRecord
  belongs_to :user
  has_many :items
  has_many :orders
  
  validates :name, presence: true
  
  # Remove logo_url method completely
  # The frontend will use user.profile_picture_url from login response
  
  def public_name
    display_name.presence || name
  end
end