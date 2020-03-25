class OrdersController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :index, :destroy]
  before_action :logged_in_admin, only: [:deny, :approve]

  def index
    @orders = Order.search(params, current_user.id) if params.present?
  end

  def new
    @home = Home.find(params[:home_id]) if params[:home_id].present?
    @room = Room.find(params[:room_id]) if params[:room_id].present?
    @order = Order.new
  end

  def create
    @home = Home.find(params[:home_id]) if params[:home_id].present?
    @order = @home.orders.build(order_params) if @home.present?

    @room = Room.find(params[:room_id]) if params[:room_id].present?
    @order = @room.orders.build(order_params) if @room.present?
    @order.user_id = current_user.id
    if @order.save
      @home.ordered! if @home.present?
      @room.ordered! if @room.present?
      flash[:success] = "Order created!"
      redirect_to orders_path
    else
      render "new"
    end
  end

  def destroy
    @home = Home.find(params[:home_id])
    @order = @home.orders.find(params[:id])
    if @order.status == "requesting" || @order.status == "denied" || @order.status == "finished"
      @order.destroy
      @home.available!
      flash[:success] = "Order deleted"
      redirect_to orders_path
    else
      flash[:danger] = "Request denied , please contact to landlord"
      redirect_to orders_path
    end
  end

  def update
    @order = Order.find_by(id: params[:id])
    if @order.update_attributes(order_params)
      @order.requesting_extension!
      flash[:success] = "requesting extension Order"
      redirect_to orders_path
    else
      render "requesting_extension"
    end
  end

  def requesting_extension
    @order = Order.find_by(id: params[:order_id])
    @home = @order.home if @order.home_id.present?
    @room = @order.room if @order.room_id.present?
    unless @order.approved?
      flash[:danger] = "Request deny , please contact to landlord"
      redirect_to orders_path
    end
  end

  def cancel
    @order = Order.new
    check = false
    @order = Order.cancel(params, check)
    check ? flash[:success] = "Order cancelled" : flash[:danger] = "Request deny , please contact to landlord"
    redirect_to orders_path
  end

  def finish
    @order = Order.new
    check = false
    @order = Order.finish(params, check)
    check ? flash[:success] = "Order finished" : flash[:danger] = "Request deny , please contact to landlord"
    redirect_to orders_path
  end

  def approve
    @order = Order.new
    @order = Order.approve(params)
    @order.approved? ? flash[:success] = "approved Order" : flash[:danger] = "Request deny , please contact to landlord"
    redirect_to orders_path
  end

  def deny
    @order = Order.new
    @order = Order.deny(params)
    @order.denied? ? flash[:success] = "denied Order" : flash[:danger] = "Request deny , please contact to landlord"
    redirect_to orders_path
  end

  private

  def order_params
    params[:order][:checkin_time] = DateTime.strptime(params[:order][:checkin_time], "%m/%d/%Y %l:%M %p")
    params.require(:order).permit(:checkin_time, :rental_period)
  end
end
