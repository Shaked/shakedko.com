#!/usr/bin/env sh
set -eu

root=${1:-.}
site_dir=${2:-$root/_site}
mapping="$root/_data/post_types.yml"
icons="$root/assets/icons/post-types"
list="$root/_includes/post-list.html"
post_layout="$root/_layouts/post.html"
styles="$root/assets/css/style.scss"
config="$root/_config.yml"
required_keys='featured ai security infrastructure development craft building thoughts'

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -f "$mapping" ] || fail 'post type mapping is missing.'
[ -f "$list" ] || fail 'post list template is missing.'
[ -f "$post_layout" ] || fail 'post layout is missing.'

entries=$(mktemp "${TMPDIR:-/tmp}/post-types-entries.XXXXXX")
trap 'rm -f "$entries"' EXIT HUP INT TERM

awk '
  function finish() {
    if (key == "") return
    if (label == "" || icon == "") {
      printf "%s is missing a label or icon.\n", key > "/dev/stderr"
      failed = 1
    } else {
      print key "\t" label "\t" icon
    }
  }
  /^[a-z][a-z0-9_-]*:$/ {
    finish()
    key = substr($0, 1, length($0) - 1)
    label = ""
    icon = ""
    next
  }
  key != "" && /^  label: [^[:space:]]/ {
    label = $0
    sub(/^  label: /, "", label)
    next
  }
  key != "" && /^  icon: [a-z0-9_-]+\.svg$/ {
    icon = $0
    sub(/^  icon: /, "", icon)
  }
  END { finish(); exit(failed ? 1 : 0) }
' "$mapping" > "$entries" || fail 'post type mapping entries must have a label and a local SVG icon.'

for key in $required_keys; do
  awk -F '\t' -v key="$key" '$1 == key { found = 1 } END { exit(found ? 0 : 1) }' "$entries" || fail "missing required post type: $key"
done

while IFS="$(printf '\t')" read -r key label icon; do
  [ -n "$key" ] && [ -n "$label" ] && [ -n "$icon" ] || fail 'post type mapping contains an invalid entry.'
  [ -f "$icons/$icon" ] || fail "$key references a missing icon: $icon"
done < "$entries"

for icon in "$icons"/*.svg; do
  [ -f "$icon" ] || fail 'post type icons are missing.'
  grep -q '<svg ' "$icon" || fail "$icon is not an SVG."
  grep -q 'aria-hidden="true"' "$icon" || fail "$icon must be decorative."
  grep -q 'focusable="false"' "$icon" || fail "$icon must not be focusable."
  if grep -Eqi '<script|<foreignObject|<(image|use|iframe|object|embed|audio|video|canvas|link|meta|base|style)|[[:space:]]on[a-z0-9:_-]*[[:space:]]*=|[[:space:]](href|src|xlink:href)[[:space:]]*=|url\(|javascript:|data:' "$icon"; then
    fail "$icon contains an executable or external reference."
  fi
done

marker_contract() {
  template=$1
  marker=$2
  grep -q "site.data.post_types\[$marker.post_type\]" "$template" || fail "$template does not use the central mapping."
  grep -q '{% if post_type %}' "$template" || fail "$template must hide missing or unknown post types."
  awk '
    /<div class="post-type">/ { in_marker = 1 }
    in_marker { block = block $0 "\n" }
    in_marker && /<\/div>/ { found = 1; in_marker = 0 }
    END { if (!found || block !~ /<img[^>]*alt=""[^>]*aria-hidden="true"/ || block !~ /<span>[^<]*post_type.label[^<]*<\/span>/) exit 1 }
  ' "$template" || fail "$template must keep a decorative icon and visible type label."
}

marker_contract "$list" post
marker_contract "$post_layout" page
post_type_block=$(awk '/^\.post-type \{/,/^\}/ { print }' "$styles")
printf '%s\n' "$post_type_block" | grep -q 'position: absolute;' || fail 'post type marker must sit in the card corner.'
printf '%s\n' "$post_type_block" | grep -q 'inset-block-start:' || fail 'post type marker must use logical vertical placement.'
printf '%s\n' "$post_type_block" | grep -q 'inset-inline-start:' || fail 'post type marker must mirror in RTL.'
! printf '%s\n' "$post_type_block" | grep -Eq '(top|left|right):' || fail 'post type marker must remain RTL-safe.'
grep -q 'padding-block-start: 52px;' "$styles" || fail 'standard cards must reserve space for the corner marker.'
grep -q 'padding-block-start: 42px;' "$styles" || fail 'X cards must reserve space for the corner marker.'
badge_block=$(awk '/^\.post-badge \{/,/^\}/ { print }' "$styles")
printf '%s\n' "$badge_block" | grep -q 'inset-inline-end:' || fail 'pinned badges must coexist on the opposite logical corner.'
grep -q 'border-radius: 999px' "$styles" || fail 'tags must render as pills.'
grep -q 'background-color: var(--color-surface)' "$styles" || fail 'tag pills must use the white surface.'
grep -q 'post_type: "thoughts"' "$config" || fail 'collections must default to thoughts.'
awk '
  /<div class="post-content"/ { content = 1 }
  content && /<\/div>/ { content_done = 1; next }
  content_done && /<aside class="post-tags"/ { tags_after_content = 1 }
  END { exit(tags_after_content ? 0 : 1) }
' "$post_layout" || fail 'tags must remain below article content.'
! grep -Eq 'Tags:|[📌🏷️#]' "$post_layout" || fail 'tag rendering must not include a label or emoji.'

if [ -d "$site_dir" ]; then
  english_page="$site_dir/2013/11/23/tinder-privacy-issues/index.html"
  hebrew_page="$site_dir/מעצמת-הסייבר-וקופות-החולים/index.html"
  [ -f "$english_page" ] || fail 'generated English post page is missing.'
  [ -f "$hebrew_page" ] || fail 'generated Hebrew post page is missing.'
  grep -q 'assets/icons/post-types/featured.svg' "$english_page" || fail 'known English post type did not render.'
  grep -q '<span>Featured</span>' "$english_page" || fail 'known English post type has no accessible text.'
  grep -q 'class="post-tags"' "$english_page" || fail 'generated tags are missing.'
  ! grep -q '>Tags:' "$english_page" || fail 'generated tags must not include a label or emoji.'
  grep -q 'dir="rtl"' "$hebrew_page" || fail 'generated Hebrew post must remain RTL.'
  grep -q 'assets/icons/post-types/security.svg' "$hebrew_page" || fail 'known Hebrew post type did not render.'
  grep -q 'class="post-item.*x-post-card"' "$site_dir/he/index.html" || fail 'generated Hebrew X card is missing.'
fi
