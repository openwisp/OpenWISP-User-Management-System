class DeDataMigration < ActiveRecord::Migration
  keys = YAML::load(File.open("db/fixtures/configurations.yml"))

  @configurations = [
    keys[142],
    keys[143],
    keys[144],
    keys[145],
    keys[146],
    keys[147],
    keys[148],
    keys[149],
    keys[150],
    keys[151],
    keys[152],
  ]

  def self.up
    @configurations.each do |config|
      begin
        Configuration.create(:key => config['key'],
                             :value => config['value'],
                             :system_key => config['system_key'] == 't')
      rescue
        Configuration.find_by_key(config['key']).destroy()
        Configuration.create(:key => config['key'],
                             :value => config['value'],
                             :system_key => config['system_key'] == 't')
      end
    end
  end

  def self.down
  end
end
