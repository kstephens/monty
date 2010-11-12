require 'monty/core'

module Monty
module Core
  # Support for configuring object instances via a callback Proc.
  #
  #   class Foo
  #     include Monty::Core::Config
  #     attr_accessor :foo, :bar
  #   end
  #   Foo.configure do | f |
  #     f.bar = 10
  #   end
  #   f = Foo.new(:baz => 2, :x => 4)
  #   f[:x] => 4
  #   f.bar => 10
  #   f.baz => 2
  #
  module Config
    def self.module_config_procs
      @module_config_procs ||= { }
    end

    def self.included target
      super
      target.extend(ModuleMethods)
      if (Class === target && ! target.superclass.ancestors.include?(self))
        target.class_eval do 
          alias :initialize_without_config :initialize unless method_defined?(:initialize_without_config)
          alias :initialize :initialize_with_config
        end
      end
    end

    # Calls initialize_before_opts, set_opts!, then initialize_after_opts.
    # Subclass is not required to override.
    def initialize_with_config *args
      initialize_without_config *args
      configure!
    end
    
    def configure!
      unless @_configured
        @_configured = true
        self.class.ancestors.reverse.each do | cls |
          if proc = Monty::Core::Config.module_config_procs[cls.name]
            proc.call(self)
          end
        end
      end
      self
    end

    module ModuleMethods
      def configure proc = nil, &blk
        proc = blk if block_given?
        Monty::Core::Config.module_config_procs[self.name] = proc
      end
      alias :configure= :configure
      alias :configure_proc= :configure

      def configure_proc
        Monty::Core::Config.module_config_procs[self.name]
      end
    end

  end # module
end # module
end # module

