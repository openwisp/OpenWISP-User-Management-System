# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module ApplicationHelper
  def j(javascript)
    escape_javascript(raw(javascript))
  end

  def t_safe(*args)
    translate(*args).html_safe
  end

  def document_path(source)
    i18n_source = "#{I18n.locale}-#{source}"
    
    # support internationalized documents
    if Pathname.new("#{Rails.public_path}/documents/#{i18n_source}").exist?
      source = i18n_source
    end
    
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
    destination = on_root? ? root_path(:locale => locale) : {:locale => locale}
    html_opts = locale.to_sym == I18n.locale ? {:class => "current_#{locale}"} : {}
    link_to(image_tag("locale/#{locale}.jpg", :size => "24x24"), destination, html_opts.merge(opts))
  end

  def link_to_toggle_mobile(opts={})
    text = session[:mobile_view] ? t(:Switch_to_full_site) : t(:Switch_to_mobile_site)
    link_to text, toggle_mobile_url, opts
  end

  def mobile_link_back_to(path, opts={})
    link_to t(:Back), path, {'data-icon' => 'back', 'data-role' => 'button', 'data-direction' => 'reverse'}.merge(opts)
  end

  def mobile_link_to_logout
    form_tag account_logout_path, :method => :delete, :class => 'ui-btn-right' do
      submit_tag t(:Logout), 'data-icon' => 'delete', :name => "", 'data-theme' => 'a'
    end
  end

  def menu_link_to(text, path, opts={})
    if opts.delete(:disable_if) || current_page?(path)
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
    raw(open_tag+to_include+"<![endif]-->")
  end

  def div_tag(opts = {}, &block)
    opts[:style] = 'display:none' if opts[:hide_if]
    content_tag(:div, opts, &block)
  end

  def document_of(owner, opts={})
    inline = opts[:inline]
    link   = opts[:link]

    if inline
      embedded_image_tag(owner.operate {|img| img.resize 100 }).html_safe
    else
      big = {:action => 'show', :format => :jpg}
      big.merge!(:id => owner.id) if owner.is_a?(User)
      thumb = big.merge({:size => 'thumb'})

      if link
        link_to image_tag(url_for(thumb)), url_for(big), :target => '_blank'
      else
        image_tag(url_for(thumb))
      end
    end
  end

  def subject_radius_check_url(subject, check)
    subject.is_a?(User) ? user_radius_check_url(subject, check) : radius_group_radius_check_url(subject, check)
  end

  def edit_subject_radius_check_url(subject, check)
    subject.is_a?(User) ? edit_user_radius_check_url(subject, check) : edit_radius_group_radius_check_url(subject, check)
  end

  def new_subject_radius_check_url(subject)
    subject.is_a?(User) ? new_user_radius_check_url(subject) : new_radius_group_radius_check_url(subject)
  end

  def subject_radius_reply_url(subject, reply)
    subject.is_a?(User) ? user_radius_reply_url(subject, reply) : radius_group_radius_reply_url(subject, reply)
  end

  def edit_subject_radius_reply_url(subject, reply)
    subject.is_a?(User) ? edit_user_radius_reply_url(subject, reply) : edit_radius_group_radius_reply_url(subject, reply)
  end

  def new_subject_radius_reply_url(subject)
    subject.is_a?(User) ? new_user_radius_reply_url(subject) : new_radius_group_radius_reply_url(subject)
  end

  def number_to_currency_custom(number, options = {})
    currency_code = Configuration.get('gestpay_currency')
    
    dictionary = {
      '242' => '&euro;',
      '1' => '$',
      '2' => '&pound;',
      '71' => '&yen;'
    }
    unless dictionary[currency_code].nil?
      options[:unit] = dictionary[currency_code]
    else
      raise(Exception, 'Unkown currency code')
    end
    number_to_currency(number, options)
  end
  
  def with_format(format, &block)
    old_formats = formats
    self.formats = [format]
    block.call
    self.formats = old_formats
    nil
  end
  
  def authenticated?
    current_account or @current_operator
  end
  
  def link_to_user_or_operator
    if current_account
      link_to(current_account.username, account_url)
    elsif @current_operator
      link_to(@current_operator.login, root_url)
    end
  end
end