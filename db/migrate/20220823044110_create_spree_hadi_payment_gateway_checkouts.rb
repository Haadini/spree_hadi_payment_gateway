class CreateSpreeHadiPaymentGatewayCheckouts < SpreeExtension::Migration[4.2]
  def change
    create_table :spree_hadi_payment_gateway_checkouts do |t|

      t.string :request_id
      t.string :payment_total
      t.string :state
      t.string :order_id
      t.boolean :success_payment


      t.timestamps
    end
  end
end
