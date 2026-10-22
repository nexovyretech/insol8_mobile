#!/usr/bin/env bash
# Publishes the portal page to its S3 bucket and writes config.js from the stack outputs.
# Run from infra/distribution after `sam deploy`:   ./scripts/deploy-portal.sh [stack-name]
set -euo pipefail

STACK="${1:-insol8-mobile-dist}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

out() {
  aws cloudformation describe-stacks --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}

BUCKET="$(out PortalBucketName)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/config.js" <<CFG
window.INSOL8_CONFIG = {
  cognitoDomain: "$(out CognitoDomainUrl)",
  clientId: "$(out UserPoolClientId)",
  apiUrl: "$(out ApiUrl)"
};
CFG

aws s3 cp "$HERE/portal/index.html" "s3://$BUCKET/index.html" \
  --content-type "text/html; charset=utf-8" --cache-control "no-cache"
aws s3 cp "$TMP/config.js" "s3://$BUCKET/config.js" \
  --content-type "application/javascript; charset=utf-8" --cache-control "no-cache"

echo
echo "Portal is live at: $(out PortalUrl)"
