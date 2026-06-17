# frozen_string_literal: true

module Glossarist
  module Collections
    class FormulaCollection < NonVerbalCollection
      instances :entries, Formula

      key_value { map_instances to: :entries }

      def self.from_directory(dir)
        collection = new
        Dir.glob(File.join(dir, "*.yaml")).each do |path|
          fml = Formula.from_file(path)
          collection.store(fml) if fml
        end
        collection
      end
    end
  end
end
