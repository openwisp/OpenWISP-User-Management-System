require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "set new configuration" do
    Configuration.set('new_configuration', 'new_value')
    assert Configuration.get('new_configuration') == 'new_value'
  end
end
