class CreateCreditCardTransactions < ActiveRecord::Migration
  keys = YAML::load(File.open("db/fixtures/configurations.yml"))
  
  @configurations = [
    keys[110],
    keys[111],
    keys[112],
    keys[113],
  ]
  
  def self.up
    create_table :credit_card_transactions do |t|
      t.integer :user_id
      t.string :ip_address
      t.decimal :amount, :precision => 8, :scale => 2
      t.text :credit_card_info
      t.timestamps
    end
    
    # add new config keys
    @configurations.each do |config|
      if Configuration.find_by_key(config['key']).nil?
        Configuration.set(config['key'], config['value'])
      end
    end
  end

  def self.down
    drop_table :credit_card_transactions
    
    # remove config keys
    @configurations.each do |config|
      c = Configuration.find_by_key(config['key'])
      unless c.nil?
        c.destroy
      end
    end
  end
end
