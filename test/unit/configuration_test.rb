require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase
  test "set new configuration" do
    Configuration.set('new_configuration', 'new_value')
    assert Configuration.get('new_configuration') == 'new_value'
  end
  
  test "cache new value" do
    assert !Configuration.cache.keys.include?('new_config')
    assert Configuration.set('new_config', 'new_value')
    
    # updates cache
    Configuration.get('new_config')
    
    assert Configuration.cache.keys.include?(:new_config)
    assert_equal 'new_value', Configuration.cache[:new_config]
  end
end
