class AddConfigurationKeys < ActiveRecord::Migration

  keys = YAML::load(File.open("db/fixtures/configurations.yml"))

  @configurations = [
    keys[44],
    keys[45],
    keys[71],
    keys[72],
    keys[73],
    keys[74],
    keys[75],
    keys[77],
    keys[78],
    keys[79],
    keys[80],
    keys[81],
    keys[82],
    keys[83]
  ]

  def self.up
    @configurations.each do |config|
      if Configuration.get(config['key']).nil?
        Configuration.create(:key => config['key'],
                             :value => config['value'],
                             :system_key => config['system_key'] == 't')
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
