class Location < ApplicationRecord
  belongs_to :town, optional: true
  has_many :schools
  has_many :items
end