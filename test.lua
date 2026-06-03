local pax = require('pax')
local util = require('util')

local function fail(msg)
  print("Error: " .. msg)
  os.exit(1)
end

if util.libc() == nil or util.libc() == "" then
  fail("util.libc() returned empty value")
end

local v = pax.git.version()
assert(v ~= nil and v ~= "", "pax.git.version() should not be empty")

local info = util.os_release()
assert(info["ID"] ~= nil)
assert(info["NAME"] ~= nil)

pax.log("ok")
