#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <paper title, arXiv URL, or ID> <output-root>" >&2
  exit 2
}

[[ $# -eq 2 ]] || usage

input=$1
output_root=$2
identifier=${input#*arxiv.org/}
identifier=${identifier#abs/}
identifier=${identifier#html/}
identifier=${identifier#pdf/}
identifier=${identifier#e-print/}
identifier=${identifier%%\?*}
identifier=${identifier%%\#*}
identifier=${identifier%.pdf}

if [[ ! $identifier =~ ^([0-9]{4}\.[0-9]{4,5}|[a-zA-Z.-]+/[0-9]{7})(v[0-9]+)?$ ]]; then
  if [[ $input == *arxiv.org/* ]]; then
    echo "Invalid arXiv URL: $input" >&2
    exit 2
  fi

  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  search_tmp=$(mktemp)
  trap 'rm -f "$search_tmp"' EXIT
  if ! curl --http1.1 --fail --location --retry 3 --get \
    --user-agent "arxiv-paper-fetcher/1.0" \
    --data-urlencode "search_query=ti:\"$input\"" \
    --data-urlencode "start=0" \
    --data-urlencode "max_results=10" \
    https://export.arxiv.org/api/query -o "$search_tmp"; then
    echo "Could not search arXiv for title: $input" >&2
    exit 1
  fi
  identifier=$(python3 "$script_dir/resolve_title.py" "$input" "$search_tmp") || {
    status=$?
    exit "$status"
  }
  echo "resolved_id=$identifier"
fi

safe_identifier=${identifier//\//_}
paper_dir="$output_root/$safe_identifier"
mkdir -p "$paper_dir"

download() {
  curl --http1.1 --fail --location --retry 3 \
    --user-agent "arxiv-paper-fetcher/1.0" "$1" -o "$2"
}

html_tmp="$paper_dir/.paper.html.part"
if download "https://arxiv.org/html/$identifier" "$html_tmp"; then
  if grep -Eq '<article[^>]+class="[^"]*ltx_document' "$html_tmp"; then
    mv "$html_tmp" "$paper_dir/arxiv-original.html"
    cp "$paper_dir/arxiv-original.html" "$paper_dir/paper.html"
    perl -0pi -e 's/\A.*?(<article\b.*?<\/article>).*\z/<!doctype html>\n<html lang="en">\n<head><meta charset="utf-8"><title>arXiv paper<\/title><\/head>\n<body>\n$1\n<\/body>\n<\/html>\n/s or die "article element not found\n"' "$paper_dir/paper.html"
    echo "format=html"
    echo "paper=$paper_dir/paper.html"
    echo "original=$paper_dir/arxiv-original.html"
    exit 0
  fi
fi
rm -f "$html_tmp"

source_tmp="$paper_dir/.source.part"
if download "https://export.arxiv.org/e-print/$identifier" "$source_tmp"; then
  if tar -tf "$source_tmp" >/dev/null 2>&1 \
    && ! tar -tf "$source_tmp" | awk '/^\// || /(^|\/)\.\.($|\/)/ { bad=1 } END { exit !bad }'; then
    mkdir -p "$paper_dir/latex"
    tar -xf "$source_tmp" -C "$paper_dir/latex"
    if find "$paper_dir/latex" -type f -name '*.tex' -size +0c -print -quit | grep -q .; then
      mv "$source_tmp" "$paper_dir/source.tar.gz"
      echo "format=latex"
      echo "source=$paper_dir/latex"
      echo "archive=$paper_dir/source.tar.gz"
      exit 0
    fi
  fi
fi
rm -f "$source_tmp"

pdf_tmp="$paper_dir/.paper.pdf.part"
if download "https://arxiv.org/pdf/$identifier" "$pdf_tmp" \
  && head -c 5 "$pdf_tmp" | grep -q '^%PDF-'; then
  mv "$pdf_tmp" "$paper_dir/paper.pdf"
  echo "format=pdf"
  echo "paper=$paper_dir/paper.pdf"
  exit 0
fi
rm -f "$pdf_tmp"

echo "No usable HTML, LaTeX source, or PDF was available for $identifier" >&2
exit 1
