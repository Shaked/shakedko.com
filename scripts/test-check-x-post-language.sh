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
  date=$3
  xlink=$4
  mkdir -p "$(dirname -- "$file")"
  {
    printf '%s\n' '---'
    [ -z "$language" ] || printf 'lang: %s\n' "$language"
    printf 'date: %s\n' "$date"
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
write_post "$fixture_dir/_posts_en/2025-08-25-valid.md" '' '2025-08-25 08:06:27.562 +0000' 'https://x.com/example/status/1959890100285812805'
write_post "$fixture_dir/_posts_he/2025-11-08-valid.md" '' '2025-11-08 12:41:35.066 +0000' 'https://x.com/example/status/1987138427695804731'
run_validator

write_post "$fixture_dir/_posts_he/2025-08-25-duplicate.md" '' '2025-08-25 08:06:27.562 +0000' 'https://twitter.com/example/status/1959890100285812805/?ref_src=example#fragment'
expect_failure 'host, query, and fragment variants must not hide duplicate xlink values'
rm "$fixture_dir/_posts_he/2025-08-25-duplicate.md"

write_post "$fixture_dir/_posts_en/2025-11-08-mismatched-language.md" he '2025-11-08 12:41:35.066 +0000' 'https://x.com/example/status/1987138427695804731'
expect_failure 'explicit language must match the collection'
rm "$fixture_dir/_posts_en/2025-11-08-mismatched-language.md"

write_post "$fixture_dir/_posts_en/2025-08-25-wrong-date.md" '' '2025-08-25 08:06:27.561 +0000' 'https://x.com/example/status/1959890100285812805'
expect_failure 'same-day X post timestamps must match Snowflake milliseconds exactly'
rm "$fixture_dir/_posts_en/2025-08-25-wrong-date.md"

write_post "$fixture_dir/_posts_en/2025-08-25-leading-zero.md" '' '2025-08-25 08:06:27.562 +0000' 'https://x.com/example/status/01959890100285812805'
expect_failure 'leading-zero Snowflake IDs must be rejected'
rm "$fixture_dir/_posts_en/2025-08-25-leading-zero.md"

write_post "$fixture_dir/_posts_en/2025-08-25-overflow.md" '' '2025-08-25 08:06:27.562 +0000' 'https://x.com/example/status/18446744073709551616'
expect_failure 'Snowflake IDs above signed 64-bit range must be rejected'
