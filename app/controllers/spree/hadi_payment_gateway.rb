module Spree
  class HadiPaymentGatewayController < StoreController


    def payment
      order_id = params[:orders_id]
      payment_total = params[:price]

      hadiapitest_to_post = "https://shop.burux.com/api/PaymentService/Request"

      callapi = HTTParty.post(hadiapitest_to_post.to_s, :body => {"App":"VisitApp",
      "Type":"INV","Price":payment_total,"Model":"{PaymentTitle:'پرداخت سفارش شماره تست بابت خرید از فروشگاه ویزیتور ها'}",
      "CallbackAction":"RedirectToUrl","ForceRedirectBank":"true",
      "CallbackUrl":"https://localhost:44383/?action=bankpayment&reqid={reqid}&payid={payid}&paytyp={type}"})

      invoice_url = callapi["InvoiceUrl"]
      request_id = callapi["RequestID"]
        

      Spree::HadiPaymentGatewayCheckout.create(request_id: request_id ,payment_total: payment_total, order_id: order_id)
        
      url_payment_services = {'payment_url'=> invoice_url}.to_json

      render json: url_payment_services
    end

    def verifypayment
      request_id = params[:request_id]
      payment_total = params[:payment_total]

      verifypayment_to_post = "https://shop.burux.com/api/PaymentService/Verify"
      verifypayment = HTTParty.post(verifypayment_to_post.to_s, :body => {"RequestID":request_id, "Price":payment_total})

      if verifypayment["IsSuccess"] == true
        order_success = Spree::HadiPaymentGatewayCheckout.find_by(request_id: request_id)
        order_id = order_success.order_id
        order_success.success_payment = true
        order_success.save

        payment_completed = Spree::Payment.find_by(order_id: order_id)
        payment_completed.state = "completed"
        payment_completed.save

        #order_payment_total = Spree::Order.find_by(id: order_id)
        #order_payment_total.payment_total += payment_total
        #order_payment_total.save

        redirect_to controller: 'HadiPaymentGatewayCheckout', action: 'confrim'#, payment_total: payment_total, request_id: request_id

      elsif verifypayment["IsSuccess"] == false
        order_success = Spree::HadiPaymentGatewayCheckout.find_by(request_id: request_id)
        order_success.success_payment = false
        order_success.save

        redirect_to controller: 'HadiPaymentGatewayCheckout', action: 'cancel'#, payment_total: payment_total, request_id: request_id


      end        
    end

    def confrim
      #thank_you_page

    end

    def cancel
      #redirect_to payment
    end
    def provider
    end
    def refund(payment, amount)
      refund_type = payment.amount == amount.to_f ? "Full" : "Partial"
      refund_transaction = provider.build_refund_transaction({
        :TransactionID => payment.source.transaction_id,
        :RefundType => refund_type,
        :Amount => {
          :currencyID => payment.currency,
          :value => amount },
        :RefundSource => "any" })
      refund_transaction_response = provider.refund_transaction(refund_transaction)
      if refund_transaction_response.success?
        payment.source.update({
          :refunded_at => Time.now,
          :refund_transaction_id => refund_transaction_response.RefundTransactionID,
          :state => "refunded",
          :refund_type => refund_type
        })

        payment.class.create!(
          :order => payment.order,
          :source => payment,
          :payment_method => payment.payment_method,
          :amount => amount.to_f.abs * -1,
          :response_code => refund_transaction_response.RefundTransactionID,
          :state => 'completed'
        )
      end
      refund_transaction_response
    end
  end
end
