# Repository Guidelines

## Project Layout

This is a Jekyll-powered GitHub Pages blog. Site settings live in `_config.yml`; layouts and reusable fragments live in `_layouts/` and `_includes/`. Put drafts in `_drafts/`, published articles in `_posts/`, theme sources in `less/` and `js/`, compiled CSS in `css/`, and static images and fonts in `img/` and `fonts/`. `sw.js` and `offline.html` provide offline behavior.

## Common Commands

- `bundle install` installs dependencies from `Gemfile.lock`.
- `bundle exec jekyll serve` runs the site at `http://127.0.0.1:4000/`.
- `bundle exec jekyll serve --drafts` includes unpublished drafts.
- `bundle exec jekyll build` performs a production-style build.

Do not assume the legacy Grunt tasks work. `Gruntfile.js` exists, but `package.json` does not.

## Conventions

Use two-space indentation in YAML, HTML/Liquid, JavaScript, and LESS. Reuse the existing LESS variables and mixins. Name posts `YYYY-MM-DD-short-title.md`, include `layout`, `title`, `date`, and `tags` in front matter, and use lowercase hyphenated names for new assets.

## Content and Privacy

Treat `_drafts/` and `_posts/` as public, publication-ready content. Never include personal usernames, real home paths, hostnames, email addresses, account or session identifiers, credentials, tokens, or machine-specific metadata. Use placeholders such as `~`, `$HOME`, `<username>`, and `<host>`, and redact copied commands, outputs, screenshots, and image metadata.

Base technical narratives on verified commands, outputs, and observations. Distinguish suggested, uncertain, and externally performed steps from actions actually completed.

## Validation

Before submitting a draft or post, scan changed content for private data and run `bundle exec jekyll build --drafts`. For other site changes, run `bundle exec jekyll build`. Inspect affected pages with `bundle exec jekyll serve` when navigation, layout, responsive behavior, assets, Liquid rendering, or offline behavior changes. Treat warnings and broken links as defects.

## Git Workflow

For every branch, commit, rebase, push, and pull-request operation, read and follow `GIT-GUIDELINE.md`. Only commit or push when the user explicitly requests it. Preserve existing modifications and untracked files unless the user places them in scope.
