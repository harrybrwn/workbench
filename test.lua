local pax = require('pax')
local python = require('misc/python')

local files = python.build("3.14.0rc3", {
  disable_gil = true,
  prefix = "/usr/local",
})

pax.print(files)
