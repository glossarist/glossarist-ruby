module Glossarist
  module Designation
    class Symbol < Base
      attribute :international, :boolean
      attribute :type, :string, default: -> { "symbol" }

      yaml do
        map :international, to: :international
        map :type, to: :type, render_default: true
      end

      def self.of_yaml(hash, options = {})
        hash["type"] = "symbol" unless hash["type"]

        super
      end
    end
  end
end
