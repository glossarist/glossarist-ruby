# frozen_string_literal: true

require "singleton"

module Glossarist
  class Config
    include Singleton

    DEFAULT_CLASSES = {
      localized_concept: Glossarist::LocalizedConcept,
      managed_concept: Glossarist::ManagedConcept,
    }.freeze

    attr_reader :registered_classes

    def initialize
      if File.exist?("glossarist.yaml")
        @config = YAML.load_file("glossarist.yaml")
      end

      @config ||= {}

      @registered_classes = DEFAULT_CLASSES.dup
      @extension_attributes = @config["extension_attributes"] || []
    end

    def class_for(name)
      @registered_classes[name.to_sym]
    end

    def register_class(class_name, klass)
      @registered_classes[class_name.to_sym] = klass
    end

    def extension_attributes
      @extension_attributes
    end

    def register_extension_attributes(attributes)
      @extension_attributes = attributes
    end

    class << self
      def class_for(name)
        instance.class_for(name)
      end

      def extension_attributes
        instance.extension_attributes
      end

      def register_class(class_name, klass)
        instance.register_class(class_name, klass)
      end

      def register_extension_attributes(attributes)
        instance.register_extension_attributes(attributes)
      end
    end
  end
end
