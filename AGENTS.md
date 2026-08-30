# Repository Guidelines

## Project Structure & Module Organization

This repository is a Jekyll-powered GitHub Pages blog. Site-wide settings live in `_config.yml`. Top-level pages such as `index.html`, `about.html`, and `tags.html` use templates from `_layouts/` and reusable fragments from `_includes/`. Draft and article content belongs in `_drafts/` and `_posts/` respectively. Theme source is split between `less/` and `js/`, while compiled CSS is committed under `css/`. Images and fonts belong in `img/` and `fonts/`. `sw.js` and `offline.html` provide offline behavior.

## Build, Test, and Development Commands

- `bundle install` installs the dependencies recorded in `Gemfile.lock`.
- `bundle exec jekyll serve` builds the site and serves it at `http://127.0.0.1:4000/`, rebuilding after edits.
- `bundle exec jekyll serve --drafts` also includes unpublished content from `_drafts/`.
- `bundle exec jekyll build` performs the production-style validation used by `.travis.yml`; generated output goes to ignored `_site/`.

`Gruntfile.js` describes legacy LESS compilation and JavaScript minification, but the required `package.json` is not present. Do not assume `grunt` works unless its dependency manifest is restored in the same change.

## Coding Style & Naming Conventions

Use two-space indentation in YAML, HTML/Liquid, JavaScript, and LESS, and keep Liquid expressions readable. Reuse variables and mixins from `less/variables.less` and `less/mixins.less` instead of duplicating theme values. Name article files `YYYY-MM-DD-short-title.md` and begin them with YAML front matter containing at least `layout`, `title`, `date`, and `tags`. Use lowercase, hyphenated names for new static assets.

## Blog Writing & Privacy

Treat everything created under `_drafts/` and `_posts/` as publication-ready source because files committed to this public repository remain visible even when Jekyll does not render drafts. Never include personal usernames, real home-directory paths, hostnames, email addresses, account identifiers, Codex session IDs, credentials, tokens, or other machine-specific identifiers in blog content, front matter, code samples, screenshots, image metadata, or captions.

Generalize local details while preserving the technical meaning. Write `~`, `$HOME`, `<username>`, `<host>`, or another clearly marked placeholder instead of a real value. Replace absolute paths such as `/home/<username>/project` with `~/project` whenever the path is relative to the user's home directory. Commands and outputs copied from terminals or local session logs must be reviewed and redacted before they enter a draft.

Base technical narratives on verified commands, outputs, and observed results. Do not present suggested commands as commands that were actually run, and keep uncertain or externally performed steps explicitly qualified. Before submitting a draft or post, search the changed content for personal names, `/home/` paths, hostnames, email addresses, secrets, and session identifiers, then run `bundle exec jekyll build --drafts`.

## Testing Guidelines

There is no automated unit-test suite or coverage target. Before submitting, run `bundle exec jekyll build` and inspect affected pages with `bundle exec jekyll serve`. Check navigation, responsive layout, image paths, Liquid rendering, and offline behavior when relevant. Treat build warnings and broken internal links as defects.

## Commit & Pull Request Guidelines

The short history uses concise, imperative summaries (for example, `Create resume.md`). Keep commits focused and describe the visible outcome. Pull requests should explain the motivation, list the pages or assets changed, and report local build results. Link related issues and include before/after screenshots for layout, styling, or responsive changes. Never commit credentials or analytics secrets; keep environment-specific values out of `_config.yml`.
