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
        Configuration.set(config['key'], config['value'])
      rescue
        Configuration.find_by_key(config['key']).destroy()
        Configuration.set(config['key'], config['value'])
      end
    end
  end

  def self.down
  end
end
