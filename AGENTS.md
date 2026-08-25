# Repository Guidelines

## Project Structure & Module Organization

This repository is a Jekyll-powered GitHub Pages blog. Site-wide settings live in `_config.yml`. Top-level pages such as `index.html`, `about.html`, and `tags.html` use templates from `_layouts/` and reusable fragments from `_includes/`. Draft and article content belongs in `_drafts/` and `_post/` respectively; preserve the existing directory names even though standard Jekyll projects commonly use `_posts/`. Theme source is split between `less/` and `js/`, while compiled CSS is committed under `css/`. Images and fonts belong in `img/` and `fonts/`. `sw.js` and `offline.html` provide offline behavior.

## Build, Test, and Development Commands

- `gem install jekyll jekyll-paginate` installs the dependencies used by CI.
- `jekyll serve` builds the site and serves it at `http://127.0.0.1:4000/`, rebuilding after edits.
- `jekyll serve --drafts` also includes unpublished content from `_drafts/`.
- `jekyll build` performs the production-style validation used by `.travis.yml`; generated output goes to ignored `_site/`.

`Gruntfile.js` describes legacy LESS compilation and JavaScript minification, but the required `package.json` is not present. Do not assume `grunt` works unless its dependency manifest is restored in the same change.

## Coding Style & Naming Conventions

Use two-space indentation in YAML, HTML/Liquid, JavaScript, and LESS, and keep Liquid expressions readable. Reuse variables and mixins from `less/variables.less` and `less/mixins.less` instead of duplicating theme values. Name article files `YYYY-MM-DD-short-title.md` and begin them with YAML front matter containing at least `layout`, `title`, `date`, and `tags`. Use lowercase, hyphenated names for new static assets.

## Testing Guidelines

There is no automated unit-test suite or coverage target. Before submitting, run `jekyll build` and inspect affected pages with `jekyll serve`. Check navigation, responsive layout, image paths, Liquid rendering, and offline behavior when relevant. Treat build warnings and broken internal links as defects.

## Commit & Pull Request Guidelines

The short history uses concise, imperative summaries (for example, `Create resume.md`). Keep commits focused and describe the visible outcome. Pull requests should explain the motivation, list the pages or assets changed, and report local build results. Link related issues and include before/after screenshots for layout, styling, or responsive changes. Never commit credentials or analytics secrets; keep environment-specific values out of `_config.yml`.
