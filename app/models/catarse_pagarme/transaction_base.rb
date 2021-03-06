module CatarsePagarme
  class TransactionBase
    attr_accessor :attributes, :contribution,
      :transaction, :user, :subscription

    def initialize(attributes, contribution)
      self.attributes = attributes
      self.contribution = contribution
      self.user = contribution.user
    end

    def change_contribution_state
      self.contribution.update_attributes(attributes_to_contribution)
      self.contribution.payment_notifications.create(extra_data: self.transaction.to_json)
      delegator.change_status_by_transaction(self.transaction.status)
    end

    def payment_method
      PaymentType::CREDIT_CARD
    end

    def attributes_to_contribution
      {
        payment_choice: payment_method,
        payment_service_fee: delegator.get_fee(payment_method, self.transaction.acquirer_name),
        payment_id: self.transaction.id,
        payment_method: 'Pagarme',
        slip_url: self.transaction.boleto_url,
        installments: (self.transaction.installments || 1),
        installment_value: (delegator.value_for_installment(self.transaction.installments || 0) / 100.0).to_f,
        acquirer_name: self.transaction.acquirer_name,
        acquirer_tid: self.transaction.tid
      }
    end

    def delegator
      self.contribution.pagarme_delegator
    end
  end
end
