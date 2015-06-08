class AddFurLanguageConfigKeys < ActiveRecord::Migration
  keys = YAML::load(File.open("db/fixtures/configurations.yml"))

  @configurations = [
    keys[120],
    keys[121],
    keys[122],
    keys[123],
    keys[124],
    keys[125],
    keys[126],
    keys[127],
    keys[128],
    keys[129],
    keys[130],
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
