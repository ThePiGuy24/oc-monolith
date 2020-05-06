-- mostly mappings of users to names --

local users = {}

local protect = require("protect")
local config = require("config")
local sha3 = require("sha3")

local old = kernel.users

old.sha = sha3
old.passwd = config.load("/etc/passwd")

local function getuid(name)
  if type(name) == "number" then
    return name
  end
  for uid, data in pairs(old.passwd) do
    if data.n == name then
      return uid
    end
  end
  return -1
end

function users.login(user, password)
  checkArg(1, user, "string", "number")
  checkArg(2, password, "string")
  local uid = getuid(user)
  local ok, err = old.login(uid, password)
  if ok then
    os.setenv("USER", old.passwd[uid].n)
    os.setenv("UID", uid)
    os.setenv("HOME", old.passwd[uid].h)
    os.setenv("SHELL", old.passwd[uid].s)
  end
  return ok, err
end

function users.logout()
  return old.logout()
end

function users.uid()
  return old.uid()
end

function users.add(name, password, cansudo)
  checkArg(1, name, "string")
  checkArg(2, password, "string")
  checkArg(3, cansudo, "boolean", "nil")
  local uid = old.add(password, cansudo)
  passwd[uid].n = name
end

function users.del(user)
  checkArg(1, user, "string", "number")
  local uid = getuid(user)
  return old.del(user)
end

function users.home()
  return os.getenv("HOME")
end

function users.shell()
  return os.getenv("SHELL")
end

return protect(users)