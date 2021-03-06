class AccountDelegateGlobalObject < KFSDataObject

  attr_accessor :doc_type, :primary_route, :start_date,
                :principal_name, :chart_code, :account_number

  def defaults
    super.merge({
      description:    random_alphanums(20, 'AFT'),
      principal_name: get_aft_parameter_value(ParameterConstants::DEFAULT_FISCAL_OFFICER),
      chart_code:     get_aft_parameter_value(ParameterConstants::DEFAULT_CHART_CODE_WITH_NAME),
      account_number: get_aft_parameter_value(ParameterConstants::DEFAULT_ACCOUNT_NUMBER)
    }).merge(get_aft_parameter_values_as_hash(ParameterConstants::DEFAULTS_FOR_ACCOUNT_DELEGATE_GLOBAL))
  end

  def build
    visit(MainPage).account_delegate_global
    on AccountDelegateGlobalPage do |page|
      page.description.focus
      page.alert.ok if page.alert.exists? # Because, y'know, sometimes it doesn't actually come up...
      fill_out page, :description, :doc_type, :principal_name
      fill_out_extended_attributes(:delegate)
      page.add_delegate

      fill_out page, :chart_code, :account_number
      fill_out_extended_attributes(:account)
      page.add_account
    end
  end

  #def add_multiple_accounting_lines
  #  if !@add_multiple_accounting_lines.nil?
  #    on(AccountGlobalPage).add_multiple_accounting_lines
  #    on AccountGlobalLookupPage do |page|
  #      page.account_number.fit @search_account_number
  #      page.search
  #      page.select_all_rows_from_this_page
  #      page.return_selected_results
  #    end
  #  end
  #end

  # Class Methods:
  class << self

    # Attributes that are required for a successful save/submit.
    # @return [Array] List of Symbols for attributes that are required
    def required_attributes
      superclass.required_attributes | [ :start_date, :doc_type, :principal_name, :chart_code, :account_number]
    end

  end #class<<self

end