class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :ranking, :medal_collection]
  before_action :redirect_unless_admin!, except: [:show, :ranking, :medal_collection, :index, :subscribe, :new, :create]
  before_action :redirect_unless_comm!, except: [:show, :ranking, :medal_collection, :subscribe, :new, :create]

  # Amount in cents
  ANNUAL_SUBSCRIPTION_COST=1200

  def index
    @subscribers = User.with_active_subscription.order(:name).group_by do |s|
      "#{s.name.downcase}"
    end.values.map(&:first)
  end

  def show
    @subscribers = User.with_active_subscription.order(:name).group_by do |s|
      "#{s.name.downcase}"
    end.values.map(&:first)
  end

  def create
    @amount = ANNUAL_SUBSCRIPTION_COST

    customer = Stripe::Customer.create(
      :email => params[:stripeEmail],
      :source  => params[:stripeToken]
    )

    charge = Stripe::Charge.create(
      :customer    => customer.id,
      :amount      => @amount,
      :description => 'Cuota de socio anual de la AES',
      :currency    => 'eur'
    )

    current_user.add_subscription(
      charge.id,
      charge.amount,
    )

    NotificationMailer.with(user: current_user).notify_new_subscriber.deliver_now

  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to new_subscription_path
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    @subscription.destroy
    flash[:success] = "Suscripción eliminada"
    redirect_to subscriptions_list_url
  end

  def ranking
    @events = ["333", "222", "444", "555", "666", "777", "333bf", "333fm", "333oh", "333ft", "clock", "minx", "pyram", "skewb", "sq1", "444bf", "555bf", "333mbf"]
    event = "#{params[:event_id]}"
    format = "#{params[:format][0]}"
    wca_ids = User.with_active_subscription.map(&:wca_id)
    @query = "#{format}_#{event}"
    @persons = Person.where(wca_id: wca_ids).where("#{@query} IS NOT NULL").order("#{@query} ASC")
  end

  def medal_collection
    wca_ids = User.with_active_subscription.map(&:wca_id)
    @persons = Person.where(wca_id: wca_ids).where("gold > 0 or silver > 0 or bronze > 0").order(gold: :desc, silver: :desc, bronze: :desc)
  end
end
