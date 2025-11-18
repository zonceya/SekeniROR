class OrderSerializer
  include JSONAPI::Serializer

  attributes :id, :order_number, :status, :payment_status, :buyer_id, :shop_id,
             :price_breakdown, :items, :addresses, :timestamps, :cancellable,
             :ratings, :shop_rating, :can_rate_seller, :can_rate_buyer

  def initialize(order, current_user = nil)
    @order = order || NullOrder.new
    @current_user = current_user
  end

  def as_json(*)
    {
      id: @order.id.to_s,
      order_number: @order.order_number,
      status: @order.order_status,
      payment_status: @order.payment_status || 'unpaid',
      buyer_id: @order.buyer_id,
      shop_id: @order.shop_id,
      price_breakdown: {
        subtotal: @order.price.to_f,
        service_fee: @order.service_fee.to_f,
        total: @order.total_amount.to_f
      },
      items: serialized_items,
      addresses: {
        shipping: @order.shipping_address || {},
        billing: @order.billing_address || {}
      },
      timestamps: {
        created_at: @order.created_at,
        updated_at: @order.updated_at,
        cancelled_at: @order.try(:cancelled_at),
        completed_at: @order.try(:completed_at)
      }.compact,
      cancellable: @order.respond_to?(:may_cancel?) && @order.may_cancel?,
      ratings: serialized_ratings,
      shop_rating: serialized_shop_rating,
      can_rate_seller: can_rate_seller?,
      can_rate_buyer: can_rate_buyer?
    }.compact
  rescue => e
    Rails.logger.error "Order serialization failed: #{e.message}"
    { error: "Failed to serialize order data" }
  end

  private

  def serialized_items
    Array(@order.order_items).map do |item|
      {
        id: item.id.to_s,
        item_id: item.item_id.to_s,
        name: item.try(:item_name) || 'Unnamed Item',
        quantity: item.quantity.to_i,
        unit_price: item.try(:actual_price).to_f,
        total_price: item.try(:total_price).to_f,
        image: item.try(:item).try(:image_url) || '/images/default-thumbnail.jpg'
      }
    end
  end

  def serialized_ratings
    {
      buyer_to_seller: @order.ratings.where(rating_type: 'buyer_to_seller').map do |rating|
        {
          id: rating.id,
          rating: rating.rating,
          review: rating.review,
          created_at: rating.created_at,
          rater_name: rating.rater.name
        }
      end,
      seller_to_buyer: @order.ratings.where(rating_type: 'seller_to_buyer').map do |rating|
        {
          id: rating.id,
          rating: rating.rating,
          review: rating.review,
          created_at: rating.created_at,
          rater_name: rating.rater.name
        }
      end
    }
  end

  def serialized_shop_rating
    shop_rating = ShopRating.find_by(shop_id: @order.shop_id)
    {
      average_rating: shop_rating&.average_rating || 0.0,
      total_ratings: shop_rating&.total_ratings || 0,
      rating_breakdown: {
        rating_1: shop_rating&.rating_1 || 0,
        rating_2: shop_rating&.rating_2 || 0,
        rating_3: shop_rating&.rating_3 || 0,
        rating_4: shop_rating&.rating_4 || 0,
        rating_5: shop_rating&.rating_5 || 0
      }
    }
  end

  def can_rate_seller?
    return false unless @current_user && @current_user.id == @order.buyer_id
    return false unless @order.completed_at && @order.completed_at <= 7.days.ago
    
    # Check if buyer hasn't rated seller for this order
    !Rating.exists?(
      order_id: @order.id, 
      rater_id: @current_user.id, 
      rating_type: 'buyer_to_seller'
    )
  end

  def can_rate_buyer?
    return false unless @current_user && @current_user.id == @order.shop.user_id
    return false unless @order.completed_at && @order.completed_at <= 7.days.ago
    
    # Check if seller hasn't rated buyer for this order
    !Rating.exists?(
      order_id: @order.id, 
      rater_id: @current_user.id, 
      rating_type: 'seller_to_buyer'
    )
  end

  # Null object to handle nil safely
  class NullOrder
    def method_missing(*)
      nil
    end

    def respond_to_missing?(*)
      true
    end
  end
end