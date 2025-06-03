class ItemType < ApplicationRecord
  belongs_to :group, class_name: 'ItemGroup', optional: true
end
