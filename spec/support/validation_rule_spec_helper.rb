# frozen_string_literal: true

# Helper for validation rule specs: builds real ConceptContext / DatasetContext
# instances from minimal input, so specs construct actual model objects instead
# of doubles (per the global "no doubles" rule).
module ValidationRuleSpecHelper
  def make_managed_concept(id:, status: nil, dates: [], sources: [], langs: {})
    mc = Glossarist::ManagedConcept.new(data: { "id" => id })
    mc.status = status if status
    mc.dates = dates if dates.any?
    mc.sources = sources if sources.any?
    langs.each do |lang, opts|
      mc.add_localization(build_localization(lang, opts))
    end
    mc
  end

  def build_localization(lang, opts = {})
    terms = opts[:terms] || [{
      "type" => "expression",
      "designation" => opts[:designation] || "test term",
      "normative_status" => opts[:normative_status] || "preferred",
    }]
    data = {
      "language_code" => lang.to_s,
      "terms" => terms,
      "definition" => opts[:definition] || [{ "content" => "a definition" }],
      "entry_status" => opts[:entry_status] || "valid",
    }
    data["sources"] = opts[:sources] if opts[:sources]
    data["notes"] = opts[:notes] if opts[:notes]
    data["examples"] = opts[:examples] if opts[:examples]
    data["annotations"] = opts[:annotations] if opts[:annotations]
    data["non_verb_rep"] = opts[:non_verb_rep] if opts[:non_verb_rep]
    Glossarist::LocalizedConcept.of_yaml({ "data" => data })
  end

  # Real DatasetContext backed by a tmpdir. Caller can add_concept before
  # creating a ConceptContext.
  def make_dataset_context(tmpdir)
    Glossarist::Validation::Rules::DatasetContext.new(tmpdir)
  end

  def make_concept_context(concept, collection_context:, file_name: nil)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept,
      file_name: file_name || "concept-#{concept.data&.id}.yaml",
      collection_context: collection_context,
    )
  end

  # Build a minimal .gcr ZIP archive in tmpdir containing the named files.
  # files is a hash of { "path/in/zip" => "content" }.
  # Returns the path to the created zip.
  def make_gcr_zip(tmpdir, files:, name: "test.gcr")
    require "zip"
    zip_path = File.join(tmpdir, name)
    Zip::File.open(zip_path, create: true) do |zf|
      files.each do |path, content|
        zf.get_output_stream(path) { |f| f.write(content) }
      end
    end
    zip_path
  end

  def make_gcr_context(zip_path)
    Glossarist::Validation::Rules::GcrContext.new(zip_path)
  end
end

RSpec.configure do |config|
  config.include ValidationRuleSpecHelper
end
