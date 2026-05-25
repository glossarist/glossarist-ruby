module Glossarist
  module Designation
    class Suffix < Base
      attribute :type, :string, default: -> { "suffix" }

      key_value do
        map :type, to: :type, render_default: true
      end

      def self.of_yaml(hash, options = {})
        hash["type"] = "suffix" unless hash["type"]

        super
      end
    end
  end
end
