class RemoveImageUrlFromBanners < ActiveRecord::Migration[8.0]
  def change
    remove_column :banners, :image_url, :string
  end
end
