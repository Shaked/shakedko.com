#!/usr/bin/env sh
set -eu

root=${1:-.}
surfaces='AGENTS.md CLAUDE.md .agents/README.md .ollama/modelfile .ollama/system-prompt.md'

fail() { printf '%s\n' "$1" >&2; exit 1; }

for surface in $surfaces; do
  file="$root/$surface"
  [ -f "$file" ] || fail "missing runtime guidance surface: $surface"
  grep -Fq 'make review' "$file" || fail "$surface must require private review."
  grep -Fq 'private review' "$file" && grep -Fq 'succeeds' "$file" || fail "$surface must require a successful private review."
  grep -Fq 'user explicitly approves the push' "$file" || fail "$surface must require user approval before push."
done

makefile="$root/Makefile"
config="$root/_config.yml"
index="$root/index.html"
[ -f "$makefile" ] && [ -f "$config" ] && [ -f "$index" ] || fail 'review workflow support files are missing.'
for target in review review-stop review-status; do
  awk -v target="$target" '$0 == target ":" { found = 1 } END { exit(found ? 0 : 1) }' "$makefile" || fail "missing generic $target wrapper."
done
grep -Fq 'yanki-shakedko-review start "$(CURDIR)"' "$makefile" || fail 'review start wrapper must pass the current checkout.'
grep -Fq 'yanki-shakedko-review stop "$(CURDIR)"' "$makefile" || fail 'review stop wrapper must pass the current checkout.'
grep -Fq 'yanki-shakedko-review status "$(CURDIR)"' "$makefile" || fail 'review status wrapper must pass the current checkout.'
for entry in AGENTS.md CLAUDE.md .agents .ollama Makefile scripts; do
  grep -Fq "  - $entry" "$config" || fail "published-site exclusion is missing: $entry"
done
grep -Fq '{{ "/he" | relative_url }}' "$index" || fail 'Hebrew home switch must be base-path safe.'

for target in review review-stop review-status; do
  recipe=$(awk -v target="$target" '$0 == target ":" { inside = 1; next } inside && /^[^[:space:]#][^:]*:$/ { exit } inside && /^\t/ { sub(/^\t/, ""); print }' "$makefile")
  [ "$(printf '%s\n' "$recipe" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 2 ] || fail "$target recipe must contain exactly the generic guard and helper wrapper."
  case "$target" in review) expected='@yanki-shakedko-review start "$(CURDIR)"' ;; review-stop) expected='@yanki-shakedko-review stop "$(CURDIR)"' ;; review-status) expected='@yanki-shakedko-review status "$(CURDIR)"' ;; esac
  printf '%s\n' "$recipe" | grep -Fxq '@command -v yanki-shakedko-review >/dev/null || { echo "Private review tooling is not installed." >&2; exit 2; }' || fail "$target recipe must retain the exact generic guard."
  printf '%s\n' "$recipe" | grep -Fxq "$expected" || fail "$target recipe must retain the exact generic helper wrapper."
done
