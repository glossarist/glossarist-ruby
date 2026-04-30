# 01 — GCR Packaging CLI with Versioning

## Goal

The `glossarist` Ruby gem provides the canonical way to build versioned GCR packages from concept datasets. Each glossary repo uses `glossarist package` in CI to publish GCR releases.

## Current State

- CLI has `package`, `upgrade`, `validate` commands (via Thor)
- `GcrPackage.create` / `GcrPackage.load` handle ZIP I/O
- `GcrMetadata` generates metadata with statistics
- `SchemaMigration` handles v0→v1 harmonization
- Missing: `shortname` and `version` fields in GcrMetadata
- Missing: v2 format support in `PackageCommand`

## Tasks

### 1. Add `shortname` and `version` to `GcrMetadata`

Edit `lib/glossarist/gcr_metadata.rb`:

```ruby
attr_accessor :shortname, :version, :title, :description, :owner, :tags,
              :concept_count, :languages,
              :created_at, :glossarist_version, :schema_version,
              :statistics, :homepage, :repository, :license

def initialize(attrs = {})
  @shortname = attrs[:shortname]
  @version = attrs[:version]
  # ... existing fields ...
end

def self.from_concepts(concepts, register_data: nil, options: {})
  stats = GcrStatistics.from_concepts(concepts)
  new(
    shortname: options[:shortname],
    version: options[:version],
    title: options[:title] || register_data&.dig("name"),
    # ... existing fields ...
  )
end

def to_h
  h = {
    "shortname" => shortname,
    "version" => version,
    "title" => title,
    # ... existing fields ...
  }
  h.compact
end
```

### 2. Add `--shortname` and `--version` CLI options

Edit `lib/glossarist/cli.rb`:

```ruby
desc "package DIR", "Create a .gcr ZIP archive from a dataset"
option :output, aliases: :o, required: true, desc: "Output .gcr file path"
option :shortname, type: :string, required: true, desc: "Machine-readable dataset ID"
option :version, type: :string, required: true, desc: "Semantic version (e.g. 1.0.0)"
option :title, type: :string, desc: "Dataset title"
option :description, type: :string, desc: "Dataset description"
option :owner, type: :string, desc: "Dataset owner"
option :register_yaml, type: :string, desc: "Path to register.yaml"
option :tags, type: :array, desc: "Tags for the dataset"
def package(dir)
  # ...
end
```

### 3. Add v2 format support to `PackageCommand`

Edit `lib/glossarist/cli/package_command.rb`:

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
    hash[lang] = localized_to_hash(l10n)
  end
  hash["term"] = preferred_designation(hash["eng"]&.dig("terms")) || ""
  hash
end

def localized_to_hash(l10n)
  h = {}
  h["terms"] = l10n.designations.map(&:to_h) if l10n.designations.any?
  h["definition"] = l10n.definition.map { |d| { "content" => d.content } } if l10n.definition.any?
  h["notes"] = l10n.notes.map { |n| { "content" => n.content } } if l10n.notes.any?
  h["examples"] = l10n.examples.map { |e| { "content" => e.content } } if l10n.examples.any?
  h["sources"] = l10n.sources.map(&:to_h) if l10n.sources.any?
  h["language_code"] = l10n.language_code if l10n.language_code
  h["entry_status"] = l10n.entry_status if l10n.entry_status
  h["dates"] = l10n.dates.map(&:to_h) if l10n.dates.any?
  h
end
```

### 4. Auto-derive shortname from directory name

If `--shortname` is not provided, derive from:
1. `register.yaml` → `register["shortname"]` or `register["id"]`
2. Directory basename
3. Raise error if none available

### 5. Validate filename matches metadata

In `GcrPackage.validate`, check that the filename pattern `{shortname}-{version}.gcr` matches the `shortname` and `version` in metadata.yaml.

### 6. Publish gem

```bash
gem build glossarist.gemspec
gem push glossarist-2.6.0.gem
```

## CLI Usage

```bash
# Install
gem install glossarist

# Package (v1 format)
glossarist package ./isotc204-glossary \
  --shortname isotc204 --version 1.0.0 \
  -o isotc204-1.0.0.gcr \
  --title "ISO/TC 204 ITS Vocabulary" --owner "ISO/TC 204"

# Package (v2 format, auto-detected)
glossarist package ./isotc211-glossary \
  --shortname isotc211 --version 2.3.0 \
  -o isotc211-2.3.0.gcr \
  --title "ISO/TC 211 Multi-Lingual Glossary" --owner "ISO/TC 211"

# Validate
glossarist validate isotc204-1.0.0.gcr
```

## Acceptance Criteria

- [ ] `GcrMetadata` includes `shortname` and `version` fields
- [ ] `glossarist package --shortname X --version Y` produces `{X}-{Y}.gcr`
- [ ] `metadata.yaml` contains `shortname` and `version`
- [ ] `glossarist validate` checks metadata has required fields
- [ ] Works with both v1 (`concepts/*.yaml`) and v2 (`geolexica-v2/*.yaml`) datasets
- [ ] Gem published to RubyGems
