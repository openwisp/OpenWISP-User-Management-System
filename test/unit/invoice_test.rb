require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  test "create new" do
    invoice = Invoice.new()
    invoice.user_id = 1
    invoice.valid?
    
    assert !invoice.valid?
    
    # * id
    # * user_id
    # * transaction_id
    # * amount
    # * tax
    # * total
    # * created_at
    # * updated_at
    
    assert_difference('Invoice.count') do
      invoice = Invoice.new()
      invoice.user_id = 1
      invoice.transaction_id = '987f37401fbdfssk90ksafsah834mnfasgf'
      invoice.amount = 1
      invoice.tax = 20
      invoice.total = 1.2
      assert invoice.save
    end
  
    # test get methods of decimals
    invoice = Invoice.last
    assert_equal "1.00", invoice.amount
    assert_equal "1.20", invoice.total
    
    # new one with same user_id should fail
    invoice = Invoice.new()
    invoice.user_id = 1
    invoice.transaction_id = '987f37401fbdfssk90ksafsah834mnfasgb'
    invoice.amount = 1
    invoice.tax = 20
    invoice.total = 1.2
    #assert !invoice.save
  end
  
  test "create according to configuration" do
    tax = Configuration.get('tax_rate')
    total = Configuration.get('credit_card_verification_cost')
    
    assert !tax.nil
    assert !total.nil?
  end
end
