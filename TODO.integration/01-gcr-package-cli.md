# 01 — GCR Packaging CLI for Glossary Repos

## Goal

The `glossarist` Ruby gem provides the canonical way to build GCR packages from concept datasets. Each glossary repo uses `glossarist package` or `glossarist upgrade` in CI to publish GCR releases.

## Current State

- CLI already has `package`, `upgrade`, `validate` commands (via Thor)
- `GcrPackage.create` / `GcrPackage.load` handle ZIP I/O
- `GcrMetadata.from_concepts` generates statistics
- `SchemaMigration` handles v0→v1 harmonization (definition, sources, dates, entry_status, inline refs)
- `PackageCommand` expects `concepts/*.yaml` with `termid` field (v1 format)
- `UpgradeCommand` handles v0→v1 migration and can output `.gcr` directly

## Problem

`PackageCommand#collect_concepts` only looks in `concepts/` or root for `*.yaml` files with `termid`. It does NOT handle:

1. **Geolexica v2 format** (`geolexica-v2/` directory with UUID-named multi-document YAML files) — used by isotc211-glossary and osgeo-glossary
2. **Paneron format** (`geolexica/` directory) — used by isotc211-glossary

The `ConceptManager` already supports both v1 and v2 formats via `load_from_files`, but the CLI `package` and `upgrade` commands bypass it — they read raw YAML instead of using the model classes.

## Tasks

### 1. Add v2 support to `PackageCommand`

In `lib/glossarist/cli/package_command.rb`, update `collect_concepts`:

- If no `concepts/` dir with `termid` files is found, check for `geolexica-v2/` directory
- Use `ConceptManager` to load v2 files, then serialize each concept to the canonical v1 hash format
- Each `ManagedConcept` becomes one hash with `termid` and language blocks

```ruby
def collect_concepts
  if v1_concepts?
    collect_v1_concepts
  elsif v2_concepts?
    collect_v2_concepts
  else
    []
  end
end

def v1_concepts?
  concepts_dir = File.join(@dir, "concepts")
  File.directory?(concepts_dir) && Dir.glob(File.join(concepts_dir, "*.yaml")).any?
end

def v2_concepts?
  File.directory?(File.join(@dir, "geolexica-v2"))
end

def collect_v2_concepts
  collection = Glossarist::ManagedConceptCollection.new
  manager = Glossarist::ConceptManager.new(path: File.join(@dir, "geolexica-v2"))
  manager.load_from_files(collection: collection)

  collection.map { |concept| concept_to_v1_hash(concept) }
end

def concept_to_v1_hash(concept)
  hash = { "termid" => concept.data.id.to_s }
  concept.localizations.each do |lang, l10n|
    hash[lang] = localized_concept_to_hash(l10n)
  end
  hash
end
```

### 2. Add v2 support to `UpgradeCommand`

Same approach — detect v2 format and use `ConceptManager` to load before migrating.

### 3. Add `--register-yaml` auto-detection

If `register.yaml` exists in the source dir, use it automatically without requiring `--register-yaml` flag.

### 4. Handle schema version for v2 datasets

v2 datasets have `register.yaml` with `schema_version: "2"`. The current `PackageCommand` rejects anything that isn't the current version. For v2:
- Either auto-upgrade before packaging
- Or accept v2 and convert inline

### 5. Test with real datasets

```bash
# Test with isotc204 (v1 format, concepts/*.yaml)
glossarist package /path/to/isotc204-glossary -o isotc204.gcr --title "ISO/TC 204" --owner "ISO/TC 204"

# Test with isotc211 (v2 format, geolexica-v2/*.yaml)
glossarist package /path/to/isotc211-glossary -o isotc211.gcr --title "ISO/TC 211" --owner "ISO/TC 211"

# Test with osgeo (v2 format)
glossarist package /path/to/osgeo-glossary -o osgeo.gcr --title "OSGeo Lexicon" --owner "OSGeo"

# Validate
glossarist validate isotc204.gcr
glossarist validate isotc211.gcr
```

### 6. Ensure gem is published

- Current version: 2.5.0
- Publish to RubyGems after changes
- Ensure `gem install glossarist` works

## Acceptance Criteria

- [ ] `glossarist package` works with both v1 (`concepts/*.yaml`) and v2 (`geolexica-v2/*.yaml`) datasets
- [ ] Output GCR matches the spec in vocabulary-browser `docs/gcr-spec.md`
- [ ] `glossarist validate` passes on the output
- [ ] No dependency on vocabulary-browser or Node.js
