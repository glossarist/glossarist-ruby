# frozen_string_literal: true

require "singleton"

module Glossarist
  class Config
    include Singleton

    DEFAULT_CLASSES = {
      localized_concept: Glossarist::LocalizedConcept,
      concet_set: Glossarist::ConceptSet,
    }.freeze

    attr_reader :registered_classes

    def initialize
      @registered_classes = DEFAULT_CLASSES.dup
    end

    def class_for(name)
      @registered_classes[name.to_sym]
    end

    def register_class(class_name, klass)
      @registered_classes[class_name] = klass
    end

    class << self
      def class_for(name)
        self.instance.class_for(name)
      end

      def register_class(class_name, klass)
        self.instance.register_class(class_name, klass)
      end
    end
  end
end
