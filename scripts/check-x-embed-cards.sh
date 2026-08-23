#!/usr/bin/env sh
set -eu

include_file=${1:-_includes/post-list.html}
css_file=${2:-assets/css/style.scss}
site_dir=${3:-_site}

grep -q 'x-post-card' "$include_file"
grep -q 'data-width="550"' "$include_file"
grep -q 'class="x-post-fallback"' "$include_file"
grep -q 'target="_blank" rel="noopener noreferrer"' "$include_file"
! sed -n '/post.xlink/,/endunless/p' "$include_file" | grep -q 'onclick='

grep -q 'width: min(100%, 550px);' "$css_file"
grep -q 'margin-inline: auto;' "$css_file"
grep -q 'max-width: 100% !important;' "$css_file"

for page in "$site_dir/index.html" "$site_dir/he/index.html"; do
  grep -q 'x-post-card' "$page"
  grep -q 'x-post-fallback' "$page"
  ! sed -n '/x-post-card/,/<\/li>/p' "$page" | grep -q 'onclick='
done
