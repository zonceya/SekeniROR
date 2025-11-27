module Api
  module V1
    class SalesController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      def index
        sale_data = {
          active_promotions: get_active_promotions,
          sale_items: get_sale_items,
          ending_soon: get_ending_soon_promotions
        }
        render json: sale_data
      end

      def items
        items = if params[:promotion_id]
                 Item.joins(:promotions)
                     .where(promotions: { id: params[:promotion_id] },
                            items: { deleted: false, status: 'active' })
               else
                 # Items with active promotions or tagged as sale
                 Item.joins('LEFT JOIN promotions ON promotions.id = items.promotion_id')
                     .where('promotions.active = TRUE OR items.label ILIKE ?', '%sale%')
                     .where(items: { deleted: false, status: 'active' })
               end

        items = items.includes(:shop, :item_images, :promotions)
                     .order(created_at: :desc)

        # Apply sorting
        if params[:sort] == 'ending_soon'
          items = items.joins(:promotions)
                       .where('promotions.end_date IS NOT NULL')
                       .order('promotions.end_date ASC')
        end

        render json: items.paginate(page: params[:page], per_page: 20)
      end

      private

      def get_active_promotions
        Promotion.where(active: true)
                 .where('start_date <= ? AND end_date >= ?', Time.current, Time.current)
                 .select(:id, :title, :description, :discount_percentage, :end_date, :image_url)
                 .order(:end_date)
      end

      def get_sale_items
        Item.joins(:promotions)
            .where(items: { deleted: false, status: 'active' }, 
                   promotions: { active: true })
            .where('promotions.end_date > ?', Time.current)
            .includes(:shop, :item_images)
            .limit(12)
      end

      def get_ending_soon_promotions
        Promotion.where(active: true)
                 .where('end_date BETWEEN ? AND ?', Time.current, 24.hours.from_now)
                 .select(:id, :title, :discount_percentage, :end_date)
                 .order(:end_date)
                 .limit(5)
      end
    end
  end
end