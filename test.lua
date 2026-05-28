local pax = require('pax')

-- local files = require('misc/python').build("3.14.0rc3", {
--   disable_gil = true,
--   prefix = "/usr/local",
-- })
-- pax.print(files)

local project = pax.project({
  package = "workbench-test",
  version = "0.0.1~alpha0",
  section = "devel",
})

local util = require('util')
local cloneopts = {
  repo   = "git@github.com:tree-sitter/tree-sitter.git",
  branch = 'v0.26.3',
  dest   = nil,
  depth  = 1,
}
cloneopts.dest = util.clone_dest(cloneopts)
pax.git.clone({ cloneopts })

project:cargo_build({ root = ".pax/repos/tree-sitter", profile = "optimize" })

require('misc.tree-sitter').gen_completion(project)
pax.print(project:files())
