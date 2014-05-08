class UserGroupObject < DataFactory

  include StringFactory

  attr_accessor :id, :user_name

  def initialize(browser, opts={})
    @browser = browser

    defaults = {

    }

    set_options(defaults.merge(get_aft_parameter_values_as_hash(ParameterConstants::DEFAULTS_FOR_USER_GROUP)).merge(opts))
    requires :user_name
  end

  # All navigation is done in the parent, UserObject.
  # IMPORTANT: This includes saving the changes!
  def create
    on PersonPage do |create|
      create.group_id.set @id
      create.add_group
    end
  end

end

class UserGroupsCollection < CollectionsFactory

  contains UserGroupObject



end