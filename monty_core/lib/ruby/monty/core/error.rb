require 'monty/core'

module Monty
  module Core
    # Logging support.
    class Error < ::Exception
      # The original error.
      attr_accessor :original_error
    end
  end # module
end # module
