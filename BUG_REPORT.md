# Bug Report — V3 model class gaps and date-type over-strictness

**Reporter**: IALA vocab port (`/Users/mulgogi/src/mn/iala-vocab`)
**Affected**: `glossarist` 2.8.x (any release)
**Severity**: Medium — caller-side workarounds required, round-trip is data-lossy for some valid YAML

## Summary

The `glossarist-ruby` gem ships a `V3::*` model hierarchy under `Glossarist::V3::` that
extends the base `Glossarist::*` classes with v3 schema additions. Two issues
remain:

1. **`V3::ConceptDate` does not exist.** The base `Glossarist::ConceptDate`
   types `date` as `:date_time`, which fails to parse year-only strings
   like `"2023"` that are valid per the v3 schema and common in real
   datasets (e.g. IALA Dictionary lifecycle markers). The v3 subclasses
   (`V3::ManagedConcept`, `V3::ConceptData`) inherit the wrong `dates`
   collection type from the base.

2. **The V3 namespace is discoverable but the base classes are still the
   default.** Callers using `Glossarist::ManagedConcept` /
   `Glossarist::LocalizedConcept` etc. silently miss the v3-only
   functionality (annotations, citation ref coercion). Only callers that
   know to use `Glossarist::V3::*` get the full v3 schema. This is not
   a bug per se, but the lack of a "use V3 by default" factory or
   documentation makes it easy to ship broken integrations.

Issue #1 is the actual bug. Issue #2 is a discoverability/DX issue worth
calling out.

## Reproduction

### Issue #1 — `V3::ConceptDate` missing

```ruby
require "glossarist"

cd = Glossarist::ConceptDate.new(type: "retired", date: "2023")
cd.to_yaml
# => "---\ndate: 2023-01-01T00:00:00+00:00\ntype: retired\n"   ← corrupted!
# lutaml-model coerces "2023" (interpreted as 2023-01-01 midnight UTC)

cd = Glossarist::V3::ConceptDate.new(type: "retired", date: "2023")
# NameError: uninitialized constant Glossarist::V3::ConceptDate
```

When the YAML round-trips through a base-class `ManagedConcept`, every
year-only date string is silently rewritten to `2023-01-01T00:00:00+00:00`,
corrupting the original data on the next write.

### Issue #2 — base classes lose v3 features

```ruby
require "glossarist"

data = Glossarist::ConceptData.new(language_code: "eng")
data.annotations << Glossarist::DetailedDefinition.new(content: "editorial remark")
data.to_yaml
# => "---\ndefinition: []\n...\nlanguage_code: eng\n"   ← annotations gone!

data = Glossarist::V3::ConceptData.new(language_code: "eng")
data.annotations << Glossarist::V3::DetailedDefinition.new(content: "editorial remark")
data.to_yaml
# => "---\n...\nannotations:\n- content: editorial remark\n"   ← correct
```

## Root cause

`lib/glossarist/concept_date.rb` (the base class) declares
`attribute :date, :date_time` on line 7. The v3 schema
(`concept-model/schemas/v3/concept.yaml`) declares
`concept_date.date` as `type: string, format: date`, which accepts any
date string. The base type is overly strict for the v3 schema.

`lib/glossarist/v3/` has subclasses for `ConceptData`, `ManagedConcept`,
`LocalizedConcept`, `Citation`, `ConceptSource`, `ConceptRef`,
`RelatedConcept`, `DetailedDefinition`, `ManagedConceptData`,
`ConceptDocument` — but no `ConceptDate`. The two v3 classes that have a
`dates` collection (`V3::ManagedConcept` and `V3::ConceptData`) inherit
the base `attribute :dates, ConceptDate, collection: true` and so
transitively inherit the wrong date type.

## Fix

Add `V3::ConceptDate` with `attribute :date, :string`, and explicitly
override the `dates` attribute on `V3::ConceptData` and
`V3::ManagedConcept` to use it:

```ruby
# lib/glossarist/v3/concept_date.rb
module Glossarist
  module V3
    class ConceptDate < Glossarist::ConceptDate
      attribute :date, :string

      key_value do
        map :date, to: :date
        map :type, to: :type
      end
    end
  end
end
```

```ruby
# lib/glossarist/v3/concept_data.rb — add this line to the attribute block
attribute :dates, V3::ConceptDate, collection: true

# lib/glossarist/v3/managed_concept.rb — add this line to the attribute block
attribute :dates, V3::ConceptDate, collection: true
```

Add `autoload :ConceptDate, "glossarist/v3/concept_date"` and
`Configuration.register_model(ConceptDate, id: :concept_date)` to
`lib/glossarist/v3.rb`.

## Test coverage added

`spec/unit/v3/concept_date_spec.rb`:

- Year-only strings (`"2023"`) round-trip
- Year ranges (`"1970-1989"`) round-trip
- Calendar dates (`"2020-01-01"`) round-trip
- Full ISO 8601 datetime (`"2020-01-01T00:00:00+00:00"`) still round-trips
- Integration: `V3::ConceptData.dates` and `V3::ManagedConcept.dates` both use `V3::ConceptDate`
- The class is reachable as `Glossarist::V3::ConceptDate`

All 7 tests pass; full suite (1456 examples) remains green.

## Caller-side impact

Callers using `Glossarist::ManagedConcept` (the base class) instead of
`Glossarist::V3::ManagedConcept` need to switch to the V3 subclasses.
There is no factory or `ManagedConcept.for_version(...)` accessor to
help them.

Suggested additional fix (out of scope for this PR): ship
`Glossarist::V3::ManagedConcept.for_dataset(...)` or make the base
classes re-export the V3 versions, so callers can't accidentally use the
v2 subset.

## Discovery context

Found while porting the IALA Dictionary (MediaWiki → Glossarist Concept
Browser site). PR #5 in `metanorma/iala-vocab` migrated 24K concept YAML
files to canonical v3 shape. PR #6 adopted the glossarist gem for typed
construction. The bugs above were found during PR #6 testing.

## Timeline

- **2026-07-02**: Bug found, fix authored in `metanorma/iala-vocab` PR #6
  (workaround: type-only idempotency check)
- **2026-07-02**: Bug reported to `glossarist-ruby` maintainers via this
  document
- **Pending**: Fix reviewed and merged upstream