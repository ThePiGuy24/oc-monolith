-- basic automated documentation generation for components using their builtin tostring features --
--[[ Copyright (C) 2020 Ocawesome101

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details. ]]

local component = require("component")
local shell = require("shell")
local pager = os.getenv("MANPAGER") or "/bin/less.lua"

local function view(file)
  shell.execute(pager, file)
end

local args, opts = shell.parse(...)

if opts.help or #args < 1 then
  print([[
cdoc copyright (c) 2020 Ocawesome101 under the GNU GPLv3.
Automated component documentation generation using their built-in tostring() functionality. May not work fully in some emulators.

usage:
  cdoc [--<help|verbose>|-v] COMPONENTTYPE

  Outputs a text file consisting of basic documentation for the specified component, if installed.
]])
  return 1
end

local ctype = args[1]

local comp = component[ctype]

local outfile = io.open("/tmp/cdoc_" .. ctype, "w")
if not outfile then
  shell.error("cdoc", "failed opening output file")
  return shell.codes.failure
end
print("Generating documentation....")
outfile:write("Auto-generated documentation: component." .. ctype .. "\n\nGenerated by cdoc. I make NO GUARANTEES as to the quality of this documentation.\n\n")
for k, v in pairs(comp) do
  if k ~= "type" and k ~= "address" and k ~= "slot" then
    if verbose then
      print("METHOD", k)
    end
    outfile:write(tostring(v):gsub(" %-%- ?", "\n  "):gsub("function", ctype .. "." .. k) .. "\n\n")
  elseif verbose then
    print("SKIP", k)
  end
end
outfile:close()
view("/tmp/cdoc_" .. ctype)
