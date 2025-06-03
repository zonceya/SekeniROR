class Shop < ApplicationRecord
    belongs_to :user
    validates :name, presence: true
    has_many :items
    has_many :orders
  end