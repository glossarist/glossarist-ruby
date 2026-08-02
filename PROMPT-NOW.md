# PROMPT-NOW: parseMention extension + legacy <<>> deprecation + terminology alignment + raw-HTML validation

> **Context:** concept-browser is implementing a strict DATA/DEPLOYMENT boundary for inline content. This requires all Glossarist libraries (JS, Ruby, and the concept-model schema) to parse the same unified `{{kind:target}}` syntax and align terminology. The JS library changes are tracked in a parallel PROMPT-NOW.md; this prompt mirrors them for the Ruby library. Self-contained.

## Background: the principle

**Dataset authors** write `{{kind:target}}` mentions in concept text. They don't know where their dataset will be deployed.

**Concept-browser** resolves every mention at runtime via `ReferenceResolver`. For this to work, `parse_mention` must produce a canonical `{kind, target, label}` shape for every mention kind — identical to the JS library's output.

The current parser recognizes `cite:`, `urn:`, `fig:`/`figure:`, `table:`/`tbl:`, `formula:`/`eq:`, and bare designation/numeric. Three new kinds are needed: `link`, `image`, `bib`.

---

## P1: parse_mention extension — `link`, `image`, `bib` kinds

### New kinds to parse

```ruby
Glossarist.parse_mention("{{link:https://example.com/page}}")
# => { kind: 'link-ref', uri: 'https://example.com/page', label: nil }

Glossarist.parse_mention("{{link:https://example.com, click here}}")
# => { kind: 'link-ref', uri: 'https://example.com', label: 'click here' }

Glossarist.parse_mention("{{image:diagram.png}}")
# => { kind: 'image-ref', src: 'diagram.png', alt: nil }

Glossarist.parse_mention("{{image:diagram.png, The diagram}}")
# => { kind: 'image-ref', src: 'diagram.png', alt: 'The diagram' }

Glossarist.parse_mention("{{bib:ref_1}}")
# => { kind: 'bib-ref', id: 'ref_1', label: nil }

Glossarist.parse_mention("{{bib:ref_1, ISO 704}}")
# => { kind: 'bib-ref', id: 'ref_1', label: 'ISO 704' }
```

### Design notes

- `link` uses `uri` (not `id`) because the target is a URL, not a dataset-local handle. The URL is canonical — external to all datasets, deployment-independent.
- `image` uses `src` (not `uri`) and `alt` (not `label`) because it's an embed, not a link. The `alt` field is the accessibility text.
- `bib` uses `id` because it references a dataset-local bibliography entry. This is the case-3-only path — the author explicitly wants a flat bibliographic record, not a concept resolution.

The parsed shapes MUST match the JS library's output exactly (same keys, same values) so concept-browser can consume either library's output interchangeably.

---

## P2: Legacy `<<target, caption>>` deprecation

### The problem

The AsciiDoc xref syntax `<<target, caption>>` has been overloaded for:
1. **Non-concept entity xrefs** (legitimate AsciiDoc use — should map to `{{fig/table/formula:target, caption}}`)
2. **Bibliography lookups** (wrong — bypasses the resolution cascade)
3. **Concept citations** (wrong — should use `{{cite:target, caption}}`)

### Proposed change

When the parser encounters `<<target, caption>>`:

1. **Emit a deprecation warning** via Ruby's `Warning` module:

```ruby
Warning.warn("[glossarist] <<#{target}, #{caption}>> is deprecated. " \
             "Use {{fig/table/formula:#{target}, #{caption}}} for non-concept entities, " \
             "or {{cite:#{target}, #{caption}}} for concept citations.")
```

