# frozen_string_literal: true

# Migrate glossarist datasets to current schema format.
#
# Usage:
#   bundle exec ruby scripts/migrate_dataset.rb SOURCE_DIR OUTPUT_DIR [--add-iev-domains]
#
# --add-iev-domains: Add domain ConceptReference objects for IEV-style identifiers
#   (e.g. "426-24-74" → area-426, section-426-24)

require "glossarist"
require "fileutils"

source_dir = ARGV[0]
output_dir = ARGV[1]
add_iev_domains = ARGV.include?("--add-iev-domains")

unless source_dir && output_dir
  abort "Usage: bundle exec ruby scripts/migrate_dataset.rb SOURCE_DIR OUTPUT_DIR [--add-iev-domains]"
end

source_dir = File.expand_path(source_dir)
output_dir = File.expand_path(output_dir)

unless File.directory?(source_dir)
  abort "Error: #{source_dir} is not a directory"
end

def add_subject_area_concepts(collection)
  areas = {}
  sections = {}

  collection.each do |concept|
    next unless concept.data.domains

    concept.data.domains.each do |ref|
      next unless ref.is_a?(Glossarist::ConceptReference) && ref.concept_id

      id = ref.concept_id
      if id.start_with?("area-")
        areas[id] = true
      elsif id.start_with?("section-")
        sections[id] = true
      end
    end
  end

  existing_ids = collection.to_set { |c| c.data.id }

  areas.each_key do |area_id|
    next if existing_ids.include?(area_id)

    mc = Glossarist::ManagedConcept.new(
      data: Glossarist::ManagedConceptData.new(
        id: area_id,
        domains: [Glossarist::ConceptReference.domain(area_id)],
      ),
    )

    code = area_id.sub("area-", "")
    narrower = sections.keys.select { |s| s.start_with?("section-#{code}-") }
    mc.related = narrower.map { |s| Glossarist::RelatedConcept.new(type: "narrower", content: s) }

    l10n = build_domain_localization(area_id, code, "eng")
    mc.add_l10n(l10n)

    collection.store(mc)
  end

  sections.each_key do |section_id|
    next if existing_ids.include?(section_id)

    parts = section_id.sub("section-", "").split("-")
    area_id = "area-#{parts[0]}"

    mc = Glossarist::ManagedConcept.new(
      data: Glossarist::ManagedConceptData.new(
        id: section_id,
        domains: [
          Glossarist::ConceptReference.domain(area_id),
          Glossarist::ConceptReference.domain(section_id),
        ],
      ),
    )

    mc.related = [Glossarist::RelatedConcept.new(type: "broader",
                                                 content: area_id)]

    section_code = parts.length > 1 ? parts[0..1].join("-") : parts[0]
    l10n = build_domain_localization(section_id, section_code, "eng")
    l10n.data.domain = area_id
    mc.add_l10n(l10n)

    collection.store(mc)
  end
end

def build_domain_localization(id, _label, lang_code)
  cd = Glossarist::ConceptData.new(
    id: id,
    language_code: lang_code,
    terms: [
      Glossarist::Designation::Expression.new(
        type: "expression",
        designation: id,
        normative_status: "preferred",
      ),
    ],
  )

  l10n = Glossarist::LocalizedConcept.new
  l10n.data = cd
  l10n.entry_status = "valid"
  l10n
end

# Detect format: managed (concept/ + localized_concept/) vs grouped (*.yaml)
concept_subdir = File.join(source_dir, "concept")
is_managed_format = File.directory?(concept_subdir)

puts "Loading concepts from #{source_dir} (#{is_managed_format ? 'managed' : 'grouped'} format)..."

collection = Glossarist::ManagedConceptCollection.new
collection.load_from_files(source_dir)

puts "Loaded #{collection.count} concepts"

# Add IEV domain references if requested
if add_iev_domains
  puts "Adding IEV domain references..."

  collection.each do |concept|
    next if concept.data.domains && !concept.data.domains.empty?

    identifier = concept.data.id.to_s
    next if identifier.empty? || identifier.start_with?("area-", "section-")

    parts = identifier.split("-")
    next unless parts.length >= 2

    area_uri = "area-#{parts[0]}"
    section_uri = "section-#{parts[0]}-#{parts[1]}"

    concept.data.domains = [
      Glossarist::ConceptReference.domain(area_uri),
      Glossarist::ConceptReference.domain(section_uri),
    ]
  end

  puts "Adding subject area hierarchy concepts..."
  add_subject_area_concepts(collection)

  puts "Domains added. Total concepts: #{collection.count}"
end

# Save output
puts "Saving to #{output_dir}..."

if is_managed_format
  concepts_out = File.join(output_dir, "concepts")
  FileUtils.mkdir_p(concepts_out)
  collection.save_to_files(concepts_out)
else
  concepts_out = File.join(output_dir)
  FileUtils.mkdir_p(concepts_out)
  collection.save_grouped_concepts_to_files(concepts_out)
end

# Copy register.yaml if present
register_src = File.join(File.dirname(source_dir), "register.yaml")
if File.exist?(register_src) && !File.exist?(File.join(output_dir, "..",
                                                       "register.yaml"))
  is_managed_format ? File.dirname(output_dir) : output_dir
  register_dst = if File.exist?(File.join(File.dirname(source_dir),
                                          "register.yaml"))
                   File.join(
                     is_managed_format ? File.dirname(output_dir) : File.dirname(output_dir), "register.yaml"
                   )
                 end
  if register_dst
    FileUtils.mkdir_p(File.dirname(register_dst))
    FileUtils.cp(register_src, register_dst) unless register_src == register_dst
  end
end

puts "Done. #{collection.count} concepts migrated."
