#!/usr/bin/env sh
set -eu

include_file=${1:-_includes/post-list.html}
css_file=${2:-assets/css/style.scss}
site_dir=${3:-_site}
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
if grep -Eq '{% if post\.xlink %}[^[:cntrl:]]*onclick=' "$include_file"; then
  fail 'X cards must not have an inline click handler.'
fi

grep -q 'width: min(100%, 550px);' "$css_file"
grep -q 'margin-inline: auto;' "$css_file"
grep -q 'max-width: 100% !important;' "$css_file"

check_page() {
  page=$1
  expected_label=$2

  awk -v page="$page" -v expected_label="$expected_label" '
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
      if (cards == 0 || in_card || failed) {
        exit 1
      }
    }
  ' "$page" || fail "X card validation failed for $page"
}

check_page "$site_dir/index.html" "$english_label"
check_page "$site_dir/he/index.html" "$hebrew_label"
