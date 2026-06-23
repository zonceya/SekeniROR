class UserItemView < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :item
  belongs_to :school, optional: true
  
  validates :item_id, presence: true
  validates :view_count, numericality: { greater_than_or_equal_to: 0 }
  
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :for_school, ->(school_id) { where(school_id: school_id) }
  
  def self.track(user_id, item_id, school_id, source, session_id)
    # Find existing view for this user/item/session from today
    view = where(
      user_id: user_id,
      item_id: item_id,
      session_id: session_id
    ).where('created_at >= ?', Time.current.beginning_of_day).first
    
    # Create new if doesn't exist
    if view.nil?
      view = new(
        user_id: user_id,
        item_id: item_id,
        session_id: session_id,
        created_at: Time.current
      )
    end
    
    view.school_id = school_id if school_id.present?
    view.source = source if source.present?
    view.view_count = (view.view_count || 0) + 1
    
    if view.save
      # Increment the item's cached view count
      Item.where(id: item_id).update_all("view_count = view_count + 1")
    end
    
    view
  end
  
  def self.popular_in_school(school_id, limit = 20, days = 7)
    where(school_id: school_id)
      .where('created_at > ?', days.days.ago)
      .group(:item_id)
      .order(Arel.sql('COUNT(*) DESC'))
      .limit(limit)
      .pluck(:item_id)
  end
  
  def self.user_preferred_categories(user_id, limit = 5)
    where(user_id: user_id)
      .joins(:item)
      .group('items.main_category_id')
      .order(Arel.sql('COUNT(*) DESC'))
      .limit(limit)
      .pluck('items.main_category_id')
      .compact
  end
end