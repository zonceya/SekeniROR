# app/controllers/api/v1/notifications_controller.rb
module Api
  module V1
    class NotificationsController < Api::V1::BaseController
      before_action :authenticate_request!

      # GET /api/v1/notifications
      def index
        notifications = current_user.notifications.order(created_at: :desc)
        
        render json: {
          notifications: notifications.map do |notification|
            {
              id: notification.id,
              title: notification.title,
              message: notification.message,
              notification_type: notification.notification_type,
              status: notification.status,
              read: notification.read,
              created_at: notification.created_at,
              notifiable_type: notification.notifiable_type,
              notifiable_id: notification.notifiable_id
            }
          end
        }, status: :ok
      end

      # PUT /api/v1/notifications/:id/read
      def mark_as_read
        notification = current_user.notifications.find(params[:id])
        notification.mark_as_read
        
        render json: {
          message: 'Notification marked as read',
          notification: { 
            id: notification.id, 
            read: notification.read 
          }
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Notification not found' }, status: :not_found
      end

      # GET /api/v1/notifications/unread_count
      def unread_count
        count = current_user.notifications.unread.count
        render json: { unread_count: count }, status: :ok
      end
    end
  end
end