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
  
  include ActionView::Helpers::SanitizeHelper
  
  def amount
    "%.2f" % self.attributes['amount'].to_f
  end
  
  def tax
    "%.2f" % self.attributes['tax'].to_f
  end
  
  def total
    "%.2f" % self.attributes['total'].to_f
  end
  
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
  
  def generate_pdf
    path = Rails.root
    
    # create new document from template
    pdf = Prawn::Document.new(:margin => 59)
    
    # owner: upper right corner
    owner = Configuration.get('invoice_owner_%s' % I18n.locale)
    owner_lines = owner.split('<br>')
    
    owner_lines.each do |line|
      pdf.text line, :inline_format => true, :align => :right, :size => 12
    end
    
    # insert logo if it exist
    logo = "%s/public/images/%s" % [Rails.root, Configuration.get('invoice_logo')]
    if File.exists?(logo)
      pdf.image logo, :position => :left, :vposition => :top, :width => 100, :scale => true#:at => [10, 300]#, :width => 450
    end
    
    # Receipt #<ID>
    pdf.text '<b>%s #%s</b>' % [I18n.t(:Receipt), self.id], :inline_format => true, :align => :right, :size => 15#, :indent_paragraphs => 4
    pdf.move_down 4
    
    # Date
    pdf.text '%s: %s' % [I18n.t(:Date), created_at.strftime("%d/%m/%Y")], :inline_format => true, :align => :right, :size => 12#, :indent_paragraphs => 4
    pdf.move_down 10
    
    ### --- USER DETAILS --- ###    
    
    user = self.user
    
    # customer details heading
    pdf.text '<b>%s</b>' % I18n.t(:Customer_details), :inline_format => true, :align => :left, :size => 14
    pdf.move_down 4
    
    # full name
    pdf.text '%s %s' % [user.given_name.capitalize, user.surname.capitalize], :align => :left, :size => 11
    if user.address != '' and not user.address.nil?
      pdf.move_down 5
      pdf.text user.address.capitalize, :align => :left, :size => 11
    end
    
    # city, zip, country
    user_secondline = ''
    for field in ['city', 'zip', 'state']
      if CONFIG[field]
        user_secondline << ', %s' % user.attributes[field].capitalize
      end
    end
    
    if user_secondline != ''
      # remove initial ", "
      user_secondline = user_secondline[2 .. -1]
      pdf.move_down 5
      pdf.text user_secondline, :align => :left, :size => 11
    end
    
    # prepare data for table containing price and description
    description = Configuration.get('invoice_description_%s' % I18n.locale)
    description.gsub!('</div>', '<br>')
    description.gsub!('</p>', '<br>')
    description = sanitize(description, :tags => ['b', 'i', 'u', 'br'])
    description_lines = owner.split('<br>')
    
    currency_dictionary = {
      '242' => 'EUR',
      '1' => 'USD',
      '2' => 'GBP',
      '71' => 'JPY;'
    }
    currency = currency_dictionary[Configuration.get('gestpay_currency')]
    
    data = [
      [I18n.t(:Description), I18n.t(:Amount)],
      [Configuration.get('invoice_description_%s' % I18n.locale), '%s %s' % [self.amount, currency]],
      ['%s: ' % I18n.t(:Tax), '%s %s' % [self.tax, currency]],
      ['%s: ' % I18n.t(:Total), '%s %s' % [self.total, currency]]
    ]
    
    pdf.move_down 50
    
    # print table
    pdf.table(data) do |table|
      table.width = 500
      table.column_widths = [360, 140]
      table.style(table.rows(0), :background_color => 'E8E9EC', :align => :center, :font_style => :bold )
      table.style(table.rows(2), :background_color => 'E8E9EC')
      table.style(table.rows(3), :background_color => 'E8E9EC')
      table.style(table.columns(1), :align => :center )
      table.style(table.rows(2..3).columns(0), :align => :right )
      table.style(table.rows(0..3).columns(0..1), :size => 10 )
      table.style(table.rows(2..3).columns(0), :font_style => :bold )
    end
    
    pdf.move_down 50
    
    # Transaction Info
    pdf.text '<b>%s</b>' % [I18n.t(:Transaction_info)], :inline_format => true, :align => :left, :size => 14
    pdf.move_down 4
    
    # Table
    data = [
      [I18n.t(:Date), I18n.t(:Gateway), I18n.t(:Transaction_ID), I18n.t(:Amount)],
      [created_at.strftime("%d/%m/%Y"), 'Gestpay Banca Sella', self.transaction_id.upcase, "#{self.total} #{currency}"]
    ]
    
    # Print transaction info table
    pdf.table(data) do |table|
      table.width = 500
      table.style(table.rows(0), :background_color => 'E8E9EC', :font_style => :bold )
      table.style(table.rows(0..3).columns(0..4), :size => 10, :align => :center )
      table.style(table.rows(1), :size => 9 )
    end
    
    filename = "#{path}/invoices/receipt-%s-date-%s.pdf" % [self.id, created_at.strftime("%Y-%m-%d")]
    pdf.render_file(filename)
    return filename
  end
end