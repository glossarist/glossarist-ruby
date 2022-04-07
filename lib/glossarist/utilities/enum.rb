# frozen_string_literal: true

require_relative "enum/class_methods"
require_relative "enum/instance_methods"

module Glossarist
  module Utilities
    module Enum
      def self.included(base)
        base.include(InstanceMethods)
        base.extend(ClassMethods)
      end

      def self.extended(base)
        base.include(InstanceMethods)
        base.extend(ClassMethods)
      end
    end
  end
end
