#!/bin/bash
set -e
cd "$(dirname "$0")"
npx --yes surge . huvypum-agreements.surge.sh
