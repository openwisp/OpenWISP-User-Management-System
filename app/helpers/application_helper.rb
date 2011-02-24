# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def document_path(source)
    compute_public_path(source, 'documents')
  end

  def bytes_to_human(bytes)
    bytes = bytes.to_i
    bytes > 1024 ? bytes > 1048576 ? bytes > 1073741824 ? bytes > 1099511627776 ? (bytes / 1099511627776).to_s + " TBytes" : (bytes / 1073741824).to_s + " GBytes" : (bytes / 1048576).to_s + " MBytes" : (bytes / 1024).to_s + " KBytes" : (bytes).to_s + " Bytes"
  end

  def is_touchscreen_device?
    is_device?('iphone') || is_device?('ipod') || is_device?('ipad') || is_device?('android')
  end

  def is_apple_device?
    is_device?('iphone') || is_device?('ipod') || is_device?('ipad')
  end
  
  def auth?(role, object=nil)
    current_operator && current_operator.has_role?(role, object)
  end
  
end
