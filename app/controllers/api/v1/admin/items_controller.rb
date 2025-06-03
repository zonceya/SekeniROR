module Api
    module V1
      module Admin
        class ItemsController < ApplicationController
          skip_before_action :verify_authenticity_token
          def adminViewAllItems
            render json: Item.all
          end
  
          def adminDeleteItem
            item = Item.find(params[:id])
            if item.update(status: :inactive)
              render json: { message: 'Item deleted by admin' }
            else
              render json: item.errors, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
  