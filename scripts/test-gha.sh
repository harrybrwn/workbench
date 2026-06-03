#!/usr/bin/bash

set -euo pipefail

act workflow_dispatch \
	--secret "SSH_KEY=$(cat ~/.ssh/id_github-actions)" \
	--secret "GITHUB_TOKEN=$(gh auth token)" \
	--rm \
	--job release \
	--input version=v0.0.1-alpha3
