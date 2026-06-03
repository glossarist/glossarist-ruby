#!/usr/bin/env ruby
# frozen_string_literal: true

# Migration script for osgeo-glossary: adds v3 fields to existing concepts.
#
# Adds:
#   - status: "valid" at managed concept level
#   - date_accepted at managed concept level (set to 2011-01-01 as earliest
#     known publication date for the OSGeo Lexicon)
#   - domains for concepts with identifiable ISO standard sources
#   - related (broader to domain) for those concepts
#   - Creates domain concepts for identified ISO standards
#
# Idempotent: safe to run multiple times.
#
# Usage:
#   cd /Users/mulgogi/src/glossarist/glossarist-ruby
#   bundle exec ruby scripts/migrate_osgeo_to_v3.rb

require "glossarist"

DIR = "/Users/mulgogi/src/geolexica/osgeo-glossary/concepts"

OSGEO_DATE = "2011-01-01T00:00:00+00:00"

# Extract a stable domain ID from an authoritative source reference string.
def extract_domain_id(ref_text)
  return nil unless ref_text

  patterns = [
    %r{ISO/IEC/IEEE\s+([\d-]+)},
    %r{ISO/IEC\s+([\d-]+)},
    %r{ISO/TS\s+([\d-]+)},
    %r{ISO/TR\s+([\d-]+)},
    %r{ISO\s+(\d+-?\d*)},
  ]

  patterns.each do |pat|
    if (m = ref_text.match(pat))
      return "iso-#{m[1]}"
    end
  end

  nil
end

collection = Glossarist::ManagedConceptCollection.new
collection.load_from_files(DIR)

puts "Loaded #{collection.count} concepts"

domain_index = {}
concepts_with_domain = 0

collection.each do |concept|
  # Set status
  concept.status = "valid" unless concept.status

  # Set date_accepted
  unless concept.date_accepted
    concept.date_accepted = Glossarist::ConceptDate.new(
      type: "accepted",
      date: OSGEO_DATE,
    )
  end

  # Extract domain from source
  eng = concept.localization("eng")
  next unless eng

  sources = eng.data&.sources
  next unless sources

  auth = sources.find { |s| s.type == "authoritative" }
  next unless auth&.origin

  ref_text = auth.origin.text || auth.origin.ref
  next unless ref_text

  domain_id = extract_domain_id(ref_text)
  next unless domain_id

  (domain_index[domain_id] ||= []) << concept.data.id
  concepts_with_domain += 1

  # Add domain ConceptReference
  concept.data.domains ||= []
  unless concept.data.domains.any? { |d| d.concept_id == domain_id }
    concept.data.domains << Glossarist::ConceptReference.new(
      concept_id: domain_id,
      source: "urn:iso:std:iso",
      ref_type: "domain",
    )
  end

  # Add broader relation to domain concept
  concept.related ||= []
  unless concept.related.any? do |r|
    r.type == "broader" && r.ref&.id == domain_id
  end
    concept.related << Glossarist::RelatedConcept.new(
      type: "broader",
      content: domain_id,
      ref: Glossarist::Citation.new(source: "ISO", id: domain_id),
    )
  end
end

puts "Added status and date_accepted to #{collection.count} concepts"
puts "Added domains to #{concepts_with_domain} concepts with ISO sources"

# Create domain hierarchy concepts
domain_index.sort.each do |domain_id, child_ids|
  mc = Glossarist::ManagedConcept.new(
    data: Glossarist::ManagedConceptData.new(
      id: domain_id,
      domains: [Glossarist::ConceptReference.new(
        concept_id: domain_id,
        source: "urn:iso:std:iso",
        ref_type: "domain",
      )],
    ),
  )
  mc.status = "valid"
  mc.date_accepted = Glossarist::ConceptDate.new(
    type: "accepted",
    date: OSGEO_DATE,
  )

  l10n = Glossarist::LocalizedConcept.new
  l10n.data = Glossarist::ConceptData.new(
    id: domain_id,
    language_code: "eng",
    terms: [Glossarist::Designation::Expression.new(
      type: "expression",
      designation: domain_id,
      normative_status: "preferred",
    )],
  )
  l10n.entry_status = "valid"
  mc.add_l10n(l10n)

  narrower = child_ids.sort.map do |child_id|
    Glossarist::RelatedConcept.new(
      type: "narrower",
      content: child_id.to_s,
      ref: Glossarist::Citation.new(source: "OSGeo", id: child_id.to_s),
    )
  end
  mc.related = narrower

  collection.store(mc)
  puts "Created domain: #{domain_id} — #{child_ids.size} narrower"
end

collection.save_grouped_concepts_to_files(DIR)
puts "Saved #{collection.count} concepts to #{DIR}"
