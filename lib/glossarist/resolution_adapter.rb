# frozen_string_literal: true

module Glossarist
  class ResolutionAdapter
    autoload :Local, "glossarist/resolution_adapter/local"
    autoload :Package, "glossarist/resolution_adapter/package"
    autoload :Route, "glossarist/resolution_adapter/route"
    autoload :Remote, "glossarist/resolution_adapter/remote"

    def resolve(_reference)
      raise NotImplementedError, "#{self.class}#resolve must be implemented"
    end
  end
end
