class UpdateShopRatingJob < ApplicationJob
  queue_as :default

  def perform(shop_id)
    shop_rating = ShopRating.find_or_create_by(shop_id: shop_id)
    shop_rating.update_rating_stats
  end
end

