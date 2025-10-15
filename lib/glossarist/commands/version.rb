module Glossarist
  module Commands
    class Version < Base
      def run
        say Glossarist::VERSION
      end
    end
  end
end
