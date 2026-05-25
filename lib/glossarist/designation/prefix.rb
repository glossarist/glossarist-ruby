module Glossarist
  module Designation
    class Prefix < Base
      attribute :type, :string, default: -> { "prefix" }

      key_value do
        map :type, to: :type, render_default: true
      end

      def self.of_yaml(hash, options = {})
        hash["type"] = "prefix" unless hash["type"]

        super
      end
    end
  end
end
