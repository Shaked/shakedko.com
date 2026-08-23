#!/usr/bin/env sh
set -eu

root=${1:-.}
site_dir=${2:-"$root/_site"}
header="$root/_includes/header.html"
config="$root/_config.yml"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -f "$header" ] || fail "header include is missing."
[ -f "$config" ] || fail "site configuration is missing."
[ -f "$site_dir/index.html" ] || fail "English generated home page is missing."
[ -f "$site_dir/he/index.html" ] || fail "Hebrew generated home page is missing."
[ ! -e "$root/about.md" ] || fail "about.md must be removed."
[ ! -e "$site_dir/about" ] || fail "/about/ must not be generated."

grep -q '^linkedin_profile: "https://il.linkedin.com/in/shakedklein"$' "$config" || fail "LinkedIn profile configuration is missing or incorrect."
if grep -Eiq 'about|/about/' "$header"; then
  fail "header must not reference About."
fi

for route in '"/" | relative_url' '"/he/" | relative_url' '"/archive/" | relative_url' '"/he/archive/" | relative_url'; do
  grep -Fq "$route" "$header" || fail "internal navigation route must use relative_url: $route"
done

grep -Fq 'aria-label="X profile (opens in a new tab)"' "$header" || fail "X icon needs an accessible label."
grep -Fq 'aria-label="LinkedIn profile (opens in a new tab)"' "$header" || fail "LinkedIn icon needs an accessible label."
external_links=$(grep -c 'target="_blank" rel="noopener noreferrer"' "$header" || true)
[ "$external_links" -eq 4 ] || fail "social links must have safe external-link attributes."

svg_count=$(grep -c '<svg aria-hidden="true" focusable="false"' "$header" || true)
[ "$svg_count" -ge 3 ] || fail "navigation SVGs must be hidden from assistive technology and unfocusable."
if grep -Eiq '<(script|foreignObject)|on[a-z]+[[:space:]]*=|javascript:' "$header"; then
  fail "navigation SVGs and links must not contain executable content."
fi

ruby - "$site_dir" <<'RUBY'
require 'uri'
site_dir = ARGV.fetch(0)
expected = {
  'index.html' => ['/', 'https://x.com/shakedko', 'https://il.linkedin.com/in/shakedklein', '/he/', '/archive/'],
  'he/index.html' => ['/he/', 'https://x.com/shakedko', 'https://il.linkedin.com/in/shakedklein', '/', '/he/archive/']
}

def fail(message)
  warn message
  exit 1
end

expected.each do |page, destinations|
  html = File.read(File.join(site_dir, page))
  nav = html[/<nav class="site-nav">.*?<\/nav>/m]
  fail "#{page}: navigation is missing" unless nav
  links = nav.scan(/<a\b([^>]*)>(.*?)<\/a>/m)
  actual = links.map { |attributes, _| attributes[/\bhref="([^"]*)"/, 1] }
  fail "#{page}: expected navigation destinations #{destinations.inspect}, got #{actual.inspect}" unless actual == destinations
  fail "#{page}: About must not be generated or linked" if html.match?(%r{(?:href=["'])/about/?(?:["'#])|/about/index\.html})

  links.each_with_index do |(attributes, _), index|
    next unless index == 1 || index == 2
    expected_label = index == 1 ? 'X profile (opens in a new tab)' : 'LinkedIn profile (opens in a new tab)'
    fail "#{page}: #{expected_label} is not accessible" unless attributes.include?(%(aria-label="#{expected_label}"))
    fail "#{page}: #{expected_label} must open safely" unless attributes.include?('target="_blank"') && attributes.include?('rel="noopener noreferrer"')
  end

  actual.each do |href|
    next if href.start_with?('http://', 'https://')
    path = href.split(/[?#]/, 2).first
    fail "#{page}: navigation links must be root-relative: #{href}" unless path.start_with?('/')
    relative = URI::DEFAULT_PARSER.unescape(path.sub(%r{\A/}, ''))
    target = relative.empty? || path.end_with?('/') ? File.join(site_dir, relative, 'index.html') : File.join(site_dir, relative)
    target = File.join(site_dir, relative, 'index.html') if !File.exist?(target) && File.directory?(File.join(site_dir, relative))
    fail "#{page}: broken internal navigation link #{href}" unless File.exist?(target)
  end
end
RUBY
