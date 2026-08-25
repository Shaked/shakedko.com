#!/usr/bin/env sh
set -eu

root=${1:-.}
site_dir=${2:-$root/_site}
mapping="$root/_data/post_types.yml"
icons="$root/assets/icons/post-types"
list="$root/_includes/post-list.html"
post_layout="$root/_layouts/post.html"
styles="$root/assets/css/style.scss"
config="$root/_config.yml"
required_keys='featured ai security infrastructure development craft building thoughts'

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -f "$mapping" ] || fail 'post type mapping is missing.'
[ -f "$list" ] || fail 'post list template is missing.'
[ -f "$post_layout" ] || fail 'post layout is missing.'

entries=$(mktemp "${TMPDIR:-/tmp}/post-types-entries.XXXXXX")
trap 'rm -f "$entries"' EXIT HUP INT TERM

ruby -ryaml - "$mapping" > "$entries" <<'RUBY' || fail 'post type mappings must each have English and Hebrew labels plus a local SVG icon.'
mapping = YAML.load_file(ARGV.fetch(0))
abort 'post type mapping must be a YAML object.' unless mapping.is_a?(Hash)
expected_labels = {
  'featured' => { 'en' => 'Featured', 'he' => 'מומלץ' },
  'ai' => { 'en' => 'AI', 'he' => 'בינה מלאכותית' },
  'security' => { 'en' => 'Security', 'he' => 'אבטחה' },
  'infrastructure' => { 'en' => 'Infrastructure', 'he' => 'תשתיות' },
  'development' => { 'en' => 'Development', 'he' => 'פיתוח' },
  'craft' => { 'en' => 'Craft', 'he' => 'יצירה' },
  'building' => { 'en' => 'Building', 'he' => 'בנייה' },
  'thoughts' => { 'en' => 'Thoughts', 'he' => 'מחשבות' }
}

mapping.each do |key, value|
  abort "invalid post type key: #{key.inspect}" unless key.is_a?(String) && key.match?(/\A[a-z][a-z0-9_-]*\z/)
  abort "#{key} must be a mapping." unless value.is_a?(Hash)
  labels = value['label']
  abort "#{key} must have bilingual labels." unless labels.is_a?(Hash)
  %w[en he].each do |language|
    label = labels[language]
    abort "#{key} is missing a #{language} label." unless label.is_a?(String) && !label.strip.empty?
  end
  icon = value['icon']
  abort "#{key} is missing a local SVG icon." unless icon.is_a?(String) && icon.match?(/\A[a-z0-9_-]+\.svg\z/)
  puts [key, labels['en'], labels['he'], icon].join("\t")
end

expected_labels.each do |key, labels|
  actual = mapping[key]
  abort "missing required post type: #{key}" unless actual.is_a?(Hash)
  labels.each do |language, expected_label|
    abort "#{key} #{language} label must equal #{expected_label.inspect}." unless actual.dig('label', language) == expected_label
  end
end
RUBY

for key in $required_keys; do
  awk -F '\t' -v key="$key" '$1 == key { found = 1 } END { exit(found ? 0 : 1) }' "$entries" || fail "missing required post type: $key"
done

while IFS="$(printf '\t')" read -r key english hebrew icon; do
  [ -n "$key" ] && [ -n "$english" ] && [ -n "$hebrew" ] && [ -n "$icon" ] || fail 'post type mapping contains an invalid entry.'
  [ -f "$icons/$icon" ] || fail "$key references a missing icon: $icon"
done < "$entries"

