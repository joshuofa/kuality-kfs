Then /^The Chart of Accounts on the accounting line defaults appropriately for the (.*) document$/ do |document|
  on page_class_for(document) do |page|
    if ['Budget Adjustment', 'Internal Billing', 'General Error Correction'].include?(document)
      page.target_chart_code.value.should == get_aft_parameter_value(ParameterConstants::DEFAULT_CHART_CODE)
    end
    page.source_chart_code.value.should == get_aft_parameter_value(ParameterConstants::DEFAULT_CHART_CODE)
  end
end

And /^I add a (From|To|Source|Target) Accounting Line to the (.*) document with Amount (\w+)$/ do |type, document, amount|
  account_number =  get_account_of_type('Endowed NonGrant')
  if document.eql?('Service Billing') && type.eql?('Source')
    account_number = @sb_account
  end
  case document
    when 'Internal Billing'
      object_code = get_object_code_of_type('Income-Cash')
    when 'General Error Correction'
      object_code = get_object_code_of_type('Accounts Receivable Asset')
  end
  chart_of_accounts_code = get_aft_parameter_value(ParameterConstants::DEFAULT_CHART_CODE)
  step "I add a #{type} Accounting Line to the #{document} document with the following:",
       table(%Q{
      | Chart Code   | #{chart_of_accounts_code} |
      | Number       | #{account_number}         |
      | Object Code  | #{object_code}            |
      | Amount       | #{amount}                 |
       })

end


And /^I lookup a Service Bill Processor as initiator and an associated account as source account$/ do
  step 'I am logged in as a KR Technical Administrator'
  visit(AdministrationPage).role
  on RoleLookup do |lookup|
    lookup.id.fit      '13'
    lookup.search
    lookup.edit_random # There can only be one!
  end
  # puts on(RolePage).frm.div(id: 'tab-Assignees-div').tables[2].rows.length
  on RolePage do |page|
    random_row = rand(2..page.member_table.rows.length - 1)
    puts page.member_table[random_row][4].text,page.member_table[random_row][8].text
    @sb_account = page.member_table[random_row][8].text
    step "I am logged in as \"#{page.member_table[random_row][4].text}\""
  end

end
