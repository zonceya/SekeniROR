class UserRating < ApplicationRecord
  belongs_to :user

  def update_rating_stats
    ratings = Rating.where(rated_id: user_id, rating_type: 'seller_to_buyer')
    
    self.total_ratings = ratings.count
    self.average_rating = ratings.average(:rating).to_f.round(2)
    self.updated_at = Time.current
    save!
  end
end