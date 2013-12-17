class ShopController < BaseController
  layout "darkswarm"

  before_filter :set_distributor
  before_filter :set_order_cycles

  def show
  end
  
  def products
    if products = current_order_cycle.andand.products_distributed_by(@distributor)
      render json: products, root: false 
    else
      render json: "", status: 404 
    end
  end

  def order_cycle
    if oc = OrderCycle.with_distributor(@distributor).active.find_by_id(params[:order_cycle_id])
      current_order(true).set_order_cycle! oc
      render status: 200, json: ""
    else
      render status: 404, json: ""
    end
  end

  private

  def set_distributor
    unless @distributor = current_distributor 
      redirect_to root_path
    end
  end

  def set_order_cycles
    @order_cycles = OrderCycle.with_distributor(@distributor).active
    
    # And default to the only order cycle if there's only the one
    if @order_cycles.count == 1
      current_order(true).set_order_cycle! @order_cycles.first
    end
  end
end
