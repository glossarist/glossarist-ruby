# frozen_string_literal: true

module Glossarist
  module Rdf
    module Namespaces
      autoload :SkosNamespace, "#{__dir__}/namespaces/skos_namespace"
      autoload :DctermsNamespace, "#{__dir__}/namespaces/dcterms_namespace"
    end
  end
end
