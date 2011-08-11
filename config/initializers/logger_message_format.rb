ActiveSupport::BufferedLogger.class_eval do
  def add(severity, message = nil, progname = nil, &block)
    return if @level > severity
    message = (message || (block && block.call) || progname).to_s
    severity_string = self.class.constants.select{ |c| 
      self.class.const_get(c) == severity
    }.first

    # If a newline is necessary then create a new message ending with a newline.
    # Ensures that the original message is not mutated.
    message = "[#{severity_string} @ #{Time.now.to_s(:db)}] #{message}"
    message << "\n" unless message[-1] == ?\n
    buffer << message
    auto_flush
    message
  end
end

