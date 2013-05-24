class Invoice < ActiveRecord::Base
  belongs_to :user
  
  # * id
  # * user_id
  # * transaction_id
  # * amount
  # * tax
  # * total
  # * created_at
  # * updated_at
  
  validates :user_id, :presence => true, :uniqueness => true
  validates :transaction_id, :presence => true
  validates :amount, :presence => true
  validates :total, :presence => true
  
  def amount
    "%.2f" % self.attributes['amount'].to_f
  end
  
  def total
    "%.2f" % self.attributes['total'].to_f
  end
  
  # static
  
  def self.create_for_user(user)
    invoice = self.new()
    
    user = user.class == Fixnum ? User.find(user) : user
    
    if user.credit_card_info.nil?
      raise 'credit_card_info does not contain all the necessary information'
    end
    
    # it is possible to pass an ID or an user instance
    invoice.user_id = user.id
    invoice.transaction_id = ActiveSupport::JSON.decode(user.credit_card_info)['shop_transaction_id']
    
    tax_rate = @settings['tax_rate'].to_f
    total = @settings['credit_card_verification_cost'].to_f
    
    
    invoice.tax = total * (invoice.tax / 100)
    invoice.amount = total - invoice.tax
  end
end