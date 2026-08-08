#!/usr/bin/env bash
set -euo pipefail

required_commands=(
  make
  Rscript
  python3
  curl
  unzip
  pdflatex
)

missing_commands=()

{
  printf 'command\tpath\n'
  for command_name in "${required_commands[@]}"; do
    if command_path="$(command -v "${command_name}" 2>/dev/null)"; then
      printf '%s\t%s\n' "${command_name}" "${command_path}"
    else
      printf '%s\tMISSING\n' "${command_name}"
      missing_commands+=("${command_name}")
    fi
  done

  printf '\nIf R package installation fails for sf, install GDAL, GEOS, PROJ, and UDUNITS.\n'
  printf 'macOS: brew install gdal geos proj udunits\n'
  printf 'Ubuntu/Debian: sudo apt-get install libgdal-dev libgeos-dev libproj-dev libudunits2-dev\n'
} > ../output/system_requirements.txt.tmp

mv ../output/system_requirements.txt.tmp ../output/system_requirements.txt

if ((${#missing_commands[@]} > 0)); then
  printf 'Missing required command-line tools: %s\n' "${missing_commands[*]}" >&2
  exit 1
fi

printf 'Wrote system requirements to ../output/system_requirements.txt\n'
