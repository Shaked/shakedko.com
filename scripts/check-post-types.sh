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
keys='featured ai security infrastructure development craft building thoughts'

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -f "$mapping" ] || fail 'post type mapping is missing.'
[ -f "$list" ] || fail 'post list template is missing.'
[ -f "$post_layout" ] || fail 'post layout is missing.'

for key in $keys; do
  grep -q "^$key:$" "$mapping" || fail "missing post type: $key"
  icon=$(awk -v key="$key" '$0 == key ":" { found = 1; next } found && /^  icon: / { sub(/^  icon: /, ""); print; exit }' "$mapping")
  [ -n "$icon" ] || fail "$key has no icon reference."
  [ -f "$icons/$icon" ] || fail "$key references a missing icon: $icon"
done

[ "$(grep -c '^[a-z].*:$' "$mapping")" -eq 8 ] || fail 'post type mapping must contain exactly the initial stable keys.'

for icon in "$icons"/*.svg; do
  [ -f "$icon" ] || fail 'post type icons are missing.'
  grep -q '<svg ' "$icon" || fail "$icon is not an SVG."
  grep -q 'aria-hidden="true"' "$icon" || fail "$icon must be decorative."
  grep -q 'focusable="false"' "$icon" || fail "$icon must not be focusable."
  if grep -Eqi '<script|<foreignObject|<image|<use|[[:space:]](href|xlink:href)=|url\(|javascript:' "$icon"; then
    fail "$icon contains an unsafe script or external reference."
  fi
done

grep -q 'site.data.post_types\[post.post_type\]' "$list" || fail 'list marker does not use the central mapping.'
grep -q 'site.data.post_types\[page.post_type\]' "$post_layout" || fail 'post marker does not use the central mapping.'
grep -q '{% if post_type %}' "$list" || fail 'list marker must gracefully hide unknown post types.'
grep -q '{% if post_type %}' "$post_layout" || fail 'post marker must gracefully hide unknown post types.'
grep -q 'aria-hidden="true"' "$list" || fail 'list marker icon must be decorative.'
grep -q 'aria-hidden="true"' "$post_layout" || fail 'post marker icon must be decorative.'
grep -q 'margin-block-end' "$styles" || fail 'post type marker must use logical RTL-safe spacing.'
grep -q 'border-radius: 999px' "$styles" || fail 'tags must render as pills.'
grep -q 'background-color: var(--color-surface)' "$styles" || fail 'tag pills must use the white surface.'
grep -q 'post_type: "thoughts"' "$config" || fail 'collections must default to thoughts.'
! grep -q 'Tags:' "$post_layout" || fail 'tag label must not be rendered.'
! awk '/^\.post-type \{/,/^\}/ { print }' "$styles" | grep -Eq 'margin-(left|right)|border-(left|right)' || fail 'post type marker must remain RTL-safe.'

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
fi
