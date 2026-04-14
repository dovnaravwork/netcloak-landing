#!/bin/bash
# NetCloak landing deploy to Netlify (account leezka21)
# Usage: ./deploy.sh

set -e
cd "$(dirname "$0")"

TOKEN="nfp_ZWBkTzzW5ht4LLGKyZxEv7yMxBt2zjfnc6a1"
SITE_ID="2f983fe8-c8c9-494d-b8a8-e042c011575b"

# Collect ALL files with their SHA1
FILES_JSON="{"
for FILE in index.html 404.html _headers _redirects netlify.toml; do
  [ -f "$FILE" ] || continue
  SHA=$(sha1sum "$FILE" | cut -d' ' -f1)
  FILES_JSON="$FILES_JSON\"/$FILE\":\"$SHA\","
done
FILES_JSON="${FILES_JSON%,}}"

# Create deploy
DEPLOY=$(curl -s -X POST "https://api.netlify.com/api/v1/sites/$SITE_ID/deploys" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"files\":$FILES_JSON}")

DEPLOY_ID=$(echo "$DEPLOY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))")
REQUIRED=$(echo "$DEPLOY" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('required',[])))")

echo "Deploy: $DEPLOY_ID ($REQUIRED files to upload)"

# Upload required files
for FILE in index.html 404.html _headers _redirects netlify.toml; do
  [ -f "$FILE" ] || continue
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "https://api.netlify.com/api/v1/deploys/$DEPLOY_ID/files/$FILE" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$FILE")
  echo "  $FILE: $HTTP"
done

echo "Done! https://netcloak.win"
