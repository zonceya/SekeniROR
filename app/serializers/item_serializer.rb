class ItemSerializer < ActiveModel::Serializer
  attributes :id, :shop_id, :name, :description, :icon, :cover_photo, 
             :status, :deleted, :meta, :created_at, :updated_at,
             :item_type_id, :school_id, :brand_id, :size_id, 
             :additional_photo, :label, :price, :quantity,
             :item_condition_id, :location_id, :province_id, 
             :label_photo, :gender_id, :reserved

  belongs_to :shop
end