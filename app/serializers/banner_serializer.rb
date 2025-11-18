class BannerSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :image_url, :thumbnail_url, 
             :redirect_url, :banner_type, :target_type, :target_id,
             :position, :active, :start_date, :end_date, :created_at, :updated_at
end