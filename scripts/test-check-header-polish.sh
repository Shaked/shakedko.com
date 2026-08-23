#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
validator="$script_dir/check-header-polish.sh"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/check-header-polish.XXXXXX")
trap 'rm -rf "$fixture"' EXIT

make_fixture() {
  rm -rf "$fixture/work"
  mkdir -p "$fixture/work/assets/css" "$fixture/work/_includes" "$fixture/work/_site/assets/css"
  cp "$root/assets/css/style.scss" "$fixture/work/assets/css/style.scss"
  cp "$root/_includes/header.html" "$fixture/work/_includes/header.html"
  cp "$root/_site/assets/css/style.css" "$fixture/work/_site/assets/css/style.css"
}

expect_failure() {
  if "$validator" "$fixture/work" "$fixture/work/_site"; then
    printf 'expected failure: %s\n' "$1" >&2
    exit 1
  fi
}

make_fixture
"$validator" "$fixture/work" "$fixture/work/_site"

make_fixture
sed 's/inset-inline-start: auto;/right: 15px;/' "$fixture/work/assets/css/style.scss" > "$fixture/style.tmp"
mv "$fixture/style.tmp" "$fixture/work/assets/css/style.scss"
expect_failure 'RTL geometry must reject a physical right inset'

make_fixture
sed 's/isolation: isolate;//' "$fixture/work/assets/css/style.scss" > "$fixture/style.tmp"
mv "$fixture/style.tmp" "$fixture/work/assets/css/style.scss"
expect_failure 'header must remain isolated above embeds'

make_fixture
sed 's/aria-label="Primary navigation"//' "$fixture/work/_includes/header.html" > "$fixture/header.tmp"
mv "$fixture/header.tmp" "$fixture/work/_includes/header.html"
expect_failure 'navigation landmark must retain its accessible name'

make_fixture
sed 's/padding-block-end: 240px;/padding-block-end: 0;/' "$fixture/work/assets/css/style.scss" > "$fixture/style.tmp"
mv "$fixture/style.tmp" "$fixture/work/assets/css/style.scss"
expect_failure 'expanded mobile menu must reserve its compact panel height'
