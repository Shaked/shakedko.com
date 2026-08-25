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

make_site() {
  rm -rf "$fixture/site"
  cp -R "$root/_site" "$fixture/site"
}

make_site
"$validator" "$root" "$fixture/site"

ruby - "$fixture/site/he/feed.xml" <<'RUBY'
path = ARGV.fetch(0)
xml = File.read(path)
changed = xml.sub(/<entry>.*?<\/entry>\s*/m, '')
abort 'feed mutation did not remove an entry' if changed == xml
File.write(path, changed)
RUBY
expect_failure 'all published Hebrew entries must remain in the feed'

make_site
ruby - "$fixture/site/feed.xml" <<'RUBY'
path = ARGV.fetch(0)
xml = File.read(path)
entry = xml.match(/<entry>.*?<\/entry>/m)&.[](0)
abort 'missing English feed entry' unless entry
changed_entry = entry.sub(/(<id>).*?(<\/id>)/m, '\\1urn:arbitrary-but-unique\\2')
abort 'ID mutation did not change the entry' if changed_entry == entry
changed = xml.sub(entry, changed_entry)
abort 'ID mutation did not change the feed' if changed == xml
File.write(path, changed)
RUBY
expect_failure 'each Atom ID must match its source document exactly'

make_site
ruby - "$fixture/site/feed.xml" <<'RUBY'
path = ARGV.fetch(0)
xml = File.read(path)
entry = xml.match(/<entry>.*?<\/entry>/m)&.[](0)
abort 'missing ordinary English feed entry' unless entry
original_destination = entry[/<link href="([^"]+)" rel="alternate"/, 1]
abort 'ordinary entry destination is missing' unless original_destination
abort 'ordinary entry already targets the site root' if original_destination == 'https://shakedko.com/'
changed_entry = entry.sub(/(<link href=")[^"]+(" rel="alternate")/, '\\1https://shakedko.com/\\2')
abort 'destination mutation did not change the entry' if changed_entry == entry
changed = xml.sub(entry, changed_entry)
abort 'destination mutation did not change the feed' if changed == xml
File.write(path, changed)
RUBY
expect_failure 'ordinary entry destinations must match their source documents exactly'
