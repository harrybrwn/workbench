#!/usr/bin/bash

set -euo pipefail

tag=main

act workflow_dispatch \
	--directory .       \
	--secret "SSH_KEY=$(cat ~/.ssh/id_github-actions)" \
	--secret "GITHUB_TOKEN=$(gh auth token)" \
	--rm \
	--job release \
	--input "version=${tag}"
