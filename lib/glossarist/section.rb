# frozen_string_literal: true

module Glossarist
  class Section < Lutaml::Model::Serializable
    attribute :id, :string
    attribute :names, :hash
    attribute :ordering, :string
    attribute :children, Section, collection: true

    key_value do
      map :id, to: :id
      map :names, to: :names
      map :ordering, to: :ordering
      map :children, to: :children
    end

    def name(lang = nil)
      return names&.dig("eng") if lang.nil?

      names&.dig(lang) || names&.dig("eng")
    end

    def descendant_by_id(target_id)
      children&.each do |child|
        return child if child.id == target_id

        found = child.descendant_by_id(target_id)
        return found if found
      end
      nil
    end

    def self.from_file(path)
      return nil unless File.exist?(path)

      from_yaml(File.read(path, encoding: "utf-8"))
    end
  end
end
