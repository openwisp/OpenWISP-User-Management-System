class AddSlLanguageConfigKeys < ActiveRecord::Migration
  keys = YAML::load(File.open("db/fixtures/configurations.yml"))

  @configurations = [
    keys[131],
    keys[132],
    keys[133],
    keys[134],
    keys[135],
    keys[136],
    keys[137],
    keys[138],
    keys[139],
    keys[140],
    keys[141],
  ]

  def self.up
    @configurations.each do |config|
      if Configuration.find_by_key(config['key']).nil?
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
