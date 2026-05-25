# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class BibliographyYamlRule < Base
        def code = "GLS-020-YAML"
        def category = :structure
        def severity = "error"
        def scope = :collection

        def applicable?(context)
          context.gcr?
        end

        def check(context)
          bib_content = context.read_zip_file("bibliography.yaml")
          return [] unless bib_content

          begin
            V3::BibliographyFile.from_yaml(bib_content)
          rescue StandardError => e
            return [issue(
              "bibliography.yaml is invalid YAML: #{e.message}",
              code: code, severity: severity,
              location: "bibliography.yaml",
              suggestion: "Fix YAML syntax errors in bibliography.yaml",
            )]
          end

          []
        end
      end
    end
  end
end
