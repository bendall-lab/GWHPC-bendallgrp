# 8. Publishing these docs

GitHub Pages serves static sites. The docs are plain Markdown with relative links, so any of these generators works.

| Option | Strengths | Trade-offs |
|---|---|---|
| **MkDocs + Material** (recommended) | Pure Markdown, one `mkdocs.yml` for navigation, search, dark mode, `mkdocs gh-deploy` or a short Actions workflow | Python tool |
| Jekyll + just-the-docs | Built into GitHub Pages; no CI needed | Ruby toolchain for local preview; plugin limits |
| Sphinx + MyST | Strong cross-referencing; fits Python/bioinformatics teams | More configuration than needed for ~10 pages |
| mdBook | Single binary, very simple | Fewer features, fewer themes |
| Docusaurus | Rich site features | Node toolchain; heavy for this scope |

**Recommendation:** MkDocs Material. Add `mkdocs.yml` (nav matching [the index](index.md)) and a GitHub Actions workflow that runs `mkdocs gh-deploy --force`, then set Pages to serve the `gh-pages` branch. If the repository is private, check that your GitHub plan supports Pages for private repositories.

Pages sites are publicly readable by default. Keep sensitive details (internal quotas, contact lists) out of any public repo.
