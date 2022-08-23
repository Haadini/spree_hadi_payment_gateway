module Spree
	class HadiPaymentGatewayCheckout < ActiveRecord::Base
		belongs_to :order
	end
end