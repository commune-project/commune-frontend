# Contributing

Before changing behavior, read the active OpenSpec artifacts and the backend browser/API documentation. If a required backend capability is missing, stop the affected implementation and report the contract, evidence, and workflow instead of inventing a response or changing the backend.

Keep HTTP state explicit: do not add automatic mutation retries, cache private data in browser storage, inject editor source as HTML, or treat server permission fields as authorization substitutes. Preserve unsent forms on recoverable errors and route changes that keep the editor open.

After editing Fluent files, run:

```sh
npm run i18n:generate
npm run i18n:check
```

Compile and test with an explicit Elm cache:

```sh
ELM_HOME=/tmp/commune-elm-home npm run compile
ELM_HOME=/tmp/commune-elm-home npm test
ELM_HOME=/tmp/commune-elm-home npm run build
```

Start `ELM_HOME=/tmp/commune-elm-home npm run dev -- --port 4173`, then run `npm run test:browser`. For the isolated PostgreSQL/HTTPS acceptance, use the commands in `docs/accessibility-and-testing.md`.
