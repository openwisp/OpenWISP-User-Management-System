require 'test_helper'

class CreditCardTransactionTest < ActiveSupport::TestCase
  test "model basic validation" do
    t = CreditCardTransaction.new
    
    assert !t.valid?
    assert_equal t.errors.keys.length, 3
    assert_equal t.errors.keys, [:user_id, :ip_address, :amount]
  end
  
  test "user_daily_transactions_below_limit" do
    Configuration.set('credit_card_max_daily_user_transactions', 10)
    CreditCardTransaction.destroy_all
    
    user = User.find(2)
    
    assert_equal 0, ActionMailer::Base.deliveries.length
    
    # -- same user id but different ip address -- #
    
    t0 = CreditCardTransaction.new(
      :user_id => user.id,
      :ip_address => '127.0.0.11',
      :amount => '0.00'
    )
    
    assert t0.valid?
    
    (1..10).each do |n|
      t = CreditCardTransaction.new(
        :user_id => user.id,
        :ip_address => '127.0.0.' + (0+n).to_s,
        :amount => '0.00'
      )
      t.save!
    end
    
    assert !t0.valid?
    assert_equal 1, t0.errors.keys.length
    assert_equal [:id], t0.errors.keys
    assert_equal 1, ActionMailer::Base.deliveries.length
    
    CreditCardTransaction.destroy_all
    
    assert t0.valid?
    
    # -- same ip address but different user id -- #
    
    (1..10).each do |n|
      t = CreditCardTransaction.new(
        :user_id => n,
        :ip_address => '127.0.0.11',
        :amount => '0.00'
      )
      t.save!
    end
    
    assert !t0.valid?
    assert_equal 1, t0.errors.keys.length
    assert_equal [:id], t0.errors.keys
    assert_equal 2, ActionMailer::Base.deliveries.length
    ActionMailer::Base.deliveries = []
    
    CreditCardTransaction.destroy_all
    
    assert t0.valid?
    
    # -- same ip address but different user id on different dates -- #
    
    (1..10).each do |n|
      t = CreditCardTransaction.new(
        :user_id => n,
        :ip_address => '127.0.0.11',
        :amount => '0.00'
      )
      t.save!
      t.created_at = n.days.ago
      t.save!
    end
    
    assert t0.valid?
  end
  
  test "YEARLY_LIMIT_STARTS_FROM" do
    assert Date.parse("#{Date.today.year}-01-01"), CreditCardTransaction.YEARLY_LIMIT_STARTS_FROM
  end
  
  test "current_total_yearly_transactions" do
    t0 = CreditCardTransaction.new(
      :user_id => 2,
      :ip_address => '127.0.0.11',
      :amount => '0.00'
    )
    
    assert 0, t0.current_total_yearly_transactions
    
    t0.save!
    
    assert 1, t0.current_total_yearly_transactions
    
    ActionMailer::Base.deliveries = []
    CreditCardTransaction.destroy_all
  end
  
  test "total_yearly_transactions_below_limit" do
    Configuration.set('credit_card_max_daily_user_transactions', 10)
    Configuration.set('credit_card_max_yearly_transactions', 2)
    
    CreditCardTransaction.destroy_all
    
    user = User.find(2)
    
    assert_equal 0, ActionMailer::Base.deliveries.length
    
    # -- same user id but different ip address -- #
    
    t0 = CreditCardTransaction.new(
      :user_id => user.id,
      :ip_address => '127.0.0.11',
      :amount => '0.00'
    )
    
    assert t0.valid?
    
    (1..2).each do |n|
      t = CreditCardTransaction.new(
        :user_id => user.id,
        :ip_address => '127.0.0.' + (0+n).to_s,
        :amount => '0.00'
      )
      t.save!
    end
    
    # 1 email because limit is reached
    assert_equal 1, ActionMailer::Base.deliveries.length
    
    assert !t0.valid?
    assert_equal 1, t0.errors.keys.length
    assert_equal [:id], t0.errors.keys
    # email because tried to validate again after limit is reached
    assert_equal 2, ActionMailer::Base.deliveries.length
    
    ActionMailer::Base.deliveries = []
    
    Configuration.set('credit_card_max_yearly_transactions', 10000)
  end
  
  test "notify_if_warning_threshold_reached" do
    Configuration.set('credit_card_max_daily_user_transactions', 10)
    Configuration.set('credit_card_max_yearly_transactions', 4)
    Configuration.set('credit_card_max_transaction_warning_threshold', 2)
    
    CreditCardTransaction.destroy_all
    
    user = User.find(2)
    
    assert_equal 0, ActionMailer::Base.deliveries.length
    
    # -- same user id but different ip address -- #
    
    t0 = CreditCardTransaction.new(
      :user_id => user.id,
      :ip_address => '127.0.0.11',
      :amount => '0.00'
    )
    
    assert t0.valid?
    
    (1..2).each do |n|
      t = CreditCardTransaction.new(
        :user_id => user.id,
        :ip_address => '127.0.0.' + (0+n).to_s,
        :amount => '0.00'
      )
      t.save!
    end
    
    assert t0.valid?
    assert_equal 1, ActionMailer::Base.deliveries.length
    
    t0.save!
    assert_equal 1, ActionMailer::Base.deliveries.length
    
    ActionMailer::Base.deliveries = []
    Configuration.set('credit_card_max_yearly_transactions', 10000)
    Configuration.set('credit_card_max_transaction_warning_threshold', 100)
  end
  
  test "disable_if_max_yearly_transaction_limit_reached" do
    Configuration.set('credit_card_max_daily_user_transactions', 10)
    Configuration.set('credit_card_max_yearly_transactions', 4)
    Configuration.set('credit_card_max_transaction_warning_threshold', 10)
    
    CreditCardTransaction.destroy_all
    
    user = User.find(2)
    
    assert_equal 0, ActionMailer::Base.deliveries.length
    
    # -- same user id but different ip address -- #
    
    t0 = CreditCardTransaction.new(
      :user_id => user.id,
      :ip_address => '127.0.0.11',
      :amount => '0.00'
    )
    
    assert t0.valid?
    
    (1..4).each do |n|
      t = CreditCardTransaction.new(
        :user_id => user.id,
        :ip_address => '127.0.0.' + (0+n).to_s,
        :amount => '0.00'
      )
      t.save!
    end
    
    assert_equal 1, ActionMailer::Base.deliveries.length
    
    assert !t0.valid?
    assert_equal 2, ActionMailer::Base.deliveries.length
    
    ActionMailer::Base.deliveries = []
    Configuration.set('credit_card_max_yearly_transactions', 10000)
    Configuration.set('credit_card_max_transaction_warning_threshold', 100)
  end
end
