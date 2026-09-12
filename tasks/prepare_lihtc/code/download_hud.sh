#!/bin/bash
set -euo pipefail
# Run from tasks/prepare_lihtc/code. Preserve the pinned 2024 archive bytes.
mkdir -p ../../../data_raw/hud_lihtc_property/2024
curl --http1.1 --fail --location --silent --show-error \
  https://www.huduser.gov/lihtc/lihtcpub.zip -o ../temp/lihtcpub.zip
printf '%s\n' 'e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288  ../temp/lihtcpub.zip' | shasum -a 256 -c -
mv ../temp/lihtcpub.zip ../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip
