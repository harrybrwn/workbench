local pax = require('pax')
local util = require('util')


local function build(version, opts)
  local v = version or "3.14.0"
  local nogil = opts.disable_gil or false
  util.clone({
    repo = "git@github.com:python/cpython.git",
    depth = 1,
    branch = "v" .. version,
  })

  local configure_flags = {
    "--enable-optimizations",
    "--enable-loadable-sqlite-extensions",
  }
  if nogil then
    table.insert(configure_flags, "--disable-gil")
  end
  local prefix = "/usr/local"
  if opts.prefix then
    prefix = opts.prefix
    table.insert(configure_flags, string.format("--prefix=%s", opts.prefix))
  end

  pax.in_dir("./.pax/repos/cpython", function()
    pax.sh(string.format([[
      ./configure %s
      make
    ]], table.concat(configure_flags, " ")))

    pax.in_dir("./Doc", function()
      pax.sh [[
        make venv changes
      ]]
    end)
  end)

  local function f(path)
    return string.format(".pax/repos/cpython/%s", path)
  end

  -- TODO: Add /usr/local/share/binfmts/python3.14
  --
  --  package python3.13
  --  interpreter /usr/bin/python3.13
  --  magic \xf3\x0d\x0d\x0a

  local bin = prefix .. "/bin/python" .. version
  return {
    { src = f("python"), dst = bin },
    -- TODO { src = bin,         dst = prefix .. "/bin/python", symlink = true },
    {
      src = f("Misc/python.man"),
      dst = prefix .. "/share/man/man1/python.1"
    },
    {
      src = f("Doc/build/NEWS"),
      dst = prefix .. "/share/doc/python" .. version .. "/changelog"
    },
  }
end

return {
  build = build,
}
