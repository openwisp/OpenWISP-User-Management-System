class ErrorFormBuilder < ActionView::Helpers::FormBuilder
  #Adds error message directly inline to a form label
  #Accepts all the options normall passed to form.label as well as:
  #  :hide_errors - true if you don't want errors displayed on this label
  #  :additional_text - Will add additional text after the error message or after the label if no errors
  def label(method, text = nil, options = {})
    #Check to see if text for this label has been supplied and humanize the field name if not.
    text = text.nil? ? self.object.class.human_attribute_name(method) : text
    #Get a reference to the model object
    object = @template.instance_variable_get("@#{@object_name}")

    #Make sure we have an object and we're not told to hide errors for this label
    unless object.nil? || options[:hide_errors]
      #Check if there are any errors for this field in the model
      errors = object.errors.on(method.to_sym)
      if errors
        #Generate the label using the text as well as the error message wrapped in a span with error class
        text += " <span class=\"error\">#{errors.is_a?(Array) ? errors.first : errors}</span>"
      end
    end
    #Add any additional text that might be needed on the label
    text += " #{options[:additional_text]}" if options[:additional_text]
    #Finally hand off to super to deal with the display of the label
    super(method, text, options)
  end
end