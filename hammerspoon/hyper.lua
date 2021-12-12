local status, hyperModeAppMappings = pcall(require, 'keyboard.hyper-apps')

if not status then
  hyperModeAppMappings = require('keyboard.hyper-apps-defaults')
end

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
    if (type(app) == 'string') then
      local application = hs.application.get(app)

      -- First time we try to either open or focus on this application
      if application == nil or not application:isFrontmost() then
        application = hs.application.open(app, nil, true)
        allWindows = nil
        if application ~= nil then
          allWindows = application:allWindows()
        end
        return
      end

      -- If for some reason allWindows is not properly set on the previous call
      if allWindows == nil then
        allWindows = application:allWindows()
      end

      local windowsLength = tableLength(allWindows)
      if (windowsLength > 1) then
        local focusedWindow = application:focusedWindow()
        local focusedIndex = tableFindIndex(allWindows, function(window) return window == focusedWindow end)
        local nextIndex = (focusedIndex % windowsLength) + 1
        allWindows[nextIndex]:focus()
      end

    elseif (type(app) == 'function') then
      app()
    else
      hs.logger.new('hyper'):e('Invalid mapping for Hyper +', key)
    end
  end)
end
