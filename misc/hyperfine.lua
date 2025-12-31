local paxutil = require("paxutil")
local M = {}

---Add support files to the project.
---@param project pax.Project
function M.files(project)
  local files = paxutil.doc_files("hyperfine", {
    "CHANGELOG.md",
    "LICENSE-APACHE",
    "LICENSE-MIT",
  })
  table.insert(files, paxutil.manpage("hyperfine/doc/hyperfine.1"))
  project:add_files(files)
end

return M
