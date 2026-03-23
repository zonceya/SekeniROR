# app/models/user_item_view.rb
class UserItemView < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  belongs_to :item
  
  # Validations
  validates :item_id, presence: true
  validates :school_id, presence: true
  
  # Scopes
  scope :recent, -> { where('created_at > ?', 7.days.ago) }
  scope :today, -> { where('created_at > ?', Time.now.beginning_of_day) }
  scope :this_week, -> { where('created_at > ?', 7.days.ago) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_school, ->(school_id) { where(school_id: school_id) }
  scope :by_source, ->(source) { where(source: source) }
  
  # Class methods
  def self.track(user_id, item_id, school_id, source = nil, session_id = nil)
    view = where(user_id: user_id, item_id: item_id)
           .where('created_at > ?', 1.hour.ago)
           .first
    
    if view
      view.increment!(:view_count)
    else
      create(
        user_id: user_id,
        item_id: item_id,
        school_id: school_id,
        source: source,
        session_id: session_id
      )
    end
  rescue => e
    Rails.logger.error "Failed to track view: #{e.message}"
  end
  
  def self.popular_in_school(school_id, limit = 20, days = 7)
    where(school_id: school_id)
      .where('created_at > ?', days.days.ago)
      .group(:item_id)
      .order(Arel.sql('SUM(view_count) DESC'))  # ✅ FIXED
      .limit(limit)
      .pluck(:item_id)
  end
  
  def self.user_preferred_categories(user_id, limit = 3)
    joins(:item)
      .where(user_id: user_id)
      .where('user_item_views.created_at > ?', 30.days.ago)
      .group('items.main_category_id')
      .order(Arel.sql('COUNT(*) DESC'))  # ✅ FIXED
      .limit(limit)
      .pluck('items.main_category_id')
  end
end