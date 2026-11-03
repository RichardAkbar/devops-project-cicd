#!/bin/sh

echo "=== Agent information ==="
hostname
whoami

echo ""
echo "=== Available tools ==="
for tool in kubectl docker trivy curl wget; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "$tool: $(command -v "$tool")"
    else
        echo "$tool: NOT FOUND"
    fi
done

echo ""
echo "=== OS information ==="
cat /etc/os-release
