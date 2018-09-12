=begin
Insights Service Catalog API

This is a API to fetch and order catalog items from different cloud sources

OpenAPI spec version: 1.0.0
Contact: you@your-company.com
Generated by: https://github.com/swagger-api/swagger-codegen.git

=end
class UsersController < ApplicationController

  def add_provider
    object = Provider.create(:name       => params[:name],
                             :url        => params[:url],
                             :token      => params[:token],
                             :user       => params[:user],
                             :password   => params[:password],
                             :verify_ssl => params.fetch(:verify_ssl, true))
    render json: object.to_hash
  end

  def add_to_order
    order = Order.find(params['order_id'])
    hash_parameters = []
    params['parameters'].each do |p|
      hash_parameters << {:name => p['name'], :value => p['value'], :format => p['format'],
                          :type => p['type'] }
    end
    order_item = OrderItem.create(:order_id    => order.id,
                                  :catalog_id  => params['catalog_id'],
                                  :plan_id     => params['plan_id'],
                                  :provider_id => params['provider_id'],
                                  :count       => params['count'] || 1,
                                  :parameters  => hash_parameters)
    render json: {"item_id" => order_item.id}
  end

  def catalog_items
    result = Provider.all.collect { |prov| prov.fetch_catalog_items }.flatten
    render json: result
  end

  def catalog_plan_parameters
    prov = Provider.where(:id => params['provider_id']).first
    result = prov.fetch_catalog_plan_parameters(params['catalog_id'], params['plan_id']) if prov
    render json: result
  end

  def fetch_catalog_item_with_provider
    prov = Provider.where(:id => params['provider_id']).first
    result = prov.fetch_catalog_items(params['catalog_id']) if prov
    render json: result
  end

  def fetch_catalog_item_with_provider_and_catalog_id
    fetch_catalog_item_with_provider
  end

  def fetch_plans_with_provider_and_catalog_id
    prov = Provider.where(:id => params['provider_id']).first
    result = prov.fetch_catalog_plans(params['catalog_id']) if prov
    render json: result
  end

  def list_order_item
    item = OrderItem.where('id = ? and order_id = ?',
                           params['order_item_id'], params['order_id']).first
    render json: item.to_hash
  end

  def list_order_items
    render json: OrderItem.where(:order_id => params['order_id']).collect(&:to_hash)
  end

  def list_orders
    render json: Order.all.collect(&:to_hash)
  end

  def list_portfolios
    portfolios = Portfolio.all
    render json: portfolios
  end

  def fetch_portfolio_with_id
    item = Portfolio.where(:id => params[:portfolio_id]).first
    render json: item
  end

  def list_progress_messages
    render json: ProgressMessage.where(:order_item_id => params['order_item_id']).collect(&:to_hash)
  end

  def list_providers
    render json: Provider.all.collect(&:to_hash)
  end

  def new_order
    render json: Order.create.to_hash
  end

  def submit_order
    order = Order.find(params['order_id'])
    OrderItem.where(:order_id => params['order_id']).each(&:submit)
    order.update_attributes(:state => 'Ordered', :ordered_at => DateTime.now())
    order.reload

    OrderItem.where(:order_id => params['order_id']).each{ |item| item.update_message('info', 'Initialized') }
    render json: order.to_hash
  end
end
