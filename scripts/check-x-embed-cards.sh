#!/usr/bin/env sh
set -eu

include_file=${1:-_includes/post-list.html}
css_file=${2:-assets/css/style.scss}
site_dir=${3:-_site}
english_dir=${4:-_posts_en}
hebrew_dir=${5:-_posts_he}
english_label='View the original post on X'
hebrew_label='לצפייה בפוסט המקורי ב-X'

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

grep -q 'x-post-card' "$include_file"
grep -q 'data-width="550"' "$include_file"
grep -q 'class="x-post-fallback"' "$include_file"
grep -q 'target="_blank" rel="noopener noreferrer"' "$include_file"
awk '
  /^[[:space:]]*<li[[:space:]]/ {
    in_tag = 1
    tag = $0 "\n"
    if ($0 ~ />/) {
      if (tag ~ /x-post-card/ && tag ~ /onclick[[:space:]]*=/) {
        print "X cards must not have an inline click handler." > "/dev/stderr"
        in_tag = 0
        exit 1
      }
      in_tag = 0
      tag = ""
    }
    next
  }

  in_tag {
    tag = tag $0 "\n"
  }

  in_tag && />/ {
    if (tag ~ /x-post-card/ && tag ~ /onclick[[:space:]]*=/) {
      print "X cards must not have an inline click handler." > "/dev/stderr"
      in_tag = 0
      exit 1
    }
    in_tag = 0
    tag = ""
  }

  END {
    if (in_tag) {
      print "Unterminated list-item tag." > "/dev/stderr"
      exit 1
    }
  }
' "$include_file" || fail 'X card source validation failed.'

grep -q 'width: min(100%, 550px);' "$css_file"
grep -q 'margin-inline: auto;' "$css_file"
grep -q 'max-width: 100% !important;' "$css_file"

check_page() {
  page=$1
  expected_label=$2
  expected_cards=$3

  awk -v page="$page" -v expected_label="$expected_label" -v expected_cards="$expected_cards" '
    BEGIN { cards = 0 }
    /<li[^>]*x-post-card/ {
      if (in_card) {
        print page ": nested X card" > "/dev/stderr"
        failed = 1
      }
      in_card = 1
      cards++
      fallbacks = 0
    }

    in_card && /onclick=/ {
      print page ": X card has an inline click handler" > "/dev/stderr"
      failed = 1
    }

    in_card && /class="x-post-fallback"/ {
      fallbacks++
      if ($0 !~ /href="[^"]+"/ || $0 !~ /target="_blank"/ || $0 !~ /rel="noopener noreferrer"/ || index($0, expected_label) == 0) {
        print page ": X fallback is missing required link semantics or localized text" > "/dev/stderr"
        failed = 1
      }
    }

    in_card && /<\/li>/ {
      if (fallbacks != 1) {
        print page ": each X card needs exactly one fallback link" > "/dev/stderr"
        failed = 1
      }
      in_card = 0
    }

    END {
      if (cards != expected_cards || in_card || failed) {
        if (cards != expected_cards) {
          print page ": expected " expected_cards " X cards but found " cards > "/dev/stderr"
        }
        exit 1
      }
    }
  ' "$page" || fail "X card validation failed for $page."
}

collect_xlinks() {
  directory=$1
  output_file=$2
  files_file=$3

  find "$directory" -type f \( -name '*.md' -o -name '*.markdown' \) -print > "$files_file"
  while IFS= read -r file; do
    awk '
      NR == 1 && $0 == "---" { front_matter = 1; next }
      front_matter && $0 == "---" { exit }
      front_matter && /^[[:space:]]*xlink:[[:space:]]*/ {
        xlink = $0
        sub(/^[[:space:]]*xlink:[[:space:]]*/, "", xlink)
        gsub(/^\"|\"$/, "", xlink)
        print xlink
        exit
      }
    ' "$file" >> "$output_file"
  done < "$files_file"
}

english_xlinks=$(mktemp "${TMPDIR:-/tmp}/check-x-embed-cards.XXXXXX")
hebrew_xlinks=$(mktemp "${TMPDIR:-/tmp}/check-x-embed-cards.XXXXXX")
files_file=$(mktemp "${TMPDIR:-/tmp}/check-x-embed-cards.XXXXXX")
trap 'rm -f "$english_xlinks" "$hebrew_xlinks" "$files_file"' EXIT HUP INT TERM

collect_xlinks "$english_dir" "$english_xlinks" "$files_file"
collect_xlinks "$hebrew_dir" "$hebrew_xlinks" "$files_file"

count_cards() {
  wc -l < "$1" | tr -d '[:space:]'
}

require_generated_xlinks() {
  page=$1
  xlinks_file=$2

  while IFS= read -r xlink; do
    matches=$(grep -F "href=\"$xlink\"" "$page" | wc -l | tr -d '[:space:]')
    [ "$matches" -eq 2 ] || fail "$page: expected one generated X card and fallback for $xlink."
  done < "$xlinks_file"
}

english_cards=$(count_cards "$english_xlinks")
hebrew_cards=$(count_cards "$hebrew_xlinks")
check_page "$site_dir/index.html" "$english_label" "$english_cards"
check_page "$site_dir/he/index.html" "$hebrew_label" "$hebrew_cards"
require_generated_xlinks "$site_dir/index.html" "$english_xlinks"
require_generated_xlinks "$site_dir/he/index.html" "$hebrew_xlinks"
