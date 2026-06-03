#!/usr/bin/env ruby
# frozen_string_literal: true

# Migration script for isotc211-glossary: adds v3 fields to existing concepts.
#
# Adds:
#   - domains (ISO standard ConceptReference) at managed concept data level
#   - related (broader to standard domain) at managed concept level
#   - Creates domain concepts per ISO standard (with narrower relations)
#
# Idempotent: safe to run multiple times.
#
# Usage:
#   cd /Users/mulgogi/src/glossarist/glossarist-ruby
#   bundle exec ruby scripts/migrate_isotc211_to_v3.rb

require "glossarist"

DIR = "/Users/mulgogi/src/geolexica/isotc211-glossary/concepts"

ISO_SOURCE_URN = "urn:iso:std:iso"

# Extract a stable domain ID from an authoritative source reference string.
# @param ref_text [String] e.g. "ISO 19136-1:2020", "ISO/IEC 19501:2005"
# @return [String, nil] domain ID e.g. "iso-19136-1", "iso-iec-19501"
def extract_domain_id(ref_text)
  # Match various ISO reference patterns
  patterns = [
    %r{ISO/IEC/IEEE\s+([\d-]+)}, # ISO/IEC/IEEE 24765:2017
    %r{ISO/IEC\s+([\d-]+)},          # ISO/IEC 19501:2005
    %r{ISO/TS\s+([\d-]+)},           # ISO/TS 19130:2010
    %r{ISO/TR\s+([\d-]+)},           # ISO/TR 19120:2001
    %r{ISO/IEC\s+Guide\s+([\d-]+)},  # ISO/IEC Guide 98-3:2008
    %r{ISO\s+DIS\s+([\d-]+)},        # ISO DIS 19123-1:2022
    %r{ISO\s+(\d+-?\d*)}, # ISO 19136-1:2020
  ]

  patterns.each do |pat|
    if (m = ref_text.match(pat))
      # Extract the full match, normalize
      prefix = ref_text[m.begin(0)...m.begin(1)].strip
      number = m[1]
      domain = "#{prefix} #{number}"
      return domain.downcase.gsub(/[\s\/]+/, "-")
    end
  end

  nil
end

collection = Glossarist::ManagedConceptCollection.new
collection.load_from_files(DIR)

puts "Loaded #{collection.count} concepts"

# Build index: domain_id -> [concept_id]
domain_index = {}
concepts_with_domain = 0
concepts_without_domain = 0

collection.each do |concept|
  eng = concept.localization("eng")
  next unless eng

  sources = eng.data&.sources
  next unless sources

  auth = sources.find { |s| s.type == "authoritative" }
  next unless auth&.origin

  ref_text = auth.origin.text || auth.origin.ref
  unless ref_text
    concepts_without_domain += 1
    next
  end

  domain_id = extract_domain_id(ref_text)
  unless domain_id
    concepts_without_domain += 1
    next
  end

  (domain_index[domain_id] ||= []) << concept.data.id
  concepts_with_domain += 1

  # Add domain ConceptReference
  concept.data.domains ||= []
  unless concept.data.domains.any? { |d| d.concept_id == domain_id }
    concept.data.domains << Glossarist::ConceptReference.new(
      concept_id: domain_id,
      source: ISO_SOURCE_URN,
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

puts "Added domains to #{concepts_with_domain} concepts"
puts "No domain extracted for #{concepts_without_domain} concepts"

# Create domain hierarchy concepts
domain_index.sort.each do |domain_id, child_ids|
  mc = Glossarist::ManagedConcept.new(
    data: Glossarist::ManagedConceptData.new(
      id: domain_id,
      domains: [Glossarist::ConceptReference.new(
        concept_id: domain_id,
        source: ISO_SOURCE_URN,
        ref_type: "domain",
      )],
    ),
  )
  mc.status = "valid"

  # Create a basic English localization with the domain ID as the term
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

  # Add narrower relations to child concepts
  narrower = child_ids.sort.map do |child_id|
    Glossarist::RelatedConcept.new(
      type: "narrower",
      content: child_id.to_s,
      ref: Glossarist::Citation.new(source: "ISO", id: child_id.to_s),
    )
  end
  mc.related = narrower

  collection.store(mc)
  puts "Created domain: #{domain_id} — #{child_ids.size} narrower"
end

collection.save_grouped_concepts_to_files(DIR)
puts "Saved #{collection.count} concepts to #{DIR}"
