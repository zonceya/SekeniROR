# app/jobs/payment_monitor_job.rb
class PaymentMonitorJob < ApplicationJob
  queue_as :default

  def perform(mode = :payments)
    case mode.to_sym
    when :payments
      GmailReader.monitor_bank_payments
    when :notifications
      GmailReader.fetch_bank_notifications
    when :both
      GmailReader.monitor_bank_payments
      GmailReader.fetch_bank_notifications
    end
    
    Rails.logger.info "Payment monitor completed in #{mode} mode"
  rescue => e
    Rails.logger.error "Payment monitoring failed: #{e.message}"
    AdminMailer.payment_monitor_failed(e, mode).deliver_later
  end
end