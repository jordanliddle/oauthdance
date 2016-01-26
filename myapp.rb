require 'sinatra'
require 'shopify_api'
require 'json'
require 'httparty'


class HelloWorldApp < Sinatra::Base

# Accessing the Shopify API
	# @shop_url = "https://#{key}:#{password}@liddle.myshopify.com/admin"
	# ShopifyAPI::Base.site = @shop_url
	# shop = ShopifyAPI::Shop.current

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

		# def find_by_sku(sku,order_line_item_qty)
		# 	get "#{@shop_url}/products/search.json?query=sku:#{sku}" do 
		# 		newdata = JSON.parse response.body
		# 		@product = newdata["products"].first
		# 		@product["variants"].select! {|variant| variant[:sku] == sku}
		# 		decrement_inventory(@product["variants"].first.id)
		# 	end		
		# end


	end

# Some simple routes
	get "/" do
		puts "hello"
		# response = HTTParty.get('https://liddle.myshopify.com/admin/oauth/authorize?client_id={api_key}&scope={scopes}&redirect_uri={redirect_uri}&state={nonce}')
	end

	get "/webhook" do
		"Dump your webhooks here."
	end

# Digesting order/create webhooks (set via Shopify admin)
	# post "/webhook" do
	# 	puts "Webhook received!"
	# 	request.body.rewind
 #  		data = JSON.parse request.body.read	

 #  		data["line_items"].each do |x|
 #  			order_li_qty = x["quantity"]
 #  			sku = x["sku"]
 #  			find_variant_by_sku_and_decrement_inventory(sku,order_li_qty)
 #  		end
		
	# 	order_id = data["id"]
	# 	add_note(order_id)
	# end	
end

