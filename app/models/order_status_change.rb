# app/models/order_status_change.rb
class OrderStatusChange < ApplicationRecord
  belongs_to :order

  validates :status, presence: true
  validates :order_id, presence: true

  after_create :notify_parties

  private

  def notify_parties
    OrderStatusChangeNotifier.call(order, status)
  end
end