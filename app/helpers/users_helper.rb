module UsersHelper
  def sort_td_class_helper(param)
    result = case params[:sort]
               when param          then 'sortup'
               when param + "_rev" then 'sortdown'
               else 'nosort'
             end

    raw "class=\"#{result}\""
  end

  def sort_remote_link_helper(text, field)
    key = field
    key += "_rev" if params[:sort] == field

    raw link_to(text, params.merge(:sort => key, :page => nil), :remote => true, :title => t(:Sort_by_this_field))
  end


  def user_verification_methods
    User::VERIFICATION_METHODS
  end

  def user_verification_select
    user_verification_methods.map{ |method| [ t(method.to_sym), method ] }
  end
end
