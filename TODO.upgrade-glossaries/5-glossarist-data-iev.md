# Upgrade Plan: glossarist-data-iev

**Repo**: glossarist/glossarist-data-iev
**PR**: https://github.com/glossarist/glossarist-data-iev/pull/1
**Branch**: `feat/glossarist-gcr-publishing`
**Concepts**: 22,228 (12 languages, IEC Electropedia / IEV 60050)

## Current State

- **Data format**: v0 (legacy IEV format in `concepts/` directory).
- `glossarist package .` picks v1 path → packages and validates clean after glossarist fixes.
- **Main branch**: Already has updated `publish-gcr.yml` using `gem install glossarist`.
- **PR**: Adds 22,228 concept files + `build.yml` + `publish-gcr.yml` + metadata.

## Issues Found

### 1. `entry_status: "Standard"` — invalid enum value (279K errors across 22K concepts)

All IEV concepts use `entry_status: Standard` instead of the expected `valid`. The glossarist validator rejects this. This is the bulk of validation errors.

**Fix options**:
- (a) Bulk-replace `Standard` → `valid` across all 22K concept files in the repo
- (b) Add `"Standard"` as an alias for `"valid"` in `GlossaryDefinition` config
- (c) Handle in `SchemaMigration` during packaging (normalize on read)

### 2. `definition` is a bare string instead of array (40K errors)

IEV concepts have:
```yaml
definition: "some text"
```
Instead of:
```yaml
definition:
  - content: "some text"
```

**Fix options**:
- (a) Bulk-migrate all concept files to use array format
- (b) Handle in `SchemaMigration` during packaging (wrap string in array)
- (c) Make `ConceptData#definition` accept both formats (normalize on load)

### 3. YAML files contain `Symbol` references (2K errors)

Some concept files have YAML that requires `Symbol` class for `safe_load`. The `build.yml` CI workflow uses `YAML.safe_load_file` without `permitted_classes: [Symbol]`, so CI will fail.

**Fix options**:
- (a) Fix `build.yml` to add `Symbol` to permitted classes
- (b) Audit and fix the ~2K files that contain Symbol references (e.g., `:foo` keys)

### 4. No `geolexica-v2/` directory

IEV uses v0 format only. `glossarist package` reads via the v1 path (raw YAML → flat hash), which works. But the concepts don't go through the model layer (no `ManagedConceptCollection`), so model-level validation is bypassed.

## Recommended Approach

The IEV data is large (22K files). Rather than bulk-editing all files, the recommended approach is:

1. **Make `SchemaMigration` handle v0 → v1** during packaging:
   - Normalize `entry_status: Standard` → `valid`
   - Wrap bare string `definition` → `[{content: string}]`
   - Permit `Symbol` in YAML loading
2. **Or** bulk-migrate the files once and commit the normalized versions.

This ensures the `glossarist package` CLI produces clean output regardless of input format.

## Action Items

1. [x] Fix `GcrPackage#collect_v1_concepts` to permit `Symbol` in YAML loading — fixed in glossarist-ruby.
2. [x] Fix `aliases: true` in GCR ZIP validation — fixed in glossarist-ruby.
3. [ ] Decide on normalization strategy for `entry_status` and `definition` format.
4. [ ] Either fix `build.yml` to permit Symbol, or fix the ~2K YAML files.
5. [ ] Release glossarist gem with fixes (needs version >= 2.6.0).
6. [ ] Merge PR #1.

## Validation Results

```
glossarist validate concepts/ → 279,454 errors (entry_status, definition format, Symbol)
glossarist package . → Created iev-test.gcr (22,228 concepts, bypasses model validation)
glossarist validate .gcr → Valid. 0 issues.
```
