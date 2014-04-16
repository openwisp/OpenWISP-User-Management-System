class CreditCardTransaction < ActiveRecord::Base
  validates :user_id, :ip_address, :amount, :presence => true
  validate :user_daily_transactions_below_limit
  validate :total_yearly_transactions_below_limit
  
  after_create :notify_if_warning_threshold_reached,
               :disable_if_max_yearly_transaction_limit_reached
  
  # retrieve date from which the yearly limit is counted
  def self.YEARLY_LIMIT_STARTS_FROM
    year_start = Configuration.get('credit_card_year_start')
    
    begin
      date_start = Date.parse("#{Date.today.year}-#{year_start}")
    rescue ArgumentError
      date_start = Date.parse("#{Date.today.year}-01-01")
    end
    
    # if tmp_date is in the future we must recalculate from the previous year
    if date_start > Date.today
      begin
        date_start = Date.parse("#{Date.today.year-1}-#{year_start}")
      rescue ArgumentError
        date_start = Date.parse("#{Date.today.year-1}-01-01")
      end
    end
    
    return date_start
  end
  
  def current_total_yearly_transactions
    start_date = CreditCardTransaction.YEARLY_LIMIT_STARTS_FROM
    return CreditCardTransaction.where('created_at > ?', start_date).count
  end
  
  private
  
  # limit number of transactions by each user to avoid DOSsing
  def user_daily_transactions_below_limit
    max = Configuration.get('credit_card_max_daily_user_transactions', 10).to_i
    count_on_id = CreditCardTransaction.where(:user_id => self.user_id).count
    count_on_ip = CreditCardTransaction.where('created_at LIKE ? AND ip_address = ?', "#{Date.today}%", self.ip_address).count
    
    if count_on_id >= max or count_on_ip >= max
      errors.add(:id, I18n.t(:max_daily_transaction_limit_reached))
      # send exception
      e = Exception.new("max daily transaction limit reached by user_id #{self.user_id} and ip #{self.ip_address}")
      ExceptionNotifier::Notifier.background_exception_notification(e).deliver
    end
  end
  
  # limit number of total transaction to avoid DOSsing and to enforce eventual contract limitations
  def total_yearly_transactions_below_limit
    max = Configuration.get('credit_card_max_yearly_transactions', 10000).to_i
    
    if self.current_total_yearly_transactions >= max
      errors.add(:id, I18n.t(:max_yearly_transaction_limit_reached))
      # send exception
      e = Exception.new("user trying to submit a credit card transaction even if max yearly transaction limit is reached")
      ExceptionNotifier::Notifier.background_exception_notification(e).deliver
    end
  end
  
  # send an email notification when the warning threshold is almost reached
  def notify_if_warning_threshold_reached
    max = Configuration.get('credit_card_max_yearly_transactions', 10000).to_i
    warning_threshold = Configuration.get('credit_card_max_transaction_warning_threshold', 100).to_i
    
    if self.current_total_yearly_transactions == (max - warning_threshold)
      e = Exception.new("WARNING: max yearly transaction limit almost reached!")
      ExceptionNotifier::Notifier.background_exception_notification(e).deliver
    end
  end
  
  # send a notification if max yearly limit reached
  def disable_if_max_yearly_transaction_limit_reached
    start_date = CreditCardTransaction.YEARLY_LIMIT_STARTS_FROM
    max = Configuration.get('credit_card_max_yearly_transactions', 10000).to_i
    total_transactions = CreditCardTransaction.where('created_at > ?', start_date).count
    
    if total_transactions >= max
      e = Exception.new("CRITICAL: max yearly transaction limit reached!")
      ExceptionNotifier::Notifier.background_exception_notification(e).deliver
    end
  end
end
