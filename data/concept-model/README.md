# data/concept-model — vendored data artifacts from concept-model repo

This directory holds **data-only** artifacts copied from
[glossarist/concept-model](https://github.com/glossarist/concept-model).

concept-model is a *model* repo (TTL, JSON-LD, YAML schemas). It holds no
code, no npm package, no Ruby gem. glossarist-ruby vendors the small set
of data files it needs at build time. There is no runtime dependency on
concept-model.

## Files

| File | Purpose |
|------|---------|
| `prefixes.ttl` | Canonical prefix bindings SSOT — consumed verbatim by every Turtle/JSON-LD serializer in the ecosystem |
| `glossarist.context.jsonld` | JSON-LD term map — reference |
| `glossarist.ttl` | OWL ontology (reference; not currently read at runtime) |
| `shapes/glossarist.shacl.ttl` | SHACL shapes — loaded by `Glossarist::Validation::ShaclValidator` at runtime |

## Syncing

Update these files from the latest concept-model tag:

```bash
rake glossarist:sync:model          # fetches latest released tag
rake glossarist:sync:model[v3.1.0]  # pin to a specific tag
rake glossarist:sync:model[main]    # tracking upstream main (uncommon)
```

The sync task fetches via the GitHub raw endpoint (no clone needed).

## Why vendor instead of `gem add`?

Because concept-model is not a gem. Treating it as one would require
bolting codegen + packaging onto a repo that should only hold data.
Vendoring the small data files we need keeps the model repo clean and
lets this repo's bindings evolve independently.
