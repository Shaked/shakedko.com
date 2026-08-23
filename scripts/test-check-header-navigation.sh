#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
validator="$script_dir/check-header-navigation.sh"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/check-header-navigation.XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

make_fixture() {
  rm -rf "$fixture/work"
  mkdir -p "$fixture/work/_includes" "$fixture/work/_site/he"
  cp "$root/_config.yml" "$fixture/work/_config.yml"
  cp "$root/_includes/header.html" "$fixture/work/_includes/header.html"
  cp "$root/_site/index.html" "$fixture/work/_site/index.html"
  cp "$root/_site/he/index.html" "$fixture/work/_site/he/index.html"
  cp -R "$root/_site/archive" "$fixture/work/_site/archive"
  cp -R "$root/_site/he/archive" "$fixture/work/_site/he/archive"
}

expect_failure() {
  description=$1
  if "$validator" "$fixture/work" "$fixture/work/_site"; then
    printf 'expected validation failure: %s\n' "$description" >&2
    exit 1
  fi
}

"$validator" "$root" "$root/_site"

make_fixture
sed 's#https://il.linkedin.com/in/shakedklein#https://www.linkedin.com/in/guessed-profile#' "$fixture/work/_config.yml" > "$fixture/config.tmp"
mv "$fixture/config.tmp" "$fixture/work/_config.yml"
expect_failure 'the configured LinkedIn URL must be authoritative'

make_fixture
sed 's#href="{{ "/archive/" | relative_url }}"#href="{{ "/about/" | relative_url }}"#' "$fixture/work/_includes/header.html" > "$fixture/header.tmp"
mv "$fixture/header.tmp" "$fixture/work/_includes/header.html"
expect_failure 'About must not return to source navigation'

make_fixture
sed 's/rel="noopener noreferrer"//' "$fixture/work/_includes/header.html" > "$fixture/header.tmp"
mv "$fixture/header.tmp" "$fixture/work/_includes/header.html"
expect_failure 'external social links need safe rel attributes'

make_fixture
sed 's#https://il.linkedin.com/in/shakedklein#https://il.linkedin.com/in/wrong#' "$fixture/work/_site/he/index.html" > "$fixture/page.tmp"
mv "$fixture/page.tmp" "$fixture/work/_site/he/index.html"
expect_failure 'generated Hebrew navigation destinations must remain exact'
