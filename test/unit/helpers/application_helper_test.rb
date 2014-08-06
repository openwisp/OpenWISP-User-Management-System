require 'test_helper'
require 'application_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "document_path" do
    assert document_path("eula.pdf").include?("/documents/eula.pdf")
    assert document_path("privacy.pdf").include?("/documents/privacy.pdf")
    
    eula_i18n = "#{Rails.public_path}/documents/#{I18n.locale}-eula.pdf"
    privacy_i18n = "#{Rails.public_path}/documents/#{I18n.locale}-privacy.pdf"
    
    File.open(eula_i18n, 'w') { |f| f.write('\n') }
    File.open(privacy_i18n, 'w') { |f| f.write('\n') }
    
    assert document_path("eula.pdf").include?("/documents/#{I18n.locale}-eula.pdf")
    assert document_path("privacy.pdf").include?("/documents/#{I18n.locale}-privacy.pdf")
    
    File.delete(eula_i18n)
    File.delete(privacy_i18n)
  end
end
