module UsersHelper

  def sort_td_class_helper(param)
    case params[:sort]
      when param          then result = 'class="sortup"'
      when param + "_rev" then result = 'class="sortdown"'
      else result = 'class="nosort"'
    end
    result
  end
  
  def sort_remote_link_helper(text, field, remotes = {})
    key = field
    key += "_rev" if params[:sort] == field
    options = {
        :url => { :action => remotes[:action], :params => params.merge({ 'action' => remotes[:action], :sort => key, :page => nil, :search => remotes[:search] }) },
        :update => remotes[:update],
        :before => remotes[:before],
        :success => remotes[:success]
    }
    html_options = {
      :title => t(:Sort_by_this_field),
      :href => '#'
    }

    link_to_remote(text, options, html_options)
  end


  def pagination_remote_links(paginator, remotes = {})
    page_options = {:window_size => 1}
    pagination_links_each(paginator, page_options) do |n|
      options = {
        :url => { :action => remotes[:action], :params => { 'action' => remotes[:action], :sort => key, :page => nil, :search => remotes[:search] }, :page => n },
        :update => remotes[:update],
        :before => remotes[:before],
        :success => remotes[:success]
      }
      html_options = { :href => "#" }
      link_to_remote(n.to_s, options, html_options)
    end
  end

  def user_verification_methods
    User::VERIFICATION_METHODS
  end

  def user_verification_select
    user_verification_methods.map{ |method| [ t(method.to_sym), method ] }
  end

end
