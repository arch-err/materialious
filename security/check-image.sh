#!/usr/bin/env bash
set -euo pipefail
image=$1
kind=$2
root=$(cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d)
container=$(docker create "$image")
trap 'docker rm -f "$container" >/dev/null 2>&1 || true; rm -rf "$tmp"' EXIT
docker cp "$container:/etc/ssl/certs/ca-certificates.crt" "$tmp/ca.pem"
for chain in "$root"/chains/*.pem; do
    if openssl verify -CAfile "$tmp/ca.pem" -untrusted "$chain" "$chain" > "$tmp/result" 2>&1; then
        echo "FAIL: compromised chain trusted: $chain"
        exit 1
    fi
    # A timeout, expiry, or unrelated verification error is not a distrust result.
    grep -Eq 'error (20|23) at' "$tmp/result" || { cat "$tmp/result"; exit 1; }
    echo "PASS: distrusted $(basename "$chain")"
done
if [[ "$kind" == node ]]; then
    docker run --rm --cap-drop ALL --security-opt no-new-privileges \
        -v "$root:/security:ro" --entrypoint node "$image" /security/tls.cjs
elif [[ "$kind" == deno ]]; then
    docker run --rm --cap-drop ALL --security-opt no-new-privileges \
        -e GET_FETCH_CLIENT_LOCATION=file:///security/tls.ts \
        -v "$root:/security:ro" "$image"
fi
