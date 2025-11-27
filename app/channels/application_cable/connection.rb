# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Implement your user authentication logic here
      # For example, if using Devise:
      # env['warden'].user || reject_unauthorized_connection
      
      # For now, return a dummy user or implement proper auth
      User.first || reject_unauthorized_connection
    end
  end
end