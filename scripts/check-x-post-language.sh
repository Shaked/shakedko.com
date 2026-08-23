#!/usr/bin/env sh
set -eu

config_file=${1:-_config.yml}
english_dir=${2:-_posts_en}
hebrew_dir=${3:-_posts_he}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

require_collection_default() {
  collection=$1
  language=$2

  awk -v collection="$collection" -v language="$language" '
    $0 ~ "type: \\\"" collection "\\\"" { in_scope = 1; next }
    in_scope && /^[[:space:]]*-[[:space:]]+scope:/ { in_scope = 0 }
    in_scope && $0 ~ "lang:[[:space:]]*\\\"" language "\\\"" { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$config_file" || fail "$collection must default to lang: $language."
}

read_front_matter_value() {
  key=$1
  file=$2

  awk -v key="$key" '
    NR == 1 && $0 == "---" { front_matter = 1; next }
    front_matter && $0 == "---" { exit }
    front_matter && $0 ~ "^[[:space:]]*" key ":[[:space:]]*" {
      line = $0
      sub("^[[:space:]]*" key ":[[:space:]]*", "", line)
      gsub(/^\"|\"$/, "", line)
      gsub(/^\047|\047$/, "", line)
      print line
      exit
    }
  ' "$file"
}

normalize_xlink() {
  printf '%s\n' "$1" | sed 's/[[:space:]]*$//; s/#.*$//; s:/*$::'
}

require_collection_default posts_en en
require_collection_default posts_he he

entries_file=$(mktemp "${TMPDIR:-/tmp}/check-x-post-language.XXXXXX")
trap 'rm -f "$entries_file"' EXIT HUP INT TERM

check_collection() {
  directory=$1
  expected_language=$2

  find "$directory" -type f \( -name '*.md' -o -name '*.markdown' \) -print | while IFS= read -r file; do
    xlink=$(read_front_matter_value xlink "$file")
    [ -n "$xlink" ] || continue

    declared_language=$(read_front_matter_value lang "$file")
    if [ -n "$declared_language" ] && [ "$declared_language" != "$expected_language" ]; then
      fail "$file: lang: $declared_language does not match $directory."
    fi

    normalized_xlink=$(normalize_xlink "$xlink")
    [ -n "$normalized_xlink" ] || fail "$file: xlink must not be empty after normalization."
    printf '%s\t%s\n' "$normalized_xlink" "$file" >> "$entries_file"
  done
}

check_collection "$english_dir" en
check_collection "$hebrew_dir" he

awk -F '\t' '
  {
    count[$1]++
    files[$1] = files[$1] (files[$1] ? ", " : "") $2
  }
  END {
    for (xlink in count) {
      if (count[xlink] > 1) {
        printf "duplicate normalized xlink %s: %s\\n", xlink, files[xlink] > "/dev/stderr"
        failed = 1
      }
    }
    exit(failed ? 1 : 0)
  }
' "$entries_file" || fail 'X-post language validation failed.'
