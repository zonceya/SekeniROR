# app/jobs/warm_recommendations_cache_job.rb
class WarmRecommendationsCacheJob < ApplicationJob
  queue_as :low

  def perform
    # Get active schools
    school_ids = UserSchool.distinct.pluck(:school_id).compact.uniq
    
    school_ids.each do |school_id|
      # Warm cache for anonymous users
      cache_key = "school:#{school_id}:home:"
      
      # Get popular items
      popular_ids = UserItemView.popular_in_school(school_id, 50)
      
      # Cache for 6 hours
      $redis.setex(cache_key, 21600, {
        sections: [
          {
            title: "Popular at Your School",
            type: "popular",
            items: popular_ids
          }
        ]
      }.to_json)
    end
  end
end