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
  
  has_many :item_tags
  has_many :tags, through: :item_tags
  has_many_attached :images

  validate :non_negative_inventory
  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  enum :status, { inactive: 0, active: 1, sold: 2, archived: 3 }, default: :active

  store_accessor :meta, :color, :size
  def available_quantity
    quantity - reserved
  end
  
  def available_quantity
    quantity.to_i - reserved.to_i
  end

  def can_fulfill?(requested_quantity)
    available_quantity >= requested_quantity
  end
  def image_urls
      return [] unless images.attached?
      
      images.map do |image|
        # You'll need to implement this URL generation method
        generate_image_url(image)
      end
    end
  private

def generate_image_url(image)
    # Similar to your user profile URL generation
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
    Rails.logger.error "Failed to generate item image URL: #{e.message}"
    nil
  end
end
  
def non_negative_inventory
  if quantity.to_i < 0
    errors.add(:quantity, "can't be negative")
  end
  if reserved.to_i < 0
    errors.add(:reserved, "can't be negative")
  end
  if reserved.to_i > quantity.to_i
    errors.add(:reserved, "can't reserve more than available quantity")
  end
end
end