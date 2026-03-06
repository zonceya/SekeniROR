# config/initializers/disable_serializers_for_schools.rb
if defined?(ActiveModelSerializers)
  # Only apply to SchoolsController, not ApplicationController
  ActiveSupport.on_load(:after_initialize) do
    Api::V1::SchoolsController.class_eval do
      def default_serializer_options
        { serializer: nil }
      end
    end
  end
end