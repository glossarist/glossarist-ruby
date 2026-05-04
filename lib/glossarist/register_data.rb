# frozen_string_literal: true

module Glossarist
  class RegisterData < Lutaml::Model::Serializable
    attribute :data, :hash, default: -> { {} }

    key_value do
      map nil, to: :data, with: { from: :data_from, to: :data_to }
    end

    def self.from_file(path)
      from_yaml(File.read(path))
    rescue Errno::ENOENT
      nil
    end

    def [](key)
      data[key]
    end

    def dig(*keys)
      data.dig(*keys)
    end

    def to_h
      data
    end

    def data_from(model, value)
      model.data = value
    end

    def data_to(model, doc)
      model.data.each do |key, value|
        doc[key] = value
      end
    end
  end
end
