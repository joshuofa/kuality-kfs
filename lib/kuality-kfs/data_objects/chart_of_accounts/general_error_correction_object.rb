class GeneralErrorCorrectionObject < KFSDataObject

  include AccountingLinesMixin

  attr_accessor :organization_document_number, :explanation

  def initialize(browser, opts={})
    @browser = browser

    defaults = {
        description:                     random_alphanums(40, 'AFT'),
        organization_document_number:    random_alphanums(10, 'AFT'),
        explanation:                     'Because I said so!'
    }.merge!(default_accounting_lines)

    set_options(defaults.merge(opts))
  end

  def build
    visit(MainPage).general_error_correction
    on GeneralErrorCorrectionPage do |page|
      page.expand_all
      page.description.focus
      page.alert.ok if page.alert.exists? # Because, y'know, sometimes it doesn't actually come up...
      fill_out page, :description, :organization_document_number, :explanation
    end
  end

end