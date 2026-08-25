#!/usr/bin/env sh
set -eu

css_file=${1:-assets/css/style.scss}

header_block=$(sed -n '/^\.site-header {/,/^}/p' "$css_file")
nav_block=$(sed -n '/^  \.site-nav {/,/^  }/p' "$css_file")

printf '%s\n' "$header_block" | grep -q 'position: relative;'
printf '%s\n' "$header_block" | grep -q 'z-index: 1;'
printf '%s\n' "$nav_block" | grep -q 'position: absolute;'
printf '%s\n' "$nav_block" | grep -q 'z-index: 3;'
