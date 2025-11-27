class Rating < ApplicationRecord
  belongs_to :order
  belongs_to :rater, class_name: 'User'
  belongs_to :rated, class_name: 'User'
  belongs_to :shop

  validates :rating, presence: true, numericality: { 
    only_integer: true, 
    greater_than_or_equal_to: 1, 
    less_than_or_equal_to: 5 
  }
  validates :rating_type, presence: true

  after_save :update_rating_summaries
  after_destroy :update_rating_summaries

  private

  def update_rating_summaries
    if rating_type == 'buyer_to_seller'
      UpdateShopRatingJob.perform_later(shop_id)
    else
      UpdateUserRatingJob.perform_later(rated_id)
    end
  end
end