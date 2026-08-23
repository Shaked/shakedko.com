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

snowflake_utc_day() {
  status_id=$1
  printf '%s\n' "$status_id" | awk '
    /^[0-9]+$/ {
      divisor = 4194304
      remainder = 0
      quotient = ""
      for (digit_index = 1; digit_index <= length($0); digit_index++) {
        value = remainder * 10 + substr($0, digit_index, 1)
        digit = int(value / divisor)
        remainder = value % divisor
        if (quotient != "" || digit != 0) quotient = quotient digit
      }
      milliseconds = quotient + 1288834974657
      days = int(milliseconds / 86400000)
      z = days + 719468
      era = z >= 0 ? int(z / 146097) : int((z - 146096) / 146097)
      doe = z - era * 146097
      yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
      year = yoe + era * 400
      doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
      month_part = int((5 * doy + 2) / 153)
      day = doy - int((153 * month_part + 2) / 5) + 1
      month = month_part + (month_part < 10 ? 3 : -9)
      year += month <= 2
      printf "%04d-%02d-%02d\n", year, month, day
      exit
    }
  '
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
        expected_day=$(snowflake_utc_day "$status_id")
        [ -n "$expected_day" ] || fail "$file: X status ID must be numeric."
        front_matter_date=$(read_front_matter_value date "$file")
        declared_day=$(printf '%s' "$front_matter_date" | cut -c 1-10)
        filename_day=$(basename "$file" | cut -c 1-10)
        [ "$declared_day" = "$expected_day" ] || fail "$file: date day $declared_day does not match X status UTC day $expected_day."
        [ "$filename_day" = "$expected_day" ] || fail "$file: filename day $filename_day does not match X status UTC day $expected_day."
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
