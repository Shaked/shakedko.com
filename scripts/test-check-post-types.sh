#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
validator="$script_dir/check-post-types.sh"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/check-post-types.XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

make_fixture() {
  rm -rf "$fixture/work"
  mkdir -p "$fixture/work"
  cp -R "$root/_data" "$root/assets" "$root/_includes" "$root/_layouts" "$fixture/work/"
  cp "$root/_config.yml" "$fixture/work/_config.yml"
}

expect_failure() {
  description=$1
  if "$validator" "$fixture/work" "$fixture/no-site"; then
    printf 'expected validation failure: %s\n' "$description" >&2
    exit 1
  fi
}

"$validator" "$root" "$root/_site"

make_fixture
printf '%s\n' '' 'experimental:' '  label: Experimental' '  icon: experimental.svg' >> "$fixture/work/_data/post_types.yml"
cp "$fixture/work/assets/icons/post-types/featured.svg" "$fixture/work/assets/icons/post-types/experimental.svg"
"$validator" "$fixture/work" "$fixture/no-site"

make_fixture
mv "$fixture/work/assets/icons/post-types/ai.svg" "$fixture/work/assets/icons/post-types/ai.svg.missing"
expect_failure 'a mapped icon must exist'

make_fixture
printf '%s\n' '<svg aria-hidden="true" focusable="false" onload="alert(1)"/>' > "$fixture/work/assets/icons/post-types/ai.svg"
expect_failure 'event-handler attributes in SVGs must be rejected'

make_fixture
awk '!/{% if post_type %}/' "$fixture/work/_includes/post-list.html" > "$fixture/list.tmp"
mv "$fixture/list.tmp" "$fixture/work/_includes/post-list.html"
expect_failure 'missing or unknown post types must be guarded by a fallback'

make_fixture
awk '!/<span>{{ post_type.label/' "$fixture/work/_layouts/post.html" > "$fixture/post.tmp"
mv "$fixture/post.tmp" "$fixture/work/_layouts/post.html"
expect_failure 'visible post type labels must remain available'

make_fixture
awk '{ gsub(/inset-inline-start/, "right"); print }' "$fixture/work/assets/css/style.scss" > "$fixture/style.tmp"
mv "$fixture/style.tmp" "$fixture/work/assets/css/style.scss"
expect_failure 'RTL-safe logical placement must not regress'

make_fixture
awk '{ print; if ($0 ~ /<aside class="post-tags"/) print "    Tags: 📌" }' "$fixture/work/_layouts/post.html" > "$fixture/post.tmp"
mv "$fixture/post.tmp" "$fixture/work/_layouts/post.html"
expect_failure 'tags must stay label-free and emoji-free'