for icon in "$icons"/*.svg; do
  [ -f "$icon" ] || fail 'post type icons are missing.'
  grep -q '<svg ' "$icon" || fail "$icon is not an SVG."
  grep -q 'aria-hidden="true"' "$icon" || fail "$icon must be decorative."
  grep -q 'focusable="false"' "$icon" || fail "$icon must not be focusable."
  if grep -Eqi '<script|<foreignObject|<(image|use|iframe|object|embed|audio|video|canvas|link|meta|base|style)|[[:space:]]on[a-z0-9:_-]*[[:space:]]*=|[[:space:]](href|src|xlink:href)[[:space:]]*=|url\(|javascript:|data:' "$icon"; then
    fail "$icon contains an executable or external reference."
  fi
done

ruby - "$list" "$post_layout" <<'RUBY' || fail 'post-type renderers must use bilingual mappings and text-only unknown fallbacks.'
list_path, post_path = ARGV

def fail(message)
  warn message
  exit 1
end

def assert_renderer(path, object)
  template = File.read(path)
  fail "#{path} does not use the central mapping." unless template.include?("site.data.post_types[#{object}.post_type]")
  fail "#{path} must render a marker for unknown post types." unless template.include?("{% if #{object}.post_type %}")
  fail "#{path} must branch between configured and unknown post types." unless template.include?('{% if post_type %}') && template.include?('{% else %}')

  configured, fallback = template.split('{% if post_type %}', 2).last.split('{% else %}', 2)
  fail "#{path} must use the language-aware configured label." unless configured.include?("post_type.label[#{object}.lang]")
  fail "#{path} must keep configured icons decorative." unless configured.match?(%r{<img[^>]*alt=""[^>]*aria-hidden="true"})
  fail "#{path} unknown post types must not render an image." if fallback.split('{% endif %}', 2).first.include?('<img')
  expected_fallback = "#{object}.post_type | replace: '_', ' ' | replace: '-', ' ' | capitalize | escape"
  fail "#{path} must render a readable text-only unknown post type fallback." unless fallback.include?(expected_fallback)
end

assert_renderer(list_path, 'post')
assert_renderer(post_path, 'page')
RUBY

post_type_block=$(awk '/^\.post-item \.post-type \{/,/^\}/ { print }' "$styles")
printf '%s\n' "$post_type_block" | grep -q 'position: absolute;' || fail 'post type marker must sit in the card corner.'
printf '%s\n' "$post_type_block" | grep -q 'inset-block-start:' || fail 'post type marker must use logical vertical placement.'
printf '%s\n' "$post_type_block" | grep -q 'inset-inline-start:' || fail 'post type marker must mirror in RTL.'
! printf '%s\n' "$post_type_block" | grep -Eq '(top|left|right):' || fail 'post type marker must remain RTL-safe.'
grep -q 'padding-block-start: 52px;' "$styles" || fail 'standard cards must reserve space for the corner marker.'
grep -q 'padding-block-start: 42px;' "$styles" || fail 'X cards must reserve space for the corner marker.'
badge_block=$(awk '/^\.post-badge \{/,/^\}/ { print }' "$styles")
printf '%s\n' "$badge_block" | grep -q 'inset-inline-end:' || fail 'pinned badges must coexist on the opposite logical corner.'
detail_type_block=$(awk '/^\.post-header \.post-type \{/,/^\}/ { print }' "$styles")
printf '%s\n' "$detail_type_block" | grep -q 'display: inline-flex;' || fail 'post-detail type marker must remain inline in the header.'
! printf '%s\n' "$detail_type_block" | grep -q 'position: absolute;' || fail 'post-detail type marker must not escape its header.'
grep -q 'border-radius: 999px' "$styles" || fail 'tags must render as pills.'
grep -q 'background-color: var(--color-surface)' "$styles" || fail 'tag pills must use the white surface.'
grep -q 'post_type: "thoughts"' "$config" || fail 'collections must default to thoughts.'
grep -Fq 'pinned_label="נעוץ"' "$root/he/index.html" || fail 'Hebrew pinned posts must use the exact נעוץ label.'
awk '
  /<div class="post-content"/ { content = 1 }
  content && /<\/div>/ { content_done = 1; next }
  content_done && /<aside class="post-tags"/ { tags_after_content = 1 }
  END { exit(tags_after_content ? 0 : 1) }
' "$post_layout" || fail 'tags must remain below article content.'
grep -Fq 'aria-label="{% if page.lang == "he" %}תגיות{% else %}Tags{% endif %}"' "$post_layout" || fail 'post tag accessibility label must be language-aware.'
! grep -Eq 'Tags:|[📌🏷️#]' "$post_layout" || fail 'tag rendering must not include a label or emoji.'

if [ -d "$site_dir" ]; then
  ruby - "$site_dir" <<'RUBY' || fail 'generated post-type labels, badges, or tag accessibility labels are incorrect.'
site_dir = ARGV.fetch(0)
pages = {
  'index.html' => { marker: ['Featured', 'featured.svg'], badge: '📌 Pinned' },
  'he/index.html' => { marker: ['אבטחה', 'security.svg'] },
  '2013/11/23/tinder-privacy-issues/index.html' => { marker: ['Featured', 'featured.svg'], tags: 'Tags' },
  'מעצמת-הסייבר-וקופות-החולים/index.html' => { marker: ['אבטחה', 'security.svg'], tags: 'תגיות' }
}

def fail(message)
  warn message
  exit 1
end

def blocks(html, class_name)
  html.scan(%r{<div\b[^>]*\bclass="[^"]*\b#{Regexp.escape(class_name)}\b[^"]*"[^>]*>.*?</div>}m)
end

def text(html)
  html.gsub(/<[^>]*>/, '').gsub(/\s+/, ' ').strip
end

pages.each do |relative_path, expected|
  path = File.join(site_dir, relative_path)
  fail "generated page is missing: #{relative_path}" unless File.file?(path)
  html = File.read(path)
  if expected[:marker]
    label, icon = expected.fetch(:marker)
    marker = blocks(html, 'post-type').find { |block| text(block) == label }
    fail "#{relative_path}: missing exact scoped post-type label #{label.inspect}" unless marker
    fail "#{relative_path}: configured post type #{label.inspect} is missing its icon" unless marker.include?("assets/icons/post-types/#{icon}")
  end
  if expected[:badge]
    badge = blocks(html, 'post-badge').find { |block| text(block) == expected.fetch(:badge) }
    fail "#{relative_path}: missing exact scoped post-badge label #{expected.fetch(:badge).inspect}" unless badge
  end
  if expected[:tags]
    tags = html[%r{<aside\b[^>]*\bclass="post-tags"[^>]*>}m]
    fail "#{relative_path}: tags are missing" unless tags
    fail "#{relative_path}: tag accessibility label changed" unless tags.include?(%(aria-label="#{expected.fetch(:tags)}"))
  end
end
RUBY
fi
