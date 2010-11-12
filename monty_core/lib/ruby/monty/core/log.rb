require 'monty/core'

module Monty
  module Core
    # Logging support.
    module Log
      # The logging object.
      # Can be a Log4r::Logger or IO object.
      attr_accessor :logger
      
      # Log level method Symbol if Log4r::Logger === logger.
      attr_accessor :log_level

      def _log msg = nil
        case 
        when Proc === @logger
          msg ||= yield
          @logger.call(msg)
        when IO === @logger
          msg ||= yield
          @logger.puts "#{self.to_s} #{msg}"
        when defined?(::Log4r) && (Log4r::Logger === @logger)
          @logger.send(@log_level || :debug) { msg ||= yield }
        when @logger.respond_to?(:_log)
          @logger._log(msg) { yield }
        when @log_level && @logger.respond_to?(@log_level)
          msg ||= yield
          @logger.send(@log_level, msg)
        end
      end

    end
  end # module
end # module
