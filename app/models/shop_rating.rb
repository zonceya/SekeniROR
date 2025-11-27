class ShopRating < ApplicationRecord
  belongs_to :shop

  def update_rating_stats
    ratings = Rating.where(shop_id: shop_id, rating_type: 'buyer_to_seller')
    
    self.total_ratings = ratings.count
    self.average_rating = ratings.average(:rating).to_f.round(2)
    
    (1..5).each do |star|
      send("rating_#{star}=", ratings.where(rating: star).count)
    end
    
    self.updated_at = Time.current
    save!
  end
end