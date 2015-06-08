class AddSpanishTranslations < ActiveRecord::Migration
  keys = YAML::load(File.open("db/fixtures/configurations.yml"))

  # new spanish config keys
  @configurations = (98..108).map { |n| keys[n] }

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
