local paxutil = require("paxutil")

local M = {}

---Add support files to the project.
---@param project pax.Project
function M.files(project)
  local files = paxutil.doc_files("fd", {
    "CHANGELOG.md",
    "LICENSE-APACHE",
    "LICENSE-MIT",
  })
  table.insert(files, paxutil.manpage("fd/doc/fd.1"))
  -- TODO: Add zsh completion file from fd/contrib/completions/_fd
  project:add_files(files)
end

return M
