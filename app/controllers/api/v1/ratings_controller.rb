# app/controllers/api/v1/ratings_controller.rb
module Api
  module V1
    class RatingsController < Api::V1::BaseController
      before_action :authenticate_request!
      before_action :set_order, only: [:create, :index]

      # POST /api/v1/orders/:order_id/ratings
      def create
        rating = Rating.new(rating_params.merge(
          order_id: @order.id,
          rater_id: current_user.id,
          shop_id: @order.shop_id
        ))

        if rating.save
          # Send notification to the rated user
          send_rating_notification(rating)
          
          render json: {
            success: true,
            message: "Rating submitted successfully",
            rating: serialize_rating(rating)
          }, status: :created
        else
          render json: {
            success: false,
            errors: rating.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/orders/:order_id/ratings
      def index
  puts "=== DEBUG: Starting ratings index action ==="
  
  begin
    # Direct query instead of using association
    ratings = Rating.where(order_id: @order.id)
    
    puts "=== DEBUG: Found #{ratings.count} ratings for order #{@order.id} ==="
    
    # Build response
    response_data = {
      order_id: @order.id,
      ratings: ratings.map { |r| serialize_rating(r) },
      can_rate_seller: can_rate_seller?,
      can_rate_buyer: can_rate_buyer?
    }

    puts "=== DEBUG: Response data built successfully ==="

    render json: response_data, status: :ok
    
  rescue => e
    puts "=== DEBUG: Error in ratings index: #{e.message} ==="
    render json: { error: "Failed to load ratings: #{e.message}" }, status: :internal_server_error
  end
end

      # GET /api/v1/shops/:shop_id/ratings
     def shop_ratings
  puts "=== DEBUG: Starting shop_ratings action ==="
  
  begin
    shop = Shop.find(params[:shop_id])
    puts "=== DEBUG: Found shop: #{shop.name} ==="
    
    ratings = Rating.where(shop_id: shop.id, rating_type: 'buyer_to_seller')
                   .includes(:rater)
                   .order(created_at: :desc)
    
    puts "=== DEBUG: Found #{ratings.count} ratings ==="
    
    shop_rating = ShopRating.find_or_create_by(shop_id: shop.id)
    puts "=== DEBUG: Shop rating stats - average: #{shop_rating.average_rating}, total: #{shop_rating.total_ratings} ==="

    # Build response data
    response_data = {
      shop_rating: {
        average_rating: shop_rating.average_rating.to_f,
        total_ratings: shop_rating.total_ratings,
        rating_breakdown: {
          "1": shop_rating.rating_1,
          "2": shop_rating.rating_2,
          "3": shop_rating.rating_3,
          "4": shop_rating.rating_4,
          "5": shop_rating.rating_5
        }
      },
      ratings: ratings.map { |r| serialize_rating_with_user(r) }
    }

    puts "=== DEBUG: Response data built successfully ==="
    puts "=== DEBUG: Ratings count in response: #{response_data[:ratings].count} ==="

    render json: response_data, status: :ok
    
  rescue => e
    puts "=== DEBUG: Error in shop_ratings: #{e.message} ==="
    puts "=== DEBUG: Backtrace: #{e.backtrace.first(5)} ==="
    render json: { error: "Failed to load ratings: #{e.message}" }, status: :internal_server_error
  end
end

      private

      def set_order
        @order = Order.find(params[:order_id])
      end

      def rating_params
        params.require(:rating).permit(:rating, :review, :rating_type, :rated_id)
      end

      def can_rate_seller?
        return false unless current_user.id == @order.buyer_id
        
        # Check if buyer hasn't rated seller for this order
        !Rating.exists?(
          order_id: @order.id, 
          rater_id: current_user.id, 
          rating_type: 'buyer_to_seller'
        ) && @order.order_status == 'completed'  # Use order_status instead of completed_at
      end

      def can_rate_buyer?
        return false unless current_user.id == @order.shop.user_id
        
        # Check if seller hasn't rated buyer for this order
        !Rating.exists?(
          order_id: @order.id, 
          rater_id: current_user.id, 
          rating_type: 'seller_to_buyer'
        ) && @order.order_status == 'completed'  # Use order_status instead of completed_at
      end

      def send_rating_notification(rating)
        rated_user = rating.rated
        
        notification = Notification.create!(
          user: rated_user,
          title: "You received a new rating!",
          message: "#{rating.rater.name} rated you #{rating.rating} stars",
          notifiable: rating,
          notification_type: 'new_rating'
        )

        if rated_user.firebase_token.present?
          FirebaseNotificationService.deliver_later(notification)
        end
      end

      def serialize_rating(rating)
        {
          id: rating.id,
          rating: rating.rating,
          review: rating.review,
          rating_type: rating.rating_type,
          created_at: rating.created_at,
          rater_name: rating.rater.name
        }
      end

      def serialize_rating_with_user(rating)
        {
          id: rating.id,
          rating: rating.rating,
          review: rating.review,
          rating_type: rating.rating_type,
          created_at: rating.created_at,
          rater_name: rating.rater.name,
         # rater_avatar: rating.rater.profile&.image || "default_avatar.png"  # Simple field instead of nested object
        }
      end
    end
  end
end