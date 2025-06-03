module Api::V1::Admin
    class UsersController < BaseController
      # GET /api/v1/admin/users
      def index
        users = User.all
        render json: users, status: :ok
      end
  
      # GET /api/v1/admin/users/:id
      def show
        user = User.find(params[:id])
        render json: user_response(user), status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end
  
      # PATCH/PUT /api/v1/admin/users/:id
      def update
        user = User.find(params[:id])
        
        if user.update_without_password(admin_user_params)
          render json: user_response(user), status: :ok
        else
          render json: { 
            success: false,
            errors: formatted_errors(user.errors) 
          }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end
      
      # Add this to your User model
      def update_without_password(params)
        update(params.except(:password, :password_confirmation))
      end
  
      # DELETE /api/v1/admin/users/:id  
      def destroy
        user = User.find(params[:id])
        user.soft_delete
        render json: { message: 'User deactivated successfully' }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end
  
      # POST /api/v1/admin/users/:id/reactivate
      def reactivate
        user = User.find(params[:id])
        user.reactivate
        render json: { message: 'User reactivated successfully' }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end
  
      private
  
      def admin_user_params
        params.require(:user).permit(
          :name,
          :email, 
          :mobile,
          :status,
          :role,
          :profile_picture
        )
      end
  
      def user_response(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          status: user_status(user),
          mobile: user.mobile,
          profile_picture_url: user.profile_picture&.attached? ? url_for(user.profile_picture) : nil,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end
  
      def user_status(user)
        if user.deleted?
          'deactivated'
        else
          user.status ? 'active' : 'inactive'
        end
      end
  
      def formatted_errors(errors)
        errors.messages.transform_values { |v| v.join(', ') }
      end
    end
  end