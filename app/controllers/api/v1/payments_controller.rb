def apay
  @item = Item.find(params[:item_id])

  result = Inventory::HoldService.new(
    item: @item,
    user: current_user,
    quantity: params[:quantity]
  ).call

  if result.success?
    # Redirect to banking details page
    redirect_to banking_details_path(item_id: @item.id)
  else
    flash[:error] = result.error
    redirect_to cart_path
  end
end