class PaymentRequestObject < KFSDataObject

  include ProcessItemsAccountingLinesMixin

  attr_accessor :number,
                # == Payment Request Detail ==
                :account_distribution_method, :payment_request_positive_approval_required,
                # == Vendor (Incomplete) ==
                :vendor_name, :vendor_number, :vendor_address_1, :vendor_address_2, :attention,
                :vendor_city, :vendor_state, :vendor_province, :vendor_postal_code, :vendor_country,
                # == Invoice Info ==
                :purchase_order_number, :pay_date, :bank_code,
                :invoice_date, :invoice_number, :vendor_invoice_amount,
                :payment_method_code,
                # == Process Items ==
                :freight_extended_cost, :freight_description,
                :misc_extended_cost, :misc_description,
                :sh_extended_cost, :sh_description,
                :close_po,
                # == Tax Tab ==
                :income_class_code, :federal_tax_pct, :state_tax_pct, :postal_country_code


  def defaults
    super.merge(default_additional_charges_accounting_lines)
         .merge(default_items)
  end

  def initialize(browser, opts={})
    @browser = browser
    set_options(defaults.merge(get_aft_parameter_values_as_hash(ParameterConstants::DEFAULTS_FOR_PAYMENT_REQUEST))
                        .merge(opts))
  end

  # Fills out the Payment Request Initiation page that is the first step of creating a Payment Request
  def initiate_request
    on PaymentRequestInitiationPage do |page|
      fill_out page, :purchase_order_number,
                     :invoice_date, :invoice_number, :vendor_invoice_amount
      page.continue
    end
    #on(YesOrNoPage) { |p| p.yes if p.yes_button.present? } # Sometimes it will ask for confirmation, currently timing out :(
    #on(YesOrNoPage).yes_if_possible # Sometimes it will ask for confirmation, currently timing out :(
    on PaymentRequestPage do |page| # Is there a special amount of framing necessary for a PREQ?
      #sleep 300
      #page.wait_until(60000, 'Payment Request page took too long to process!') { puts right_now[:samigo]; page.frm.div(id: /^headerarea/).h1.visible? }
      @number = page.preq_id
    end
  end

  # Fills out the Payment Request's tax tab. This should not be done during an edit,
  # @param [Hash] opts Elements to update
  def update_tax_tab(opts={})
    on PaymentRequestPage do |page|
      edit_fields opts, page, :income_class_code, :federal_tax_pct, :state_tax_pct, :postal_country_code
    end
    update_options(opts)
  end

  # Note: You'll need to update the subcollections (e.g. Items) separately.
  # @param [Hash] opts Elements to update
  def update(opts={})
    super
    on PaymentRequestPage do |page|
      edit_fields opts, page, :account_distribution_method, :payment_request_positive_approval_required,
                              :vendor_name, :vendor_number, :vendor_address_1, :vendor_address_2, :attention,
                              :vendor_city, :vendor_state, :vendor_province, :vendor_postal_code, :vendor_country,
                              :purchase_order_number, :pay_date, :bank_code,
                              :invoice_date, :invoice_number, :vendor_invoice_amount,
                              :payment_method_code,
                              :freight_extended_cost, :freight_description,
                              :misc_extended_cost, :misc_description,
                              :sh_extended_cost, :sh_description,
                              :close_po
    end
    update_options(opts)
  end
  alias_method :edit, :update

  include ItemLinesMixin

end