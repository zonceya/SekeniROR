class User < ApplicationRecord
    has_one :profile, dependent: :destroy
    has_many :user_sessions, dependent: :destroy
  end
  