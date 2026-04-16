class Item < ApplicationRecord
  belongs_to :shop, optional: true
  belongs_to :item_type, optional: true
  belongs_to :item_condition, optional: true
  belongs_to :brand, optional: true
  belongs_to :school, optional: true
  belongs_to :size, class_name: 'ItemSize', optional: true
  belongs_to :location, optional: true
  belongs_to :province, optional: true
  belongs_to :gender, optional: true
  belongs_to :main_category, optional: true
  belongs_to :sub_category, optional: true
  belongs_to :color, class_name: 'ItemColor', foreign_key: 'color_id', optional: true

  # ============================================
  # VALIDATIONS & ASSOCIATIONS
  # ============================================
  validate :validate_category_consistency

  has_many :item_tags
  has_many :tags, through: :item_tags
  has_many_attached :images
  has_many :item_variants
  validate :validate_image_limit
  validate :non_negative_inventory
  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  enum :status, { inactive: 0, active: 1, sold: 2, archived: 3 }, default: :active
  
  before_save :set_categories_from_item_type, if: -> { item_type_id.present? && (main_category_id.blank? || sub_category_id.blank?) }
  store_accessor :meta, :color, :size
  
  # ============================================
  # VIRTUAL ATTRIBUTES
  # ============================================
  attr_accessor :quantity, :reserved, :size_id, :color_id
  
  def quantity
    @quantity || self[:total_quantity] || 0
  end
  
  def quantity=(value)
    @quantity = value.to_i
    self.total_quantity = value.to_i
  end
  
  def reserved
    @reserved || self[:total_reserved] || 0
  end
  
  def reserved=(value)
    @reserved = value.to_i
    self.total_reserved = value.to_i
  end
  
  def size_id
    @size_id || self[:size_id]
  end
  
  def size_id=(value)
    @size_id = value
    self.size = ItemSize.find_by(id: value) if value.present?
  end
  
  def color_id
    @color_id || self[:color_id]
  end
  
  def color_id=(value)
    @color_id = value
    self.meta ||= {}
    self.meta['color_id'] = value
  end
 
  def available_quantity
    quantity.to_i - reserved.to_i
  end

  def can_fulfill?(requested_quantity)
    available_quantity >= requested_quantity
  end
  
  def validate_image_limit
    if images.attached? && images.size > 3
      errors.add(:images, "cannot exceed 3 images")
    end
  end
  
  # ============================================
  # IMAGE METHODS (PUBLIC - BEFORE private)
  # ============================================
  
  def image_urls
    return [] unless images.attached?
    images.map { |image| generate_presigned_url(image) }
  end

 def cover_photo
  # First check Active Storage
  if images.attached? && images.first.present?
    generate_presigned_url(images.first)
  elsif self[:cover_photo].present?
    # Fall back to database column (CDN URL)
    self[:cover_photo]
  else
    nil
  end
end
  def all_image_urls
  urls = []
  
  # Add Active Storage images first
  if images.attached?
    urls += images.map { |img| generate_presigned_url(img) }
  end
  
  # Add cover_photo from database if present and not already included
  if self[:cover_photo].present? && !urls.include?(self[:cover_photo])
    urls << self[:cover_photo]
  end
  
  # Add additional_photo if present
  if self[:additional_photo].present? && !urls.include?(self[:additional_photo])
    urls << self[:additional_photo]
  end
  
  urls
end

# For backward compatibility with existing code
def image_urls
  all_image_urls
end
  def generate_item_image_urls
    return [] unless images.attached?
    
    images.map do |image|
      {
        id: image.id,
        url: generate_presigned_url(image),
        filename: image.filename.to_s,
        content_type: image.content_type,
        created_at: image.created_at
      }
    end
  end

  def generate_presigned_url(image)
    s3_client = Aws::S3::Client.new(
      access_key_id: ENV['R2_ACCESS_KEY_ID'],
      secret_access_key: ENV['R2_SECRET_ACCESS_KEY'],
      endpoint: ENV['R2_ENDPOINT'],
      region: 'auto',
      force_path_style: true
    )
    
    signer = Aws::S3::Presigner.new(client: s3_client)
    
    signer.presigned_url(
      :get_object,
      bucket: ENV['R2_BUCKET_NAME'],
      key: image.key,
      expires_in: 3600
    )
  rescue => e
    Rails.logger.error "Failed to generate URL for image #{image.id}: #{e.message}"
    nil
  end

  # ============================================
  # PRIVATE METHODS
  # ============================================
  private
  
  def validate_category_consistency
    return unless main_category && sub_category
    
    if sub_category.main_category_id != main_category_id
      errors.add(:sub_category, "must belong to the selected main category")
    end
  end
  
  def set_categories_from_item_type
    self.main_category_id ||= item_type.main_category_id
    
    if main_category_id.present? && sub_category_id.blank?
      default_sub = main_category.sub_categories.find_by("name ILIKE ?", "%#{item_type.name}%")
      self.sub_category_id = default_sub.id if default_sub
    end
  end
  
  def non_negative_inventory
    if self.quantity < 0
      errors.add(:quantity, "can't be negative")
    end
    if self.reserved < 0
      errors.add(:reserved, "can't be negative")
    end
    if self.reserved > self.quantity
      errors.add(:reserved, "can't reserve more than available quantity")
    end
  end
end