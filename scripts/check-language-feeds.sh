#!/usr/bin/env sh
set -eu

root=${1:-.}
site_dir=${2:-"$root/_site"}

ruby - "$root" "$site_dir" <<'RUBY'
require 'rexml/document'
require 'rexml/xpath'
require 'date'
require 'time'
require 'uri'
require 'yaml'

root, site_dir = ARGV
atom = { 'atom' => 'http://www.w3.org/2005/Atom' }

def fail(message)
  warn message
  exit 1
end

def front_matter(path)
  text = File.read(path)
  match = text.match(/\A---\s*\n(.*?)^---\s*$\n?/m)
  fail "#{path}: front matter is missing." unless match
  YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: false) || {}
end

def collection_entries(root, collection)
  Dir.glob(File.join(root, "_#{collection}", '*.{md,markdown}')).map do |path|
    data = front_matter(path)
    next if data['published'] == false

    {
      title: data.fetch('title').to_s.gsub(/\s+/, ' ').strip,
      published: Time.parse(data.fetch('date').to_s),
      xlink: data['xlink']&.to_s,
      archived: data['archived'] == true
    }
  end.compact.sort_by { |entry| entry[:published] }.reverse
end

def generated_documents(site_dir)
  Dir.glob(File.join(site_dir, '**', '*.html')).map do |path|
    html = File.read(path)
    canonical = html[/<link rel="canonical" href="([^"]+)"\s*\/>/, 1]
    title = html[/<meta property="og:title" content="([^"]+)"\s*\/>/, 1]
    published = html[/<meta property="article:published_time" content="([^"]+)"\s*\/>/, 1]
    next unless canonical && title && published

    { title: normalize_title(title), published: Time.parse(published), canonical: canonical }
  end.compact
end

def bind_generated_document(source, documents)
  matches = documents.select do |document|
    document[:title] == normalize_title(source[:title]) && document[:published] == source[:published]
  end
  fail "#{source[:title]}: source document does not resolve to exactly one generated document." unless matches.length == 1

  canonical = matches.first[:canonical]
  source.merge(id: canonical.sub(%r{/+\z}, ''), destination: source[:xlink] || canonical)
end

def atom_text(element, name, namespaces)
  child = REXML::XPath.first(element, "atom:#{name}", namespaces)
  child&.text&.gsub(/\s+/, ' ')&.strip
end

def normalize_title(value)
  value.to_s.tr('“”‘’', "\\\"\\\"''").gsub(/\s+/, ' ').strip
end

def generated_document?(site_dir, href)
  uri = URI.parse(href)
  return false unless uri.scheme.nil? || %w[http https].include?(uri.scheme)

  path = URI::DEFAULT_PARSER.unescape(uri.path)
  return File.exist?(File.join(site_dir, 'index.html')) if path.empty? || path == '/'

  relative = path.sub(%r{\A/}, '')
  File.exist?(File.join(site_dir, relative, 'index.html')) || File.exist?(File.join(site_dir, relative))
rescue URI::InvalidURIError
  false
end

def advertised_feed?(page, href)
  File.read(page).scan(/<link\b[^>]*>/i).any? do |tag|
    tag.match?(/rel="alternate"/) && tag.match?(/type="application\/atom\+xml"/) && tag.match?(/href="#{Regexp.escape(href)}"/)
  end
end

def validate_feed(root, site_dir, collection, feed_path, discovery_page, discovery_href, namespaces)
  feed_file = File.join(site_dir, feed_path)
  fail "#{feed_path}: generated feed is missing." unless File.file?(feed_file)
  fail "#{discovery_page}: language feed is not advertised." unless advertised_feed?(File.join(site_dir, discovery_page), discovery_href)

  document = REXML::Document.new(File.read(feed_file))
  fail "#{feed_path}: Atom feed root is invalid." unless document.root&.name == 'feed' && document.root.namespace == namespaces['atom']
  documents = generated_documents(site_dir)
  expected = collection_entries(root, collection).map { |source| bind_generated_document(source, documents) }
  entries = REXML::XPath.match(document, '/atom:feed/atom:entry', namespaces)
  fail "#{feed_path}: expected #{expected.length} entries, found #{entries.length}." unless entries.length == expected.length

  ids = []
  entries.each_with_index do |entry, index|
    source = expected.fetch(index)
    title = atom_text(entry, 'title', namespaces)
    published = atom_text(entry, 'published', namespaces)
    updated = atom_text(entry, 'updated', namespaces)
    id = atom_text(entry, 'id', namespaces)
    link = REXML::XPath.first(entry, "atom:link[@rel='alternate']", namespaces)&.attributes&.[]('href')

    fail "#{feed_path}: entry #{index + 1} title is incorrect." unless normalize_title(title) == normalize_title(source[:title])
    fail "#{feed_path}: entry #{index + 1} published date is invalid." unless Time.parse(published) == source[:published]
    fail "#{feed_path}: entry #{index + 1} updated date is invalid." unless Time.parse(updated)
    fail "#{feed_path}: entry #{index + 1} ID does not match its source document." unless id == source[:id]
    ids << id

    fail "#{feed_path}: entry #{index + 1} destination does not match its source document." unless link == source[:destination]
  rescue ArgumentError
    fail "#{feed_path}: entry #{index + 1} has an invalid Atom timestamp."
  end

  fail "#{feed_path}: entry IDs must be unique." unless ids.uniq.length == ids.length
  archived_count = expected.count { |entry| entry[:archived] }
  fail "#{feed_path}: archived entries were omitted." if archived_count.positive? && entries.length < archived_count
end

validate_feed(root, site_dir, 'posts_en', 'feed.xml', 'index.html', '/feed.xml', atom)
validate_feed(root, site_dir, 'posts_he', 'he/feed.xml', 'he/index.html', '/he/feed.xml', atom)
RUBY
