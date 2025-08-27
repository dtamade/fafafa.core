#!/usr/bin/env bash
set -euo pipefail
# Cleanup demo outputs for fafafa.core.crypto examples
# - Removes generated test_* files and logs

cd "$(dirname "$0")"

count=0
rm_if_exists() {
  local f="$1"
  if [[ -e "$f" ]]; then
    rm -f "$f" && echo "Deleted: $f" && ((count++)) || true
  fi
}

rm_if_exists fileenc.log
rm_if_exists test_original.txt
rm_if_exists test_encrypted.dat
rm_if_exists test_decrypted.txt
rm_if_exists test_decrypted_wrong.txt
rm_if_exists bin/run.log

if [[ "$count" -eq 0 ]]; then
  echo "Nothing to clean."
else
  echo "Cleaned $count file(s)."
fi

echo "Done."

