require 'sinatra'
require 'shopify_api'
require 'json'
require 'rest-client'
require 'uri-handler'
require 'json'


class HelloWorldApp < Sinatra::Base

# Helper methods
	helpers do
		# Marks new order with note
		def add_note(order_id)
			order = ShopifyAPI::Order.find(order_id)
			order.note = "Dropped inventory."
			order.save
		end

		# Drops variant inventory based on order line items qty
		def decrement_inventory(variant_id,order_line_item_qty)
			variant = ShopifyAPI::Variant.find(variant_id)
			variant.inventory_quantity -= order_line_item_qty
			variant.save
		end

		# Compares all variants against order line items SKU 
		def find_variant_by_sku_and_decrement_inventory(sku,order_line_item_qty)
			all_variants = ShopifyAPI::Variant.all
			all_variants.each do |variant| 
				decrement_inventory(variant.id,order_line_item_qty) if variant.sku == sku
			end
		end
	end

	# Set variables for request
	shop = "liddle"
	api_key = "9f34194c2e102ab66125123f0a24e48a"
	secret = "f363d7de4de567981ef03c645d998c3d"
	scopes = "read_orders,write_orders,read_products,write_products"
	redirect_uri = "https://oauth2dance.herokuapp.com/auth/shopify/callback"
	nonce = "123abc789xyz"

	# Build redirect url
	permission_url = "https://#{shop}.myshopify.com/admin/oauth/authorize?client_id=#{api_key}&scope=#{scopes.to_uri}&redirect_uri=#{redirect_uri.to_uri}&state=#{nonce}"

	# Some simple routes
	get "/" do
		redirect permission_url
	end

	get "/auth/shopify/callback" do
		# get temporary Shopify API code...
  		session_code = request.env['rack.request.query_hash']['code']

  		# POST it back to Shopify
  		result = RestClient.post("https://#{shop}.myshopify.com/admin/oauth/access_token",
                          {:client_id => api_key,
                           :client_secret => secret,
                           :code => session_code},
                           :accept => :json)

  		# extract the access token and create order/create webhook
  		access_token = JSON.parse(result)['access_token']
  		session = ShopifyAPI::Session.new("liddle.myshopify.com", access_token)
  		ShopifyAPI::Base.activate_session(session)
  		shop = ShopifyAPI::Shop.current
  		webhook = ShopifyAPI::Webhook.create(topic: "orders/create", address:"https://oauth2dance.herokuapp.com/webhook", format: "json")
  		puts "Webhook created!"
	end

	# Digest order webhook and run decrement inventory logic
	post "/webhook" do
		puts "Webhook received!"
		request.body.rewind
  		data = JSON.parse request.body.read	

  		data["line_items"].each do |x|
  			order_li_qty = x["quantity"]
  			sku = x["sku"]
  			find_variant_by_sku_and_decrement_inventory(sku,order_li_qty)
  		end
		
		order_id = data["id"]
		add_note(order_id)
	end	
end

