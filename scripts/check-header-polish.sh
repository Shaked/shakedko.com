#!/bin/sh
set -eu

root=${1:-.}
source_css="$root/assets/css/style.scss"
site_dir=${2:-"$root/_site"}
compiled_css=${3:-"$site_dir/assets/css/style.css"}
header="$root/_includes/header.html"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -f "$source_css" ] || fail 'header source CSS is missing.'
[ -f "$compiled_css" ] || fail 'compiled header CSS is missing.'
[ -f "$header" ] || fail 'header include is missing.'

ruby - "$source_css" "$compiled_css" "$header" <<'RUBY'
source_path, compiled_path, header_path = ARGV

def fail(message)
  warn message
  exit 1
end

source = File.read(source_path)
compiled = File.read(compiled_path)
header = File.read(header_path)

fail 'header navigation needs an accessible landmark name.' unless header.include?('<nav class="site-nav" aria-label="Primary navigation">')
fail 'quote needs the semantic polish wrapper.' unless header.match?(%r{<div class="header-quote">\s*<blockquote class="site-quote">.*?</blockquote>\s*<cite class="quote-author">}m)

header_block = source[/\.site-header\s*\{([^}]*)\}/m, 1]
fail 'header must keep its stacking context above embedded cards.' unless header_block&.match?(/position:\s*relative;/) && header_block.match?(/isolation:\s*isolate;/) && header_block.match?(/z-index:\s*1;/)
fail 'header borders and padding must use logical properties.' unless header_block.match?(/border-block-start:/) && header_block.match?(/border-block-end:/) && header_block.match?(/padding-block:/)

top = source[/\.header-top\s*\{([^}]*)\}/m, 1]
fail 'header top needs a shared divider and resilient flex spacing.' unless top&.match?(/position:\s*relative;/) && top.match?(/gap:\s*var\(--space-4\);/) && top.match?(/border-block-end:/) && top.match?(/margin-block-end:/)

quote = source[/\.header-quote\s*\{([^}]*)\}/m, 1]
fail 'quote needs logical divider and spacing.' unless quote&.match?(/padding-inline-start:/) && quote.match?(/border-inline-start:/) && quote.match?(/max-inline-size:/)

trigger = source[/\.site-nav \.trigger\s*\{([^}]*)\}/m, 1]
fail 'desktop navigation needs a wrapping flex layout.' unless trigger&.match?(/display:\s*flex;/) && trigger.match?(/flex-wrap:\s*wrap;/) && trigger.match?(/justify-content:\s*flex-end;/)

link = source[/\.site-nav \.page-link\s*\{([^}]*)\}/m, 1]
fail 'navigation spacing must use logical properties.' unless link&.match?(/margin-inline-start:\s*0;/) && link.match?(/padding:/) && link.match?(/border-radius:/)
fail 'navigation links need a visible keyboard state.' unless source.match?(/\.site-nav \.page-link:focus-visible\s*\{[^}]*background-color:\s*var\(--color-purple-soft\);/m)

mobile = source.split('@media screen and (max-width: 600px)', 2)[1]
fail 'mobile header polish is missing.' unless mobile
mobile_nav = mobile[/\.site-nav\s*\{([^}]*)\}/m, 1]
fail 'mobile navigation must preserve logical RTL anchoring.' unless mobile_nav&.match?(/inset-inline-end:\s*15px;/) && mobile_nav.match?(/inset-inline-start:\s*auto;/)
fail 'mobile navigation must not use a physical right inset.' if mobile_nav.match?(/\bright:\s*/)
fail 'mobile menu needs a bounded control size and shared shadow.' unless mobile_nav.match?(/inline-size:\s*36px;/) && mobile_nav.match?(/max-inline-size:/) && mobile_nav.match?(/box-shadow:\s*var\(--shadow-md\);/)
expanded_nav = mobile[/\.site-nav:has\(\.nav-trigger:checked\)\s*\{([^}]*)\}/m, 1]
fail 'expanded mobile menu needs a compact bounded inline size.' unless expanded_nav&.match?(/inline-size:\s*min\(240px,\s*calc\(100%\s*-\s*var\(--space-6\)\)\);/)
expanded_top = mobile[/\.header-top:has\(\.nav-trigger:checked\)\s*\{([^}]*)\}/m, 1]
fail 'expanded mobile menu must reserve its compact panel height.' unless expanded_top&.match?(/padding-block-end:\s*240px;/)
fail 'mobile navigation rows must keep a compact touch rhythm.' unless mobile.match?(/\.site-nav \.page-link\s*\{[^}]*min-block-size:\s*44px;/m) && mobile.match?(/\.mobile-social-links\s*\{[^}]*min-block-size:\s*44px;/m)

compiled_header = compiled.scan(/\.site-header\s*\{([^}]*)\}/m).flatten.last
fail 'compiled header lost its stacking contract.' unless compiled_header&.match?(/isolation:\s*isolate/) && compiled_header.match?(/z-index:\s*1/)
compiled_mobile = compiled.split('@media screen and (max-width: 600px)', 2)[1]
fail 'compiled mobile header polish is missing.' unless compiled_mobile
compiled_nav = compiled_mobile.scan(/\.site-nav\s*\{([^}]*)\}/m).flatten.last
fail 'compiled mobile navigation lost its RTL geometry.' unless compiled_nav&.match?(/inset-inline-end:\s*15px/) && compiled_nav.match?(/inset-inline-start:\s*auto/) && compiled_nav.match?(/max-inline-size:/)
fail 'compiled mobile navigation regained a physical right inset.' if compiled_nav.match?(/\bright:\s*/)
RUBY
