# app/models/concerns/inventory_lockable.rb
module InventoryLockable
  extend ActiveSupport::Concern

  def with_inventory_lock(item, &block)
    ActiveRecord::Base.transaction do
      item.with_lock do
        yield
      end
    end
  end
end

# Include in your models
class Order < ApplicationRecord
  include InventoryLockable
end