#!/usr/bin/env bash
# node22
# Usage: maven3-jdk17

set -euo pipefail

# Environment
ENVIRONMENT_NAME="${CI_ENVIRONMENT_NAME:-}"
if [ -z "$ENVIRONMENT_NAME" ]; then
  echo "Not CI_ENVIRONMENT_NAME" >&2
  exit 1
fi