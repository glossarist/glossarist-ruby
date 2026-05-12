# frozen_string_literal: true

require_relative "rules/base"
require_relative "rules/registry"
require_relative "rules/dataset_context"
require_relative "rules/gcr_context"
require_relative "rules/concept_context"

# Load all rule definitions
require_relative "rules/concept_id_rule"
require_relative "rules/concept_id_uniqueness_rule"
require_relative "rules/localization_presence_rule"
require_relative "rules/entry_status_rule"
require_relative "rules/asciidoc_xref_rule"
require_relative "rules/image_reference_rule"
require_relative "rules/concept_mention_rule"
require_relative "rules/concept_count_rule"
require_relative "rules/language_list_rule"
require_relative "rules/language_coverage_rule"
require_relative "rules/filename_id_rule"
require_relative "rules/l10n_uuid_integrity_rule"
require_relative "rules/orphaned_l10n_files_rule"
require_relative "rules/orphaned_bibliography_rule"
require_relative "rules/orphaned_images_rule"
require_relative "rules/definition_content_rule"
require_relative "rules/preferred_term_rule"
require_relative "rules/duplicate_term_rule"
require_relative "rules/citation_completeness_rule"
require_relative "rules/authoritative_source_rule"
require_relative "rules/related_concept_rule"
require_relative "rules/concept_status_rule"
require_relative "rules/source_type_rule"
require_relative "rules/terms_presence_rule"
require_relative "rules/bibliography_yaml_rule"
require_relative "rules/concept_uri_rule"
require_relative "rules/related_concept_symmetry_rule"
require_relative "rules/related_concept_cycle_rule"
require_relative "rules/designation_status_rule"
require_relative "rules/date_type_rule"
require_relative "rules/language_code_format_rule"
require_relative "rules/designation_type_rule"
require_relative "rules/date_validity_rule"

# Register all built-in rules
module Glossarist
  module Validation
    module Rules
      R = Registry

      R.register(ConceptIdRule)
      R.register(ConceptIdUniquenessRule)
      R.register(LocalizationPresenceRule)
      R.register(EntryStatusRule)
      R.register(AsciidocXrefRule)
      R.register(ImageReferenceRule)
      R.register(ConceptMentionRule)
      R.register(ConceptCountRule)
      R.register(LanguageListRule)
      R.register(LanguageCoverageRule)
      R.register(FilenameIdRule)
      R.register(L10nUuidIntegrityRule)
      R.register(OrphanedL10nFilesRule)
      R.register(OrphanedBibliographyRule)
      R.register(OrphanedImagesRule)
      R.register(DefinitionContentRule)
      R.register(PreferredTermRule)
      R.register(DuplicateTermRule)
      R.register(CitationCompletenessRule)
      R.register(AuthoritativeSourceRule)
      R.register(RelatedConceptRule)
      R.register(ConceptStatusRule)
      R.register(SourceEnumRule)
      R.register(TermsPresenceRule)
      R.register(BibliographyYamlRule)
      R.register(ConceptUriRule)
      R.register(RelatedConceptSymmetryRule)
      R.register(RelatedConceptCycleRule)
      R.register(DesignationStatusRule)
      R.register(DateTypeRule)
      R.register(LanguageCodeFormatRule)
      R.register(DesignationTypeRule)
      R.register(DateValidityRule)
    end
  end
end
