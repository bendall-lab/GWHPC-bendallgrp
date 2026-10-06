# 8. Publishing these docs

GitHub Pages serves static sites. The docs are plain Markdown with relative links, so any of these generators works.

| Option | Strengths | Trade-offs |
|---|---|---|
| **MkDocs + Material** (recommended) | Pure Markdown, one `mkdocs.yml` for navigation, search, dark mode, `mkdocs gh-deploy` or a short Actions workflow | Python tool |
| Jekyll + just-the-docs | Built into GitHub Pages; no CI needed | Ruby toolchain for local preview; plugin limits |
| Sphinx + MyST | Strong cross-referencing; fits Python/bioinformatics teams | More configuration than needed for ~10 pages |
| mdBook | Single binary, very simple | Fewer features, fewer themes |
| Docusaurus | Rich site features | Node toolchain; heavy for this scope |

**Chosen:** MkDocs Material. Configuration is `mkdocs.yml`; dependencies are in `requirements-docs.txt`; `.github/workflows/docs.yml` builds with `mkdocs build --strict` and deploys through GitHub Actions on pushes to `main` that touch the docs. The site URL is https://bendall-lab.github.io/GWHPC-bendallgrp/.

- **Add a page:** create `docs/NN-name.md`, add it to `nav:` in `mkdocs.yml`, and to the TOCs in `docs/index.md` and `README.md`.
- **Preview locally:** `pip install -r requirements-docs.txt && mkdocs serve`.
- **Pin MkDocs below 2.0.** The Material maintainers warn that MkDocs 2.0 will break plugins and themes, so `requirements-docs.txt` keeps `mkdocs<2`.
- **Pages visibility:** private repositories need a GitHub plan that supports Pages for them.

Pages sites are publicly readable by default. Keep sensitive details (internal quotas, contact lists) out of any public repo.
