# frozen_string_literal: true

module Glossarist
  class CollectionConfig < Lutaml::Model::Serializable
    attribute :packages, :hash, collection: true, default: -> { [] }
    attribute :routes, :hash, collection: true, default: -> { [] }
    attribute :remotes, :hash, collection: true, default: -> { [] }

    yaml do
      map :packages, to: :packages
      map :routes, to: :routes
      map :remote, to: :remotes
    end

    def self.from_file(path)
      return nil unless File.exist?(path)

      from_yaml(File.read(path))
    rescue Psych::SyntaxError, Lutaml::Model::InvalidFormatError
      nil
    end
  end
end
