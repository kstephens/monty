module Monty
  module Core
    class Content
      include Monty::Core::Options

      attr_accessor :name, :data

      module Behavior
      end
    end
  end
end
