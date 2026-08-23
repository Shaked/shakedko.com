#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)

"$script_dir/check-post-types.sh" "$root"

fixture=$(mktemp -d "${TMPDIR:-/tmp}/check-post-types.XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/_data" "$fixture/assets/icons/post-types" "$fixture/_includes" "$fixture/_layouts" "$fixture/assets/css"
cp "$root/_data/post_types.yml" "$fixture/_data/post_types.yml"
cp "$root/assets/icons/post-types/featured.svg" "$fixture/assets/icons/post-types/featured.svg"
cp "$root/_includes/post-list.html" "$fixture/_includes/post-list.html"
cp "$root/_layouts/post.html" "$fixture/_layouts/post.html"
cp "$root/assets/css/style.scss" "$fixture/assets/css/style.scss"
cp "$root/_config.yml" "$fixture/_config.yml"

if "$script_dir/check-post-types.sh" "$fixture"; then
  printf '%s\n' 'expected missing mapped icon validation failure.' >&2
  exit 1
fi
