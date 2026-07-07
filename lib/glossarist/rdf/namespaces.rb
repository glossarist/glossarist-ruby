# frozen_string_literal: true

module Glossarist
  module Rdf
    module Namespaces
      autoload :DcatNamespace,       "#{__dir__}/namespaces/dcat_namespace"
      autoload :DctermsNamespace,    "#{__dir__}/namespaces/dcterms_namespace"
      autoload :FoafNamespace,       "#{__dir__}/namespaces/foaf_namespace"
      autoload :GlossaristNamespace,
               "#{__dir__}/namespaces/glossarist_namespace"
      autoload :IsoThesNamespace,    "#{__dir__}/namespaces/iso_thes_namespace"
      autoload :OwlNamespace,        "#{__dir__}/namespaces/owl_namespace"
      autoload :RdfNamespace,        "#{__dir__}/namespaces/rdf_namespace"
      autoload :ProvNamespace,       "#{__dir__}/namespaces/prov_namespace"
      autoload :SkosNamespace,       "#{__dir__}/namespaces/skos_namespace"
      autoload :SkosxlNamespace,     "#{__dir__}/namespaces/skosxl_namespace"
    end
  end
end
