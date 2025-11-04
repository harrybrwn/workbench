local pax = require('pax')
local util = require('util')

local goci_lint_version = "2.5.0" -- https://github.com/golangci/golangci-lint/releases/latest

local project = pax.project({
  package     = "golangci-lint",
  email       = "me@h3y.sh",
  arch        = "amd64",
  version     = "0.0.1~alpha0",
  section     = "devel",
  author      = pax.git.username(),
  homepage    = "https://github.com/harrybrwn/workbench",
  priority    = pax.Priority.Optional,
  provides    = {
    string.format("golangci-lint (= %s)", goci_lint_version),
  },
  description = "Harry's build of golangci-lint.",
})

util.add_golangci_lint(project, goci_lint_version)

project:finish()
