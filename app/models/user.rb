class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :user_sessions, dependent: :destroy

  def soft_delete
    update(deleted: true)
  end
  def reactivate
    update(status: true, deleted: false)
  end
end

  