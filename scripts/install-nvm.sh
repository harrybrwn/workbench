#!/bin/sh
set -eu

# Don't append nvm to .bashrc
export PROFILE=/dev/null

curl -LsSf -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
