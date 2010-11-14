require 'monty'

module Monty
  # Core module for Monty.
  #
  # Namespace for core classes and XSLT generation.
  module Core

    @@load_libxml = nil
    def self.load_libxml!
      unless @@load_libxml 
        gem 'libxml-ruby'
        require 'xml'
        @@load_libxml = true
      end
    end

    @@load_libxslt = nil
    def self.load_libxslt!
      unless @@load_libxslt
        load_libxml!
        gem 'libxslt-ruby'
        require 'xslt'
        @@load_libxslt = true
      end
    end
  end
end

require 'monty/core/error'
require 'monty/core/options'
require 'monty/core/config'
require 'monty/core/log'
require 'monty/core/uri_pattern'
require 'monty/core/experiment'
require 'monty/core/experiment_group'
require 'monty/core/experiment_set'
require 'monty/core/possibility'
require 'monty/core/rule'
require 'monty/core/rule_selection'
require 'monty/core/content'
require 'monty/core/input'
require 'monty/core/x_path'
require 'monty/core/sgml_entity'
require 'monty/core/xslt'
require 'monty/core/xslt_generator'
require 'monty/core/xsl_processor'
require 'monty/core/entropy_stream'