2. **Re-parse** based on what `target` resolves to:
   - If `target` matches a figure/table/formula entity in the dataset → treat as `{{kind:target, caption}}`
   - Otherwise → treat as `{{cite:target, caption}}` (let concept-browser's resolution cascade handle it)

3. **Do NOT** treat as a bibliography lookup. Bibliography is reached only via `{{bib:id}}` (explicit) or via the resolution cascade's case-3 fallback (implicit).

### RuboCop cop (optional)

Consider a custom RuboCop cop that flags `<<...,...>>` in concept text fixtures:

```ruby
# .rubocop.yml
require: glossarist/rubocop

Glossarist/NoLegacyXrefSyntax:
  Enabled: true
  Description: 'Use {{kind:target}} instead of <<target, caption>>'
```

---

## P3: Terminology alignment

### The rename

Rename `NonVerbalEntity` → `NonConceptEntity` in Ruby model classes (where referring to Figure/Table/Formula). The terminology fix:

- **Non-verbal** refers to the modality of expression (non-verbal designation: symbol, formula expression). Properties OF concepts.
- **Non-concept** refers to entities that are NOT concepts at all (Figure, Table, Formula). Standalone dataset entities.

### Proposed change

```ruby
# BEFORE
module Glossarist
  class NonVerbalEntity < GlossaristModel; end      # ambiguous
  class SharedNonVerbalEntity < NonVerbalEntity; end
  class NonVerbRep < GlossaristModel; end            # concept-local designation
end

# AFTER
module Glossarist
  class NonConceptEntity < GlossaristModel; end      # clear — NOT a concept
  class NonVerbRep < GlossaristModel; end            # unchanged — IS a designation

  # Deprecated alias for backward compat
  # @deprecated Use NonConceptEntity instead.
  NonVerbalEntity = NonConceptEntity
  SharedNonVerbalEntity = NonConceptEntity
end
```

Keep `NonVerbRep` unchanged — it IS a non-verbal representation (a designation of a concept).

Provide deprecated aliases for one release cycle.

---

## P4: Raw-HTML validation

### The problem

Concept text sometimes contains raw HTML instead of typed mention syntax:

```yaml
# BAD — raw HTML in YAML
definition:
  - content: See <a href="http://std.iec.ch/...">IEV</a> for details.
```

This bypasses the renderer, is brittle, has no accessibility contract, and can embed deployment-specific URLs.

### Proposed change

Add a validator:

```ruby
module Glossarist
  module Validators
    class NoRawHtml
      def self.call(text)
        issues = []

        # <a href="URL">label</a> → {{link:URL, label}}
        text.scan(/<a\s+href="([^"]+)"[^>]*>([^<]*)<\/a>/i) do |url, label|
          issues << {
            severity: 'warning',
            match: "<a href=\"#{url}\">#{label}</a>",
            suggestion: label && !label.empty? ? "{{link:#{url}, #{label}}}" : "{{link:#{url}}}",
            message: 'Use {{link:}} instead of raw <a> tags',
          }
        end

        # <img src="SRC" alt="ALT"> → {{image:SRC, ALT}}
        text.scan(/<img\s+src="([^"]+)"(?:\s+alt="([^"]*)")?[^>]*>/i) do |src, alt|
          suggestion = alt ? "{{image:#{src}, #{alt}}}" : "{{image:#{src}}}"
          issues << {
            severity: 'warning',
            match: "<img src=\"#{src}\"#{" alt=\"#{alt}\"" if alt}>",
            suggestion: suggestion,
            message: 'Use {{image:}} instead of raw <img> tags',
          }
        end

        issues
      end
    end
  end
end
```

Replacement suggestions:

| Raw HTML | Suggested replacement |
|---|---|
| `<a href="URL">label</a>` | `{{link:URL, label}}` |
| `<a href="URL">URL</a>` | `{{link:URL}}` |
| `<img src="SRC">` | `{{image:SRC}}` |
| `<img src="SRC" alt="ALT">` | `{{image:SRC, ALT}}` |
| `<iframe src="URL">` | `{{link:URL}}` (iframes not supported as embeds) |

The validator is opt-in — concept-browser (or the data pipeline) can call it during data loading to warn dataset authors.

---

## Summary

| Change | Impact |
|---|---|
| P1: parse_mention extension | New parsed shapes for `link`, `image`, `bib` (must match JS output exactly) |
| P2: Legacy `<<>>` deprecation | Warning + re-parse; optional RuboCop cop |
| P3: Terminology rename | `NonVerbalEntity` → `NonConceptEntity` (with deprecated alias) |
| P4: Raw-HTML validator | New `Glossarist::Validators::NoRawHtml` class |

## Coordination

- **concept-model** needs schema changes for the new kinds and terminology (parallel PROMPT-NOW.md).
- **glossarist-js** needs the same parser extension (parallel PROMPT-NOW.md).
- **concept-browser** wires the resolvers once both libraries ship the new parse output.
- A **shared contract test fixture** (a concept with every kind of mention) should be consumed by all implementations to prevent syntax drift. The fixture lives in concept-model; both libraries import it.

## Cross-library contract

The parsed output from `parse_mention` MUST be identical between the Ruby and JS libraries:

```ruby
# Ruby
Glossarist.parse_mention("{{link:https://example.com, click here}}")
# => { kind: 'link-ref', uri: 'https://example.com', label: 'click here' }
```

```ts
// JS
parseMention("{{link:https://example.com, click here}}")
// => { kind: 'link-ref', uri: 'https://example.com', label: 'click here' }
```

Same keys. Same values. Same symbol-as-string for `kind`. This allows concept-browser to consume either library's output without translation.
