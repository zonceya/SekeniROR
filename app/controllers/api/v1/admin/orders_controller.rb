module Api
  module V1
    module Admin
      class OrdersController < Admin::BaseController
        RATE_LIMIT = 100 # requests
        PERIOD = 1.hour
        before_action :authenticate_admin!, :check_rate_limit
        before_action :set_order, only: [:show, :update_status]
        before_action :enforce_bulk_limit, only: :bulk_index
      
        # GET /api/v1/admin/orders
        def index
          @orders = Order.includes(:buyer, :shop, order_items: [:item])
                        .order(created_at: :desc)
          
          # Pagination
          @orders = if @orders.respond_to?(:page)
                      @orders.page(params[:page]).per(params[:per_page] || 25)
                    else
                      @orders.limit(params[:per_page] || 25)
                    end

          render json: {
            data: AdminOrderSerializer.new(@orders).serializable_hash[:data],
            meta: pagination_meta(@orders)
          }
        end

        # GET /api/v1/admin/orders/:id
        def show
          @order = Order.includes(:buyer, :shop, order_items: [:item])
                        .find(params[:id])

          render json: AdminOrderSerializer.new(@order).serializable_hash
        end

        # PATCH /api/v1/admin/orders/:id/status
        def update_status
        if @order.update(order_status_params)
          render json: AdminOrderSerializer.new(@order).serializable_hash
        else
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
        end
      end

        def bulk_index
          orders = Order.includes(:buyer, :shop, :order_items)
                      .where(filter_params)
                      .order(created_at: :desc)
                      .limit(1000) # Safety limit

          render json: {
            data: AdminOrderSerializer.new(orders).serializable_hash[:data],
            meta: {
              total_count: orders.count
            }
          }
        end

        private

        def enforce_bulk_limit
          return if params[:limit].to_i <= 1000 # Customizable cap
          render json: { error: "Maximum 1000 orders per bulk request" }, status: :bad_request
        end
      
        def filter_params
          params.permit(:status, :shop_id, :buyer_id, :created_after, :created_before)
        end

        def check_rate_limit
          key = "admin_rate_limit:#{current_admin.id}"
          count = Rails.cache.fetch(key, expires_in: PERIOD) { 0 }
          if count >= RATE_LIMIT
            render json: { error: "Rate limit exceeded. Try again later" }, status: :too_many_requests
          else
            Rails.cache.increment(key)
          end
        end

        def set_order
          @order = Order.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Order not found' }, status: :not_found
        end

        def order_status_params
          params.require(:order).permit(:status, :admin_notes)
        end

        def pagination_meta(object)
          if object.respond_to?(:current_page)
            {
              current_page: object.current_page,
              next_page: object.next_page,
              prev_page: object.prev_page,
              total_pages: object.total_pages,
              total_count: object.total_count
            }
          else
            {
              current_page: 1,
              total_count: object.count
            }
          end
        end
      end
    end
  end
end