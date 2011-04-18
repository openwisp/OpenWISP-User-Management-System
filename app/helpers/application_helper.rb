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

  def link_to_toggle_mobile(opts={})
    url = {:controller => :application, :action => :toggle_mobile_view}
    text = session[:mobile_view] ? t(:Switch_to_full_site) : t(:Switch_to_mobile_site)
    link_to text, url, opts
  end

  def mobile_link_back_to(path, opts={})
    link_to t(:Back), path, {'data-icon' => 'back', 'data-role' => 'button', 'data-direction' => 'reverse'}.merge(opts)
  end

  def mobile_link_to_logout
    form_tag account_logout_path, :method => :get, :class => 'ui-btn-right', 'data-ajax' => false do
      submit_tag t(:Logout), 'data-icon' => 'delete', :name => "", 'data-theme' => 'a'
    end
  end

  def menu_link_to(text, path, opts={})
    if current_page?(path) || opts[:disable_if]
      link_to text, "#", {:class => 'off'}.merge(opts)
    else
      link_to text, path, opts
    end
  end

  def on_root?
    current_page?(root_path) || current_page?(root_path.chop)
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

  def div_tag(opts = {}, &block)
    opts[:style] = 'display:none' if opts[:hide_if]
    content_tag(:div, opts, &block)
  end
end
