class ProductLineObject < DataFactory

  include DateFactory
  include StringFactory
  include GlobalConfig

  attr_accessor   :line_number,
                  :description, :catalog_number, :size_packaging,
                  :unit_price, :quantity, :ext_price

  def defaults
    { quantity: '1' }
  end

  def initialize(browser, opts={})
    @browser = browser
    set_options(defaults.merge(opts))
  end

  # Currently, #create doesn't really interact with the page because we add
  # items to this sort of collection through the shop search pages. Hence, we're
  # simply absorbing the info from the page.
  def create; end

  def edit(opts={})
    on(ShopCartPage).update_product_quantity(@line_number).fit opts[:quantity]
    update_options(opts)
  end

  def delete
    on(ShopCartPage).delete_product @line_number
  end

  def fill_out_extended_attributes
    # Override this method if you have site-specific extended attributes.
  end

  def update_extended_attributes(opts = {})
    # Override this method if you have site-specific extended attributes.
  end
  alias_method :edit_extended_attributes, :update_extended_attributes

end

class ProductLineObjectCollection < LineObjectCollection

  contains ProductLineObject

  attr_accessor :supplier_name, :supplier_subtotal

  def update_from_page!(target=:new)
    on ShopCartPage do |lines|
      clear # Drop any cached lines. More reliable than sorting out an array merge.

      lines.expand_all
      unless lines.current_product_count.zero?
        (0..(lines.current_product_count - 1)).to_a.collect!{ |i|
          pull_existing_product(i, target).merge(pull_extended_existing_product(i, target))
        }.each { |new_obj|
          # Update the stored lines
          self << (make contained_class, new_obj)
        }
      end

    end
  end

  # @param [Fixnum] i The line number to look for (zero-based)
  # @param [Symbol] target Which search alias to pull from (most useful during a copy action). Defaults to :new
  # @return [Hash] The return values of attributes for the given line
  def pull_existing_product(i=0, target=:new)
    pulled_product = Hash.new

    on ShopCartPage do |scp|
      case target
        when :old
          pulled_product = {
            name:   scp.old_product_name(i),
            active: yesno2setclear(scp.old_product_active(i))
          }
        when :new
          pulled_product = {
            name:   scp.update_product_name(i),
            active: yesno2setclear(scp.update_product_active(i))
          }
      end
    end

    pulled_product
  end

  # @param [Fixnum] i The line number to look for (zero-based)
  # @param [Symbol] target Which search alias to pull from (most useful during a copy action). Defaults to :new
  # @return [Hash] The return values of attributes for the given line
  def pull_extended_existing_product(i=0, target=:new)
    # This can be implemented for site-specific attributes. See the Hash returned in
    # the #collect! in #update_from_page! above for the kind of way to get the
    # right return value.
    Hash.new
  end

end