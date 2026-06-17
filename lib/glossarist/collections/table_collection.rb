# frozen_string_literal: true

module Glossarist
  module Collections
    class TableCollection < NonVerbalCollection
      instances :entries, Table

      key_value { map_instances to: :entries }

      def self.from_directory(dir)
        collection = new
        Dir.glob(File.join(dir, "*.yaml")).each do |path|
          tbl = Table.from_file(path)
          collection.store(tbl) if tbl
        end
        collection
      end
    end
  end
end
