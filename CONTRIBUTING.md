# Contributing to PostGIS Tiger Geocoder

This file is the stable entry point for contribution information. See
[README.md](README.md) for usage, installation, and data loading, and
[AGENTS.md](AGENTS.md) for build, test, and coding conventions.

## Reporting bugs

Search the [issue tracker](https://gitea.osgeo.org/postgis/postgis_tiger_geocoder/issues)
first. If the problem is already reported, add the extra context there instead
of opening a duplicate.

Reduce reports to the smallest reproducible example, ideally a single SQL
statement, and include expected versus actual output. Always include:

```sql
SELECT version();
SELECT postgis_full_version();
SELECT extversion FROM pg_extension WHERE extname = 'postgis_tiger_geocoder';
```

For data loading or geocoding results, also state the state(s)/county(ies)
loaded and the TIGER/Line year.

Usage questions belong on the [PostGIS mailing lists](https://postgis.net/community/mailinglists/)
or other community support channels, not the bug tracker.

## Reporting security issues

Do not file security-sensitive reports in the public tracker. Follow
[SECURITY.md](SECURITY.md) and email `security@postgis.net`.

## Source repositories

The official repository is the OSGeo Gitea repository:

```sh
git clone https://gitea.osgeo.org/postgis/postgis_tiger_geocoder.git
cd postgis_tiger_geocoder
```

Issues and pull requests are accepted only on the primary OSGeo Gitea
repository.

## Making changes

1. Fork the repository and create a branch named for the issue or topic.
2. Build and test as described in [README.md](README.md#building-the-extension).
3. Change the source file under `src/` that owns the behavior. Do not edit the
   generated `data/`, `sql/`, `expected/`, or `results/` output by hand.
4. Add regression coverage for behavior changes:
   - normalize/geocode cases in `src/regress/*_regress.sql`;
   - expected output in the matching `src/regress/*_desired_regress`.
5. When adding a function, add it to the appropriate list in `Makefile` and the
   upgrade assembly so it ships in fresh installs and upgrades.
6. Update [doc/postgis_tiger_geocoder.md](doc/postgis_tiger_geocoder.md) for
   user-visible SQL changes and add a `NEWS.md` entry for user-visible fixes and
   features.
7. Run `make -j check` (or `make installcheck` against an installed extension)
   before submitting and report the command and environment used.

Keep each change focused on one issue or reviewable topic. Follow
[.editorconfig](.editorconfig) and the SQL, testing, and commit conventions in
[AGENTS.md](AGENTS.md). Do not bump `postgis_tiger_geocoder.control`,
`META.json`, or `upgradeable_versions.mk` unless the change is explicitly a
release.

## Commit messages

Reference the issue or pull request in the commit message, for example:

```
Normalize route exit addresses

Closes #5
Closes #51
```

Add user-visible changes under the correct version section in `NEWS.md`, with an
issue/ticket link and contributor name, matching the existing style.

## AI / LLM usage disclosure

See [AGENTS.md](AGENTS.md#ai--llm-usage-disclosure).

## Getting help

Use the [postgis-users mailing list](https://lists.osgeo.org/mailman/listinfo/postgis-users)
for usage questions and the
[postgis-devel mailing list](https://lists.osgeo.org/mailman/listinfo/postgis-devel)
for design discussion and larger changes. Discuss substantial features before
investing heavily in implementation.
