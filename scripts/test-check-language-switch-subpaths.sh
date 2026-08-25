#!/usr/bin/env sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
validator="$script_dir/check-language-switch-subpaths.sh"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/switch-subpaths.XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
make_fixture() {
  rm -rf "$fixture/work"; mkdir -p "$fixture/work/he/archive" "$fixture/work/archive" "$fixture/work/_site/he/archive" "$fixture/work/_site/archive" "$fixture/work/_site/he"
  for page in he/index.html archive/index.html he/archive/index.html; do
    cp "$root/$page" "$fixture/work/$page"; cp "$root/_site/$page" "$fixture/work/_site/$page"
  done
}
expect_failure() { if "$validator" "$fixture/work" "$fixture/work/_site" /shakedko; then printf 'expected failure: %s\n' "$1" >&2; exit 1; fi; }
"$validator" "$root" "$root/_site" /shakedko
for page in he/index.html archive/index.html he/archive/index.html; do
  make_fixture
  sed 's/relative_url/absolute_url/' "$fixture/work/$page" > "$fixture/mutated"; mv "$fixture/mutated" "$fixture/work/$page"
  expect_failure "$page source link must remain subpath safe"
  make_fixture
  sed 's#/shakedko/#/#' "$fixture/work/_site/$page" > "$fixture/mutated"; mv "$fixture/mutated" "$fixture/work/_site/$page"
  expect_failure "$page generated link must retain the subpath"
done
