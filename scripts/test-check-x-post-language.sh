#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
validator="$script_dir/check-x-post-language.sh"
fixture_dir=$(mktemp -d "${TMPDIR:-/tmp}/check-x-post-language.XXXXXX")
trap 'rm -rf "$fixture_dir"' EXIT HUP INT TERM

write_config() {
  printf '%s\n' \
    'defaults:' \
    '  - scope:' \
    '      path: ""' \
    '      type: "posts_en"' \
    '    values:' \
    '      lang: "en"' \
    '  - scope:' \
    '      path: ""' \
    '      type: "posts_he"' \
    '    values:' \
    '      lang: "he"' > "$fixture_dir/_config.yml"
}

write_post() {
  file=$1
  language=$2
  xlink=$3
  mkdir -p "$(dirname -- "$file")"
  {
    printf '%s\n' '---'
    [ -z "$language" ] || printf 'lang: %s\n' "$language"
    printf 'xlink: %s\n' "$xlink"
    printf '%s\n' '---'
  } > "$file"
}

run_validator() {
  "$validator" "$fixture_dir/_config.yml" "$fixture_dir/_posts_en" "$fixture_dir/_posts_he"
}

expect_failure() {
  description=$1
  if run_validator; then
    printf 'expected validation failure: %s\n' "$description" >&2
    exit 1
  fi
}

mkdir -p "$fixture_dir/_posts_en" "$fixture_dir/_posts_he"
write_config
write_post "$fixture_dir/_posts_en/valid.md" '' 'https://x.com/example/status/1'
write_post "$fixture_dir/_posts_he/valid.md" '' 'https://x.com/example/status/2'
run_validator

write_post "$fixture_dir/_posts_he/duplicate.md" '' 'https://x.com/example/status/1#fragment'
expect_failure 'fragments must not hide duplicate xlink values'
rm "$fixture_dir/_posts_he/duplicate.md"

write_post "$fixture_dir/_posts_en/mismatched-language.md" he 'https://x.com/example/status/3'
expect_failure 'explicit language must match the collection'
