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

local function tableFilter(t, filterIter)
  local out = {}
  for k, v in pairs(t) do
    if filterIter(v, k, t) then out[k] = v end
  end
  return out
end

local openApplication = function(appId, windowId)
  if (type(appId) ~= 'string') then
    hs.logger.new('hyper'):e('Invalid application id ', appId)
    return
  end

  local application = windowId and hs.application.get(windowId)
  
  if application == nil then
    application = hs.application.get(appId)
  end

  -- First time we try to either open or focus on this application
  if application == nil or not application:isFrontmost() then
    hs.logger.new('hyper'):e('Opened application', appId)
    hs.application.open(appId)
    return
  end

  local allWindows = tableFilter(application:allWindows(), function(window)
    return not window:isMinimized()
  end)
  table.sort(allWindows, function(a, b) return a:id() < b:id() end)

  local windowsLength = tableLength(allWindows)

  -- If there are more than 1 windows for this application we try to focus
  -- the window on the next index.
  if (windowsLength > 1) then
    local focusedWindow = application:focusedWindow()
    local focusedIndex = tableFindIndex(
      allWindows,
      function(window) return window == focusedWindow end
    ) or -1
    hs.logger.new('hyper'):e('Focused index', focusedIndex, 'of', windowId)
    local nextIndex = (focusedIndex % windowsLength) + 1
    allWindows[nextIndex]:focus()
  else
    hs.logger.new('hyper'):e('There\'s only one window of', windowId or appId)
  end
end

for _, mapping in ipairs(hyperModeAppMappings) do
  local key = mapping[1]
  local appId = mapping[2]
  local windowId = mapping[3]
  hs.hotkey.bind({ 'shift', 'ctrl', 'alt', 'cmd' }, key, function()
    openApplication(appId, windowId)
  end)
end

return {
  openApplication = openApplication
}
