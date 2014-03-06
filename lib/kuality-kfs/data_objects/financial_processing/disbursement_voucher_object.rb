class DisbursementVoucherObject < KFSDataObject

  DOC_INFO = { label: 'Disbursement Voucher Document', type_code: 'DV' }

  include PaymentInformationMixin
  include AccountingLinesMixin
  alias :add_target_line :add_source_line

  attr_accessor :organization_document_number, :explanation,
                :contact_name, :phone_number, :email_address,
                :foreign_draft_in_usd, :foreign_draft_in_foreign_currency, :currency_type

  def initialize(browser, opts={})
    @browser = browser

    defaults = {
        description:                       random_alphanums(40, 'AFT'),
        #foreign_draft_in_foreign_currency: :set,
        #currency_type:                     'Canadian $'
    }
    # this is kind of hack for KFSQA-709, so Payment Info tab will not be filled
    opts.size == 0 ? defaults.merge!(default_accounting_lines).merge!(default_payment_information_lines) : defaults.merge!(default_accounting_lines)
    set_options(defaults.merge(opts))
  end

  def build
    visit(MainPage).disbursement_voucher
    on DisbursementVoucherPage do |page|
      page.expand_all
      page.description.focus
      page.alert.ok if page.alert.exists? # Because, y'know, sometimes it doesn't actually come up...
      fill_out page, :description, :organization_document_number, :explanation,
               :contact_name, :phone_number, :email_address,
               :foreign_draft_in_usd, :foreign_draft_in_foreign_currency, :currency_type
    end
  end

  def view
    visit(MainPage).doc_search
    on DocumentSearch do |search|
      search.document_type.fit ''
      search.document_id.fit @document_id
      search.search
      search.open_doc @document_id
    end
  end

end