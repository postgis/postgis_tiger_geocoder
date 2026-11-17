# AGENTS.md

Guidance for agents and contributors working on `postgis_tiger_geocoder`.

## Project overview

See [README.md](README.md) for the project description, requirements,
installation, upgrading, verification, and data loading.

## Layout

- `src/` - SQL source grouped by feature (`geocode/`, `normalize/`,
  `pagc_normalize/`, `tables/`, `topology/`, `utility/`).
- `sql_bits/` - reusable `.sql.in` fragments used to assemble extension files.
- `Makefile` / `GNUmakefile` - build, test, install, and release assembly.
- `data/`, `sql/`, `expected/`, `results/` - generated build/test output.
  Do not edit these by hand and do not commit them.
- `src/regress/` - regression test inputs and desired outputs.
- `doc/` - function reference.
- `tools/run-check.sh` - self-contained temporary-cluster test runner.
- `scripts/release.sh`, `.woodpecker/`, `.jenkins/`, `ci/` - release and CI.

## Build and test

See [README.md](README.md#building-the-extension) for build, install, and
`check` options. Always run `make -j check` (or `make installcheck` against an
installed extension) before submitting changes; report the command and
environment used.

## SQL conventions

- Use the `tiger.` schema prefix for every extension object reference. Do not
  rely on `search_path`.
- Keep `@extschema:postgis@`, `@extschema:fuzzystrmatch` (and similar) qualification for PostGIS types and
  other extension function signatures.
- Schema qualify all references to pg_catalog objects.
- Write `CREATE OR REPLACE FUNCTION`, `LANGUAGE plpgsql`.
- Match the surrounding file: tab indentation for SQL, `$_$` dollar quoting,
  uppercase SQL keywords, and existing naming (`snake_case`).
- When adding a function, add it to the appropriate list in `Makefile` and the
  upgrade assembly so it ships in both fresh installs and upgrades.
- Keep extension objects relocatable-safe and avoid superuser-only behavior;
  this is a trusted extension.

## Tests

- Add normalize/geocode cases to the matching `src/regress/*_regress.sql`;
  add expected output to `src/regress/*_desired_regress`.
- Tests are assembled into `sql/test-*.sql` and `expected/test-*.out` by the
  `Makefile`; edit the `src/regress` and `sql_bits` sources, not generated files.
- Run the focused target where possible, then the full `make -j check`.
- Update `expected/` only when the new output is intentional and correct.

## Style and edits

- Follow `.editorconfig`: UTF-8, LF, trailing whitespace trimmed, final newline.
- Tabs for `*.sql`, `*.c`, `*.h`, `*.pl`, and `Makefile`; spaces for XML.
- `.bat` files use CRLF and shell files use LF (see `.gitattributes`).
- Do not add comments unless they explain non-obvious intent.
- Keep diffs focused; do not reformat unrelated code.

## Commits, issues, and releases

- Reference issues/PRs (for example `Closes #51`, `GT-58`) in commit messages
  and `NEWS.md` entries when appropriate.
- Add user-visible changes under the correct version section in `NEWS.md` with
  an issue/ticket link and contributor name, matching existing style.
- Do not bump `postgis_tiger_geocoder.control`, `META.json`, or
  `upgradeable_versions.mk` unless the task explicitly asks for a release.

## AI / LLM usage disclosure

If an LLM or other generative AI tool assisted with a change, state the model
and provider used. Keep it factual and brief, for example:

```
Assisted-by: big-pickle (opencode)
```

or, when the model and provider differ:

```
Assisted-by: <model-name> via <provider-name>
```

Include this in the commit message, PR description, or the relevant code/comment
context. Do not include links to the provider or promotional URLs.
