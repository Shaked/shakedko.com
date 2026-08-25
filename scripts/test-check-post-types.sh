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
  mkdir -p "$fixture/work/he"
  cp "$root/he/index.html" "$fixture/work/he/index.html"
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
printf '%s\n' '' 'experimental:' '  label:' '    en: Experimental' '    he: ניסיוני' '  icon: experimental.svg' >> "$fixture/work/_data/post_types.yml"
cp "$fixture/work/assets/icons/post-types/featured.svg" "$fixture/work/assets/icons/post-types/experimental.svg"
"$validator" "$fixture/work" "$fixture/no-site"

make_fixture
awk '!/^    he: /' "$fixture/work/_data/post_types.yml" > "$fixture/mapping.tmp"
mv "$fixture/mapping.tmp" "$fixture/work/_data/post_types.yml"
expect_failure 'every configured post type needs a Hebrew label'

make_fixture
sed 's/    he: בינה מלאכותית/    he: בינה אחרת/' "$fixture/work/_data/post_types.yml" > "$fixture/mapping.tmp"
mv "$fixture/mapping.tmp" "$fixture/work/_data/post_types.yml"
expect_failure 'configured translations must retain their approved exact values'

make_fixture
sed 's/pinned_label="נעוץ"/pinned_label="מוצמד"/' "$fixture/work/he/index.html" > "$fixture/page.tmp"
mv "$fixture/page.tmp" "$fixture/work/he/index.html"
expect_failure 'Hebrew pinned posts must retain the exact נעוץ label'

make_fixture
mv "$fixture/work/assets/icons/post-types/ai.svg" "$fixture/work/assets/icons/post-types/ai.svg.missing"
expect_failure 'a mapped icon must exist'

make_fixture
printf '%s\n' '<svg aria-hidden="true" focusable="false" onload="alert(1)"/>' > "$fixture/work/assets/icons/post-types/ai.svg"
expect_failure 'event-handler attributes in SVGs must be rejected'

make_fixture
sed 's/post_type.label\[post.lang\]/post_type.label/' "$fixture/work/_includes/post-list.html" > "$fixture/list.tmp"
mv "$fixture/list.tmp" "$fixture/work/_includes/post-list.html"
expect_failure 'English scalar post-type renderer regression must be rejected'

make_fixture
awk '!/{% else %}/' "$fixture/work/_layouts/post.html" > "$fixture/post.tmp"
mv "$fixture/post.tmp" "$fixture/work/_layouts/post.html"
expect_failure 'unknown post types must keep a text-only fallback'

make_fixture
awk '{ print; if ($0 ~ /{% else %}/) print "          <img src=\"/assets/icons/post-types/unknown.svg\" alt=\"\">" }' "$fixture/work/_layouts/post.html" > "$fixture/post.tmp"
mv "$fixture/post.tmp" "$fixture/work/_layouts/post.html"
expect_failure 'unknown post types must not render a broken image'

make_fixture
awk '{ gsub(/inset-inline-start/, "right"); print }' "$fixture/work/assets/css/style.scss" > "$fixture/style.tmp"
mv "$fixture/style.tmp" "$fixture/work/assets/css/style.scss"
expect_failure 'RTL-safe logical placement must not regress'

make_fixture
awk '{ print; if ($0 ~ /<aside class="post-tags"/) print "    Tags: 📌" }' "$fixture/work/_layouts/post.html" > "$fixture/post.tmp"
mv "$fixture/post.tmp" "$fixture/work/_layouts/post.html"
expect_failure 'tags must stay label-free and emoji-free'

make_fixture
sed 's/}תגיות{% else %}Tags/}Tags{% else %}תגיות/' "$fixture/work/_layouts/post.html" > "$fixture/post.tmp"
mv "$fixture/post.tmp" "$fixture/work/_layouts/post.html"
expect_failure 'Hebrew post tag accessibility label must remain Hebrew'
