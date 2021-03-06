include Utilities

And /^the next pending action for the (.*) document is an? (.*) from a (.*)$/ do |document, action, user_type|

  on page_class_for(document) do |page|
    page.show_route_log_button.wait_until_present
    page.show_route_log unless page.route_log_shown?

    page.pnd_act_req_table_action.visible?.should

    if page.pnd_act_req_table_requested_of.text.match(/Multiple/m)
      page.show_pending_action_requests_in_action_list if page.pending_action_requests_in_action_list_hidden?

      page.pnd_act_req_table_multi.visible?.should
      page.pnd_act_req_table_multi_action.text.should match(/#{action}/)
      page.pnd_act_req_table_multi_annotation.text.should match(/#{user_type}/)
    else
      page.pnd_act_req_table_action.text.should match(/#{action}/)
      page.pnd_act_req_table_annotation.text.should match(/#{user_type}/)
    end
  end
end

When /^I route the (.*) document to final$/ do |document|
  step "I view the #{document} document"
  until 'FINALPROCESSSED'.include? on(page_class_for(document)).document_status
    step "I switch to the user with the next Pending Action in the Route Log for the #{document} document"
    step "I view the #{document} document"
    step "I attach an Invoice Image to the #{document} document" if document == 'Payment Request' &&
                                                                    (document_object_for(document).notes_and_attachments_tab.length.zero? ||
                                                                     document_object_for(document).notes_and_attachments_tab.index{ |na| na.type == 'Invoice Image' }.nil?)
    step "I approve the #{document} document, confirming any questions, if it is not already FINAL"
    step "I view the #{document} document"
  end

end


Then  /^the (.*) document routes to the (.*) node$/ do |document, node|
  pending_action_request_node = ''
  step "the #{document} document goes to ENROUTE"
  on page_class_for(document) do |page|
    page.show_route_log_button.wait_until_present
    page.show_route_log unless page.route_log_shown?
    page.pnd_act_req_table_action.visible?.should
    page.show_pending_action_requests_in_action_list unless page.pending_action_requests_in_action_list_shown?

    until (page.pen_act_req_table_sub_node == node) || ('FINALPROCESSSED'.include? on(page_class_for(document)).document_status)
      step "I route the #{document} document to the next node"
      page.show_route_log_button.wait_until_present
      page.show_route_log unless page.route_log_shown?
      page.pnd_act_req_table_action.visible?.should
      page.show_pending_action_requests_in_action_list unless page.pending_action_requests_in_action_list_shown?
      pending_action_request_node = page.pen_act_req_table_sub_node
    end #until
  end #on page
  pending_action_request_node.should == node
end


When /^I route the (.*) document to the next node$/ do |document|
  step "I view the #{document} document"
  step "I switch to the user with the next Pending Action in the Route Log for the #{document} document"
  step "I view the #{document} document"
  step "I attach an Invoice Image to the #{document} document" if document == 'Payment Request' &&
      (document_object_for(document).notes_and_attachments_tab.length.zero? ||
          document_object_for(document).notes_and_attachments_tab.index{ |na| na.type == 'Invoice Image' }.nil?)
  step "I approve the #{document} document, confirming any questions, if it is not already FINAL"
  step "I view the #{document} document"
end


Then /^I switch to the user with the next Pending Action in the Route Log for the (.*) document$/ do |document|
  new_user = ''
  on page_class_for(document) do |page|
    page.expand_all
    page.show_route_log unless page.route_log_shown?

    page.pnd_act_req_table_action.visible?.should

    if page.pnd_act_req_table_requested_of.text.match(/Multiple/m)
      page.show_pending_action_requests_in_action_list if page.pending_action_requests_in_action_list_hidden?

      page.pnd_act_req_table_multi_requested_of.links.first.click
    else
      #page.pnd_act_req_table_requested_of.links.first.click
      page.first_pending_approve
    end

    page.use_new_tab

    # TODO: Actually build a functioning PersonPage to grab this. It seems our current PersonPage ain't right.
    if page.frm.div(id: 'tab-Overview-div').exists?
      # WITH FRAME
      page.frm.div(id: 'tab-Overview-div').tables[0][1].tds.first.should exist
      page.frm.div(id: 'tab-Overview-div').tables[0][1].tds.first.text.empty?.should_not

      if page.frm.div(id: 'tab-Overview-div').tables[0][1].text.include?('Principal Name:')
        new_user = page.frm.div(id: 'tab-Overview-div').tables[0][1].tds.first.text
      else
        # TODO : this is for group.  any other alternative ?
        mbr_tr = page.frm.select(id: 'document.members[0].memberTypeCode').parent.parent.parent
        new_user = mbr_tr[4].text
      end

    elsif page.div(id: 'tab-Overview-div').exists?
      #NO FRAME
      page.div(id: 'tab-Overview-div').tables[0][1].tds.first.should exist
      page.div(id: 'tab-Overview-div').tables[0][1].tds.first.text.empty?.should_not

      if page.div(id: 'tab-Overview-div').tables[0][1].text.include?('Principal Name:')
        new_user = page.div(id: 'tab-Overview-div').tables[0][1].tds.first.text
      else
        # TODO : this is for group.  any other alternative ?
        mbr_tr = page.select(id: 'document.members[0].memberTypeCode').parent.parent.parent
        new_user = mbr_tr[4].text
      end
    end

  page.close_children
  end

  @new_approver = new_user
  step "I am logged in as \"#{new_user}\""
end

And /^the initiator is not an approver in the Future Actions table$/ do
  on KFSBasePage do |page|
    page.expand_all
    page.show_future_action_requests if page.show_future_action_requests_button.exists?
    page.future_actions_table.rows(text: /APPROVE/m).any? { |r| r.text.include? 'Initiator' }.should_not
  end
end

And /^I verify that the following (Pending|Future) Action approvals are requested:$/ do |action_type, roles|
  roles = roles.raw.flatten
  on KFSBasePage do |page|
    page.expand_all
    case action_type
      when 'Pending'
        roles.each do |ra|
          page.pnd_act_req_table.rows(text: /APPROVE/m).any? { |r| r.text.include? ra }.should
        end
      when 'Future'
        page.show_future_action_requests if page.show_future_action_requests_button.exists?
        roles.each do |ra|
          page.future_actions_table.rows(text: /APPROVE/m).any? { |r| r.text.include? ra }.should
        end
    end
  end

end

And /^the POA Routes to the FO$/ do
  @fo_users.length.should >= 1
end


And /^the (.*) document does not route to the Financial Officer$/ do  |document|
  on(page_class_for(document)).app_doc_status.should_not include 'Fiscal Officer'
end

And /^I capture the (.*) document id number$/ do |document|
  on page_class_for(document) do |page|
    @requisition_id = page.requisition_id if @requisition_id.nil? && page.header_title.include?('Requisition #:')
  end
end

And /^the (.*) document's route log is:$/ do |document, desired_route_log|
  # desired_route_log.hashes.keys => [:Role, :Action]

  on page_class_for(document) do |page|
    page.show_route_log_button.wait_until_present
    page.show_route_log unless page.route_log_shown?

    page.show_pending_action_requests unless page.pending_action_requests_shown?
    page.pnd_act_req_table_action.visible?.should

    page.show_future_action_requests unless page.future_action_requests_shown?
    page.future_actions_table.visible?.should


    # Note: This expects you to list out the full log from start to some end point.
    #       You cannot skip any interim entries, though you could probably skip
    #       entries at the end of the list.
    route_log = page.route_log_hash
    desired_route_log.hashes.each_with_index do |row, i|
      route_log[:annotation][i].should match /#{row[:Role]}/
      route_log[:action][i].should match /#{row[:Action]}/
    end

  end
end