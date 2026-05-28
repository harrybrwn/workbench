local pax = require('pax')
local paxutil = require('misc.paxutil')

local M = {}

---@param project pax.Project
function M.gen_completion(project)
  local target = ".pax/repos/tree-sitter/target/release"
  local dir = pax.path.join(target, "completion")
  pax.fs.mkdir_all(dir)
  local bash = pax.path.join(dir, "tree-sitter.bash")
  local zsh = pax.path.join(dir, "_tree-sitter")
  local fish = pax.path.join(dir, "tree-sitter.fish")
  local bin = pax.path.join(target, "tree-sitter")
  pax.os.exec(bin, { "complete", "--shell", "bash" }, { stdout_file = bash })
  pax.os.exec(bin, { "complete", "--shell", "zsh" }, { stdout_file = zsh })
  pax.os.exec(bin, { "complete", "--shell", "fish" }, { stdout_file = fish })
  project:add_files({
    paxutil.bash_comp(bash, "tree-sitter"),
    paxutil.zsh_comp(zsh),
    paxutil.fish_comp(fish),
  })
end

return M
