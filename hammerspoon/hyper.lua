local status, hyperModeAppMappings = pcall(require, 'keyboard.hyper-apps')

if not status then
  hyperModeAppMappings = require('keyboard.hyper-apps-defaults')
end

-- local function dump(o)
--   if type(o) == 'table' then
--     local s = '{ '
--     for k,v in pairs(o) do
--       if type(k) ~= 'number' then k = '"'..k..'"' end
--       s = s .. '['..k..'] = ' .. dump(v) .. ','
--     end
--     return s .. '} '
--   else
--     return tostring(o)
--   end
-- end

local function tableLength(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

local function tableFindIndex(t, fn)
  for i, item in ipairs(t) do
    if (fn(item, i)) then
      return i
    end
  end
  return nil
end

local function tableMap(tbl, f)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = f(v)
  end
  return t
end

local function tableIsShallowEqual(t1, t2)
  if tableLength(t1) ~= tableLength(t2) then
    return false
  end
  for k, item in pairs(t1) do
    if item ~= t2[k] then
      return false
    end
  end
  return true
end

local function windowIsShallowEqual(t1, t2)
  t1 = tableMap(t1, function(t) return t:id() end)
  t2 = tableMap(t2, function(t) return t:id() end)
  table.sort(t1)
  table.sort(t2)
  return tableIsShallowEqual(t1, t2)
end

for _, mapping in ipairs(hyperModeAppMappings) do
  local key = mapping[1]
  local app = mapping[2]

  -- We have to keep a reference to the table containing all windows because
  -- the table returned by application:allWindows() keeps changing its order.
  -- I think it returns an array ordered by their z-index.
  -- By keeping the original order we are able to properly cycle through the
  -- available windows.
  local allWindows = nil

  hs.hotkey.bind({'shift', 'ctrl', 'alt', 'cmd'}, key, function()
    if (type(app) == 'function') then
      app()
      return
    end
    if (type(app) ~= 'string') then
      hs.logger.new('hyper'):e('Invalid mapping for Hyper +', key)
      return
    end

    local application = hs.application.get(app)

    -- First time we try to either open or focus on this application
    if application == nil or not application:isFrontmost() then
      allWindows = nil
      application = hs.application.open(app, nil, true)
      if application ~= nil then
        allWindows = application:allWindows()
      end
      return
    end

    -- If for some reason allWindows is not properly set on the previous call
    -- Or if we currently have more or less windows than when we
    -- created allWindows.
    if allWindows == nil or not windowIsShallowEqual(allWindows, application:allWindows()) then
      allWindows = application:allWindows()
    end

    local windowsLength = tableLength(allWindows)

    -- If there are more than 1 windows for this application we try to focus
    -- the window on the next index.
    if (windowsLength > 1) then
      local focusedWindow = application:focusedWindow()
      local focusedIndex = tableFindIndex(allWindows, function(window) return window == focusedWindow end) or 0
      local nextIndex = (focusedIndex % windowsLength) + 1
      allWindows[nextIndex]:focus()
    end
  end)
end
