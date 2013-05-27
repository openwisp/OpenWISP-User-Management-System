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
  
  def tax
    "%.2f" % self.attributes['tax'].to_f
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
    invoice.transaction_id = ActiveSupport::JSON.decode(user.credit_card_info)['shop_transaction']
    
    # calculate VAT depending on tax rate
    tax_costant = 1.0 + Configuration.get('tax_rate').to_f / 100
    total = Configuration.get('credit_card_verification_cost').to_f
    amount = total / tax_costant
    
    invoice.amount = amount
    invoice.tax = total - amount
    invoice.total = total
    
    invoice.save!
    return invoice
  end
end