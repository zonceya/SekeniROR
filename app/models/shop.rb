# app/models/shop.rb
class Shop < ApplicationRecord
  belongs_to :user
  has_many :items
  has_many :orders
  
  validates :name, presence: true 
 
  
  def public_name
    display_name.presence || name
  end
  
  def seller_mobile
    user&.mobile
  end
end