#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
validator="$script_dir/check-language-feeds.sh"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/check-language-feeds.XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

expect_failure() {
  description=$1
  if "$validator" "$root" "$fixture/site"; then
    printf 'expected validation failure: %s\n' "$description" >&2
    exit 1
  fi
}

cp -R "$root/_site" "$fixture/site"
"$validator" "$root" "$fixture/site"

ruby - "$fixture/site/he/feed.xml" <<'RUBY'
path = ARGV.fetch(0)
xml = File.read(path)
changed = xml.sub(/<entry>.*?<\/entry>\s*/m, '')
abort 'feed mutation did not remove an entry' if changed == xml
File.write(path, changed)
RUBY
expect_failure 'all published Hebrew entries must remain in the feed'
