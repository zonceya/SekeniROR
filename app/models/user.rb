class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_one :shop, dependent: :destroy

  after_commit :create_shop_for_user, on: :create
  after_create :create_profile_for_user

  # 👉 Soft delete (makes user inactive)
  def soft_delete
    update(deleted: true)
  end

  # 👉 Reactivate user
  def reactivate
    update(deleted: false)
  end

  private

  def create_shop_for_user
    return if shop.present?

    create_shop!(
      name: "#{name}'s Shop",
      description: "Shop for #{name}"
    )
  rescue => e
    Rails.logger.error "🚨 Failed to auto-create shop: #{e.message}"
  end

  def create_profile_for_user
    self.create_profile(profile_picture: 'default.png')
  end
end
