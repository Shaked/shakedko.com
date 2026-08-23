#!/usr/bin/env sh
set -eu

site_dir=${1:?usage: check-document-language.sh SITE_DIRECTORY}

for page in "$site_dir/he/index.html" "$site_dir/he/archive/index.html"; do
  grep -q '^<html lang="he" dir="rtl">$' "$page"
done

for page in "$site_dir/index.html" "$site_dir/archive/index.html"; do
  grep -q '^<html lang="en">$' "$page"
done
