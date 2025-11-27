module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    helper_method :current_user
  end

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token.blank?
      render json: { error: 'Authorization token missing' }, status: :unauthorized
      return false
    end

    session = UserSession.find_by(token: token)
    
    if session.nil?
      render json: { error: 'Invalid session token' }, status: :unauthorized
      return false
    end

    if session.ended_at.present?
      render json: { error: 'Session expired' }, status: :unauthorized
      return false
    end

    if session.user.deleted?
      render json: { error: 'Account deactivated' }, status: :forbidden
      return false
    end

    @current_user = session.user
    true
  end
def authenticate_request!
  authenticate_user!
end
  def current_user
    @current_user
  end
end