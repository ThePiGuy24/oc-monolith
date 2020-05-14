-- very heavily inspired by the default *nix Bourne shell --

-- reload shell and sh, else things break badly for unknown reasons
local shell = require("shell", true)
local sh = require("sh", true)
local readline = require("readline").readline

dofile("/etc/profile.lua")
local exit = false
local oexit = shell.exit
function shell.exit()
  shell.exit = oexit
  exit = true
  return true
end

if not require("filesystem").exists(os.getenv("HOME")) then
  shell.error("warning", "home directory does not exist")
  os.setenv("HOME", "/")
end

os.setenv("PWD", os.getenv("HOME"))
os.setenv("PS1", os.getenv("PS1") or "\\w\\$ ")
local ok, err = pcall(sh.execute, ".shrc")

local history = {}
while not exit do
  local cmd = readline({prompt = "\27[0m" .. sh.prompt(os.getenv("PS1")), history = history}):gsub("\n", "")
  if cmd ~= "" then
    pcall(function()shell.execute(cmd)end)
  end
end
