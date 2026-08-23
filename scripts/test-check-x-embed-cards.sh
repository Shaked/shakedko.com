#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
validator="$script_dir/check-x-embed-cards.sh"
fixture_dir=$(mktemp -d "${TMPDIR:-/tmp}/check-x-embed-cards.XXXXXX")
trap 'rm -rf "$fixture_dir"' EXIT HUP INT TERM

mkdir -p "$fixture_dir/_posts_en" "$fixture_dir/_posts_he" "$fixture_dir/_site/he" "$fixture_dir/assets"
printf '%s\n' \
  '<li class="x-post-card" data-width="550">' \
  '  <a href="https://x.com/example/status/1"></a>' \
  '  <a class="x-post-fallback" href="https://x.com/example/status/1" target="_blank" rel="noopener noreferrer">View the original post on X</a>' \
  '</li>' > "$fixture_dir/include.html"
printf '%s\n' \
  '.x-post-card { width: min(100%, 550px); margin-inline: auto; }' \
  '.x-post-card iframe { max-width: 100% !important; }' > "$fixture_dir/style.scss"
printf '%s\n' \
  '---' \
  'xlink: https://x.com/example/status/1' \
  '---' > "$fixture_dir/_posts_en/post.md"
cp "$fixture_dir/include.html" "$fixture_dir/_site/index.html"
: > "$fixture_dir/_site/he/index.html"

run_validator() {
  "$validator" "$fixture_dir/include.html" "$fixture_dir/style.scss" "$fixture_dir/_site" "$fixture_dir/_posts_en" "$fixture_dir/_posts_he"
}

expect_failure() {
  description=$1
  if run_validator; then
    printf 'expected validation failure: %s\n' "$description" >&2
    exit 1
  fi
}

run_validator
: > "$fixture_dir/_site/index.html"
expect_failure 'removing all generated cards must fail'
