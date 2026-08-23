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
  printf '%s\n' "$1" | awk '
    {
      url = $0
      sub(/[[:space:]]+$/, "", url)
      sub(/[?#].*$/, "", url)
      sub(/\/+$/, "", url)

      if (url ~ /^https?:\/\/(www\.)?(x\.com|twitter\.com)\/[^\/]+\/status\/[0-9]+$/) {
        segments = split(url, path, "/")
        print "x-status:" path[segments]
      } else {
        print url
      }
    }
  '
}

validate_snowflake_timestamp() {
  ruby - "$1" "$2" "$3" <<'RUBY'
status_id, front_matter_date, filename_day = ARGV
abort 'X status ID must be canonical decimal and nonzero.' unless status_id.match?(/\A[1-9]\d*\z/)
id = Integer(status_id, 10)
abort 'X status ID exceeds the signed 64-bit range.' if id > 9_223_372_036_854_775_807
milliseconds = (id >> 22) + 1_288_834_974_657
seconds, milliseconds_part = milliseconds.divmod(1_000)
utc = Time.at(seconds).utc
expected = "#{utc.strftime('%Y-%m-%d %H:%M:%S')}.#{format('%03d', milliseconds_part)} +0000"
abort "date must equal canonical Snowflake timestamp #{expected}." unless front_matter_date == expected
abort "filename day must match Snowflake UTC day #{utc.strftime('%Y-%m-%d')}." unless filename_day == utc.strftime('%Y-%m-%d')
RUBY
}

require_collection_default posts_en en
require_collection_default posts_he he

entries_file=$(mktemp "${TMPDIR:-/tmp}/check-x-post-language.XXXXXX")
files_file=$(mktemp "${TMPDIR:-/tmp}/check-x-post-language.XXXXXX")
trap 'rm -f "$entries_file" "$files_file"' EXIT HUP INT TERM

check_collection() {
  directory=$1
  expected_language=$2

  find "$directory" -type f \( -name '*.md' -o -name '*.markdown' \) -print > "$files_file"
  while IFS= read -r file; do
    xlink=$(read_front_matter_value xlink "$file")
    [ -n "$xlink" ] || continue

    declared_language=$(read_front_matter_value lang "$file")
    if [ -n "$declared_language" ] && [ "$declared_language" != "$expected_language" ]; then
      fail "$file: lang: $declared_language does not match $directory."
    fi

    normalized_xlink=$(normalize_xlink "$xlink")
    [ -n "$normalized_xlink" ] || fail "$file: xlink must not be empty after normalization."
    case "$normalized_xlink" in
      x-status:*)
        status_id=${normalized_xlink#x-status:}
        front_matter_date=$(read_front_matter_value date "$file")
        filename_day=$(basename "$file" | cut -c 1-10)
        validate_snowflake_timestamp "$status_id" "$front_matter_date" "$filename_day" || fail "$file: X Snowflake timestamp validation failed."
        ;;
    esac
    printf '%s\t%s\n' "$normalized_xlink" "$file" >> "$entries_file"
  done < "$files_file"
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
