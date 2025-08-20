class Town < ApplicationRecord
  belongs_to :province
  has_many :locations
end