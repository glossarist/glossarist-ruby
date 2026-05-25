#!/usr/bin/env ruby
# frozen_string_literal: true

# Migration script for isotc204-glossary: adds v3 fields to existing concepts.
#
# Adds:
#   - status: "valid" at managed concept level
#   - date_accepted at managed concept level
#   - domains (section ConceptReference) at managed concept data level
#   - related (broader to section) at managed concept level
#   - Creates section hierarchy concepts with narrower relations
#
# Usage:
#   cd /Users/mulgogi/src/glossarist/glossarist-ruby
#   bundle exec ruby scripts/migrate_isotc204_to_v3.rb
#
# Safe to run multiple times (idempotent).

require "glossarist"

DIR = "/Users/mulgogi/src/geolexica/isotc204-glossary/concepts"

ISO_TS_14812_SECTIONS = {
  "3.1" => "General concepts",
  "3.2" => "Transport information and control",
  "3.3" => "ITS station",
  "3.4" => "Communications",
  "3.5" => "ITS services",
  "3.6" => "Geospatial",
  "3.7" => "Driving automation",
}.freeze

ISO_TS_14812_DATE = "2022-01-01T00:00:00+00:00"
ISO_TS_14812_SOURCE = "urn:iso:std:iso:ts:14812"

collection = Glossarist::ManagedConceptCollection.new
collection.load_from_files(DIR)

puts "Loaded #{collection.count} concepts"

# Track which concepts belong to which section for narrower relations
section_children = Hash.new { |h, k| h[k] = [] }

collection.each do |concept|
  identifier = concept.data.id.to_s
  section_code = identifier.split(".")[0..1].join(".")
  section_uri = "section-#{section_code.gsub('.', '-')}"
  section_children[section_uri] << identifier

  # Set status
  concept.status = "valid" unless concept.status

  # Set date_accepted
  unless concept.date_accepted
    concept.date_accepted = Glossarist::ConceptDate.new(
      type: "accepted",
      date: ISO_TS_14812_DATE,
    )
  end

  # Add domain ConceptReference
  concept.data.domains ||= []
  unless concept.data.domains.any? { |d| d.concept_id == section_uri }
    concept.data.domains << Glossarist::ConceptReference.new(
      concept_id: section_uri,
      source: ISO_TS_14812_SOURCE,
      ref_type: "domain",
    )
  end

  # Add broader relation to section
  concept.related ||= []
  unless concept.related.any? { |r| r.type == "broader" && r.ref&.id == section_uri }
    concept.related << Glossarist::RelatedConcept.new(
      type: "broader",
      content: section_uri,
      ref: Glossarist::Citation.new(source: "ISO/TS 14812", id: section_uri),
    )
  end
end

puts "Updated #{collection.count} concepts with status, date_accepted, domains, related"

# Create section hierarchy concepts
ISO_TS_14812_SECTIONS.each do |code, title|
  section_uri = "section-#{code.gsub('.', '-')}"

  mc = Glossarist::ManagedConcept.new(
    data: Glossarist::ManagedConceptData.new(
      id: section_uri,
      domains: [Glossarist::ConceptReference.new(
        concept_id: section_uri,
        source: ISO_TS_14812_SOURCE,
        ref_type: "domain",
      )],
    ),
  )
  mc.status = "valid"
  mc.date_accepted = Glossarist::ConceptDate.new(
    type: "accepted",
    date: ISO_TS_14812_DATE,
  )

  l10n = Glossarist::LocalizedConcept.new
  l10n.data = Glossarist::ConceptData.new(
    id: section_uri,
    language_code: "eng",
    terms: [Glossarist::Designation::Expression.new(
      type: "expression",
      designation: title,
      normative_status: "preferred",
    )],
  )
  l10n.entry_status = "valid"
  mc.add_l10n(l10n)

  # Add narrower relations to child concepts
  children = section_children[section_uri]
  if children.any?
    mc.related = children.sort.map do |child_id|
      Glossarist::RelatedConcept.new(
        type: "narrower",
        content: child_id,
        ref: Glossarist::Citation.new(source: "ISO/TS 14812", id: child_id),
      )
    end
  end

  collection.store(mc)
  puts "Created section concept: #{section_uri} (#{title}) — #{children.length} narrower"
end

collection.save_grouped_concepts_to_files(DIR)
puts "Saved #{collection.count} concepts to #{DIR}"
