#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
validator="$script_dir/check-review-workflow.sh"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/review-workflow.XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

make_fixture() {
  rm -rf "$fixture/work"
  mkdir -p "$fixture/work/.agents" "$fixture/work/.ollama"
  cp "$root/AGENTS.md" "$root/CLAUDE.md" "$root/Makefile" "$root/_config.yml" "$root/index.html" "$fixture/work/"
  cp "$root/.agents/README.md" "$fixture/work/.agents/README.md"
  cp "$root/.ollama/modelfile" "$root/.ollama/system-prompt.md" "$fixture/work/.ollama/"
}

expect_failure() {
  if "$validator" "$fixture/work"; then
    printf 'expected validation failure: %s\n' "$1" >&2
    exit 1
  fi
}

"$validator" "$root"

for surface in AGENTS.md CLAUDE.md .agents/README.md .ollama/modelfile .ollama/system-prompt.md; do
  make_fixture
  sed 's/user explicitly approves the push/user decides/' "$fixture/work/$surface" > "$fixture/mutated"
  mv "$fixture/mutated" "$fixture/work/$surface"
  expect_failure "$surface must retain approval-before-push guidance"
done

make_fixture
sed 's/yanki-shakedko-review start/yanki-shakedko-review status/' "$fixture/work/Makefile" > "$fixture/mutated"
mv "$fixture/mutated" "$fixture/work/Makefile"
expect_failure 'review start wrapper must remain generic and checkout-scoped'

for target in review review-stop review-status; do
  make_fixture
  awk -v target="$target" '{ print; if ($0 == target ":") print "\t@echo extra-command" }' "$fixture/work/Makefile" > "$fixture/mutated"
  mv "$fixture/mutated" "$fixture/work/Makefile"
  expect_failure "$target must reject an extra recipe command"
done
