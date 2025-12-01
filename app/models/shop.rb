class Shop < ApplicationRecord
  belongs_to :user
  has_one_attached :logo  # Active Storage for shop logos
  
  validates :name, presence: true
  has_many :items
  has_many :orders
  
  def logo_url
    if logo.attached?
      Rails.application.routes.url_helpers.url_for(logo)
    else
      "https://cdn.skoolswap.co.za/default_shop_logo.png"
    end
  end
end