#!/usr/bin/env sh
set -eu

root=${1:-.}
site_dir=${2:-"$root/_site"}
header="$root/_includes/header.html"
config="$root/_config.yml"
source_css="$root/assets/css/style.scss"
compiled_css=${3:-"$site_dir/assets/css/style.css"}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -f "$header" ] || fail "header include is missing."
[ -f "$config" ] || fail "site configuration is missing."
[ -f "$source_css" ] || fail "navigation source CSS is missing."
[ -f "$compiled_css" ] || fail "compiled navigation CSS is missing."
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

ruby - "$site_dir" "$header" "$source_css" "$compiled_css" <<'RUBY'
require 'uri'
site_dir, header_path, source_css_path, compiled_css_path = ARGV
expected = {
  'index.html' => ['/', 'https://x.com/shakedko', 'https://il.linkedin.com/in/shakedklein', '/he/', '/archive/'],
  'he/index.html' => ['/he/', 'https://x.com/shakedko', 'https://il.linkedin.com/in/shakedklein', '/', '/he/archive/']
}

def fail(message)
  warn message
  exit 1
end

header = File.read(header_path)
fail 'mobile toggle must place the checkbox before its associated label and menu content.' unless header.match?(%r{<input\b[^>]*id="nav-trigger"[^>]*>\s*<label\b[^>]*for="nav-trigger"[^>]*>.*?</label>\s*<div class="trigger">}m)

source_css = File.read(source_css_path)
mobile_source = source_css.split('@media screen and (max-width: 600px)', 2)[1]
fail 'mobile navigation CSS is missing.' unless mobile_source
source_trigger = mobile_source.scan(/\.site-nav \.nav-trigger\s*\{([^}]*)\}/m).flatten.last
fail 'mobile nav trigger must override Minima with display: block.' unless source_trigger&.match?(/display:\s*block;/)
['position: absolute;', 'inline-size: 1px;', 'block-size: 1px;', 'inset-inline-start: -9999px;', 'overflow: hidden;', 'clip: rect(0 0 0 0);', 'clip-path: inset(50%);'].each do |declaration|
  fail "mobile nav trigger must remain visually hidden with #{declaration}" unless source_trigger.include?(declaration)
end
fail 'mobile nav trigger must not use visibility: hidden.' if source_trigger.match?(/visibility:\s*hidden/)
fail 'mobile keyboard focus must visibly outline the menu label.' unless mobile_source.match?(%r!\.site-nav \.nav-trigger:focus-visible \+ \.nav-toggle\s*\{[^}]*outline:\s*3px solid var\(--color-focus\);[^}]*\}!m)

compiled_css = File.read(compiled_css_path)
desktop_css, mobile_compiled = compiled_css.split('@media screen and (max-width: 600px)', 2)
fail 'compiled CSS must keep the expanded desktop menu non-focusable.' unless desktop_css&.match?(%r{\.site-nav \.nav-trigger\s*\{\s*display:\s*none\s*;?\s*\}})
fail 'compiled mobile navigation CSS is missing.' unless mobile_compiled
compiled_trigger = mobile_compiled.scan(/\.site-nav \.nav-trigger\s*\{([^}]*)\}/m).flatten.last
fail 'compiled mobile nav trigger must override Minima display:none.' unless compiled_trigger&.match?(/display:\s*block/)
compact_trigger = compiled_trigger.gsub(/\s+/, '')
['position:absolute', 'inline-size:1px', 'block-size:1px', 'inset-inline-start:-9999px', 'overflow:hidden', 'clip:rect(0000)', 'clip-path:inset(50%)'].each do |declaration|
  fail "compiled mobile nav trigger is missing #{declaration}" unless compact_trigger.include?(declaration)
end
fail 'compiled mobile nav trigger must not be display:none or visibility:hidden.' if compiled_trigger.match?(/display:\s*none|visibility:\s*hidden/)
fail 'compiled CSS must visibly show mobile keyboard focus on the menu label.' unless mobile_compiled.match?(%r!\.site-nav \.nav-trigger:focus-visible\s*\+\s*\.nav-toggle\s*\{[^}]*outline:\s*3px solid var\(--color-focus\);[^}]*\}!)

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
