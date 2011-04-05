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

  def link_to_locale(locale, opts={})
    html_opts = locale.to_sym == I18n.locale ? {:class => "current_#{locale}"} : {}
    link_to(image_tag("locale/#{locale}.jpg", :size => "24x24"), {:controller => :application, :action => :set_session_locale, :locale => locale}, html_opts.merge(opts))
  end

  def back_for_mobile?
    !(
        current_page?(root_path) ||
        current_page?(account_path) ||
        current_page?(:controller => :mobile_phone_password_resets, :action => :edit) ||
        current_page?(:controller => :email_password_resets, :action => :edit) ||
        current_page?(:controller => :mobile_phone_password_resets)
    )
  end

  def for_ie(opts = {:version => nil, :if => nil}, &block)
    to_include = with_output_buffer(&block)
    open_tag = "<!--[if "
    open_tag << "#{opts[:if]} " unless opts[:if].nil?
    open_tag << "IE"
    open_tag << " #{opts[:version]}" unless opts[:version].nil?
    open_tag << "]>"
    concat(open_tag+to_include+"<![endif]-->")
  end
end
