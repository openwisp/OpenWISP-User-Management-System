class AddNewConfigurationKeys < ActiveRecord::Migration
  
  keys = YAML::load(File.open("db/fixtures/configurations.yml"))
  
  @configurations = [
    keys[61] # logo
  ]
  
  def self.up
    @configurations.each do |config|
      if Configuration.get(config['key']).nil?
        Configuration.set(config['key'], config['value'])
      end
    end
  end

  def self.down
    @configurations.each do |config|
      c = Configuration.find_by_key(config['key'])
      unless c.nil?
        c.destroy
      end
    end
  end
end
