module OpenFoodNetwork
  class SubscriptionPaymentUpdater
    def initialize(order)
      @order = order
    end

    def update!
      create_payment
      ensure_payment_source
      return if order.errors.any?

      payment.update_attributes(amount: order.outstanding_balance)
    end

    private

    attr_reader :order

    def payment
      @payment ||= order.pending_payments.last
    end

    def create_payment
      return if payment.present?

      @payment = order.payments.create(
        payment_method_id: order.subscription.payment_method_id,
        amount: order.outstanding_balance
      )
    end

    def card_required?
      [Spree::Gateway::StripeConnect,
       Spree::Gateway::StripeSCA].include? payment.payment_method.class
    end

    def card_set?
      payment.source is_a? Spree::CreditCard
    end

    def ensure_payment_source
      return unless card_required? && !card_set?

      ensure_credit_card || order.errors.add(:base, :no_card)
    end

    def ensure_credit_card
      return false if saved_credit_card.blank? || !allow_charges?

      payment.update_attributes(source: saved_credit_card)
    end

    def allow_charges?
      order.customer.allow_charges?
    end

    def saved_credit_card
      order.user.default_card
    end

    def errors_present?
      order.errors.any?
    end
  end
end
