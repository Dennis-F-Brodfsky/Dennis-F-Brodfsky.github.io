---
name: arxiv-paper-fetcher
description: Find and download an arXiv paper from a user-provided title, arXiv URL, or identifier, preferring a cleaned HTML article, then LaTeX source, and finally PDF. Use when collecting local, AI-readable arXiv research material.
---

# arXiv Paper Fetcher

Store paper material inside the location already chosen for the task. In this
repository, default to `_drafts/<topic>/materials/arxiv/` so research material
does not add a new top-level directory. Do not invent `<topic>` when the active
task does not make it clear; ask for the destination or use an explicitly
provided output directory.

Run `scripts/fetch_arxiv.sh <title, arXiv URL, or ID> <output-root>`. For a
title, the script searches the official arXiv API. Continue automatically only
when exactly one result has the same title after case and whitespace
normalization. If search returns only similar matches or multiple exact matches,
show the candidates and ask the user to select one; do not infer from search
rank. If no result exists, report that and do not start the download fallback.

After resolving an ID, the script creates one directory per normalized arXiv ID
and implements this fallback order:

1. Download the official arXiv HTML page. Accept it only when it contains a
   paper `<article>` element. Preserve the full response as
   `arxiv-original.html` and create `paper.html` containing only the article,
   wrapped in a minimal UTF-8 HTML document. Keep MathML, its TeX annotations,
   citations, tables, and figure references intact.
2. If usable HTML is unavailable, download the official TeX source archive.
   Reject error pages and unsafe archive paths. Extract it under `latex/` and
   accept it only when at least one non-empty `.tex` file exists. Keep the
   downloaded archive as `source.tar.gz`.
3. If neither HTML nor LaTeX is usable, download the official PDF as
   `paper.pdf`. Verify the `%PDF-` signature rather than trusting the response
   extension.

Treat a failed validation as an unsupported format and continue to the next
format. Do not claim a format succeeded merely because the HTTP request did.
Report the selected format, local paths, and any fallback that occurred. Network
access or other elevated execution still requires the normal runtime approval.

When HTML succeeds, note that formulas are preserved as MathML with TeX
annotations, while linked images or styles may still refer to arXiv. Do not
rewrite the paper's scholarly content. Record provenance or checksums in the
task's existing material index when one exists.
