-- getty implementation --

local thread = require("thread")
local component = require("component")
local computer = require("computer")
local vt100 = require("vt100")
local stream = require("stream")
local config = require("config")

local cfg = config.load("/etc/getty.conf", {start = "/sbin/login.lua"})
local login = cfg.start or "/sbin/login.lua"

local getty = {}

local gpus, screens, dinfo = {}, {}, {}
local streams = {}

local function nextGPU(res)
  local match = {}
  for k, v in pairs(gpus) do
    if not v.bound then
      match[v.res] = match[v.res] or k
    end
  end

  return match[res] or match[8000] or match[800] or match[200]
end

local function nextScreen(res)
  local match = {}
  for k, v in pairs(screens) do
    if not v.bound then
      match[v.res] = match[v.res] or k
    end
  end

  return match[res] or match[8000] or match[800] or match[200]
end

function getty.scan()
  dinfo = computer.getDeviceInfo()
  for addr, _ in component.list("gpu") do
    gpus[addr] = gpus[addr] or {bound = false, res = tonumber(dinfo[addr].capacity)}
  end

  for addr, _ in component.list("screen") do
    screens[addr] = screens[addr] or {bound = false, res = tonumber(dinfo[addr].capacity)}
  end

  for addr, p in pairs(gpus) do
    if not dinfo[addr] then
      if p.bound then
        thread.signal(p.bound, thread.signals.kill)
      end
      gpus[addr] = nil
    end
  end

  for addr, p in pairs(screens) do
    if not dinfo[addr] then
      if p.bound then
        thread.signal(p.bound, thread.signals.kill)
      end
      screens[addr] = nil
    end
  end

  while true do
    local gpu, screen = nextGPU(), nextScreen()
    if gpu and screen then
      local sr, sw, sc = vt100.session(gpu, screen)
      local ios = stream.new(sr, sw, sc)
      local ok, err = loadfile(login)
      if not ok then
        error(err)
      end
      local pid = thread.spawn(ok, login, nil, nil, ios, ios)
      gpus[gpu].bound = pid
      screens[screen].bound = pid
    else
      break
    end
--    thread.ipc(pid, "components", gpu, screen) -- give the process info about the GPU and screen, useful for things like GUIs
  end
end

getty.scan()

while true do
  local sig, pid, res = coroutine.yield()
  if sig == "thread_errored" then
    error(pid .. ": " .. res)
  end
  if sig == "component_added" or sig == "component_removed" then
    getty.scan()
  end
end