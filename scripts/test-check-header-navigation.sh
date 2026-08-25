#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
validator="$script_dir/check-header-navigation.sh"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/check-header-navigation.XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

make_fixture() {
  rm -rf "$fixture/work"
  mkdir -p "$fixture/work/_includes" "$fixture/work/assets/css" "$fixture/work/_site/he" "$fixture/work/_site/assets/css"
  cp "$root/_config.yml" "$fixture/work/_config.yml"
  cp "$root/_includes/header.html" "$fixture/work/_includes/header.html"
  cp "$root/assets/css/style.scss" "$fixture/work/assets/css/style.scss"
  cp "$root/_site/assets/css/style.css" "$fixture/work/_site/assets/css/style.css"
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

expect_success() {
  description=$1
  if ! "$validator" "$fixture/work" "$fixture/work/_site"; then
    printf 'expected validation success: %s\n' "$description" >&2
    exit 1
  fi
}

"$validator" "$root" "$root/_site"

make_fixture
ruby - "$fixture/work/_site/assets/css/style.css" <<'RUBY'
path = ARGV.fetch(0)
css = File.read(path)
desktop, mobile = css.split('@media screen and (max-width: 600px)', 2)
abort 'missing desktop CSS rule' unless desktop && desktop.sub!(/\.site-nav\s+\.nav-trigger\s*\{\s*display\s*:\s*none\s*;?\s*\}/, '.site-nav .nav-trigger { display: none }')
abort 'missing mobile CSS rule' unless mobile && mobile.sub!(/(\.site-nav\s+\.nav-trigger\s*\{[^}]*?)display\s*:\s*block\s*;?/, '\\1display: block')
File.write(path, desktop + '@media screen and (max-width: 600px)' + mobile)
RUBY
expect_success 'compiled CSS may be formatted with an omitted desktop final semicolon'

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

make_fixture
sed 's/aria-label="מעבר לאנגלית"//' "$fixture/work/_includes/header.html" > "$fixture/header.tmp"
mv "$fixture/header.tmp" "$fixture/work/_includes/header.html"
expect_failure 'Hebrew language switch needs its explicit Hebrew accessible name'

make_fixture
sed 's/>English<\//>אנגלית<\//' "$fixture/work/_site/he/index.html" > "$fixture/page.tmp"
mv "$fixture/page.tmp" "$fixture/work/_site/he/index.html"
expect_failure 'generated Hebrew language switch must visibly read English'

make_fixture
sed 's#href="/" aria-label="מעבר לאנגלית"#href="/he/" aria-label="מעבר לאנגלית"#' "$fixture/work/_site/he/index.html" > "$fixture/page.tmp"
mv "$fixture/page.tmp" "$fixture/work/_site/he/index.html"
expect_failure 'generated Hebrew language switch must link to the English home page'

make_fixture
sed 's/inset-inline-start: auto;/right: 15px;/' "$fixture/work/assets/css/style.scss" > "$fixture/style.tmp"
mv "$fixture/style.tmp" "$fixture/work/assets/css/style.scss"
expect_failure 'mobile RTL navigation must clear Minima’s physical right inset'

make_fixture
ruby - "$fixture/work/_site/assets/css/style.css" <<'RUBY'
path = ARGV.fetch(0)
before = File.read(path)
mobile_start = before.index('@media screen and (max-width: 600px)')
abort 'missing mobile media query' unless mobile_start
mobile = before[mobile_start..]
matches = mobile.enum_for(:scan, /\.site-nav\s+\.nav-trigger\s*\{[^}]*display\s*:\s*block\s*;?[^}]*\}/m).to_a
abort 'missing mobile display:block trigger rule' if matches.empty?
rule = matches.last
mutated_rule = rule.sub(/display\s*:\s*block\s*;?/, 'display: none')
abort 'mobile trigger mutation did not change display:block' if mutated_rule == rule
after = before.dup
offset = mobile_start + mobile.rindex(rule)
after[offset, rule.length] = mutated_rule
abort 'compiled CSS mutation did not change the file' if after == before
abort 'compiled mobile trigger was not changed to display:none' unless after[offset, mutated_rule.length].match?(/display\s*:\s*none/)
File.write(path, after)
RUBY
expect_failure 'compiled mobile CSS must override Minima display:none'
