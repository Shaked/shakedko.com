#!/usr/bin/env sh
set -eu
root=${1:-.}
site_dir=${2:-$root/_site}
base=${3:-/shakedko}
fail() { printf '%s\n' "$1" >&2; exit 1; }
grep -Fq '{{ "/" | relative_url }}' "$root/he/index.html" || fail 'Hebrew home English switch must use relative_url.'
grep -Fq '{{ "/he/archive/" | relative_url }}' "$root/archive/index.html" || fail 'English archive Hebrew switch must use relative_url.'
grep -Fq '{{ "/archive/" | relative_url }}' "$root/he/archive/index.html" || fail 'Hebrew archive English switch must use relative_url.'
ruby - "$site_dir" "$base" <<'RUBY'
site, base = ARGV
{'he/index.html'=>"#{base}/",'archive/index.html'=>"#{base}/he/archive/",'he/archive/index.html'=>"#{base}/archive/"}.each do |page, href|
  abort "#{page}: missing exact subpath switch #{href}" unless File.read(File.join(site, page)).include?(%(href="#{href}"))
end
RUBY
