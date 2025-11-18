# app/jobs/update_user_rating_job.rb
class UpdateUserRatingJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user_rating = UserRating.find_or_create_by(user_id: user_id)
    user_rating.update_rating_stats
  end
end