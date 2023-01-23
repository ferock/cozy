
-- █▀▄▀█ █ █▀ █▀▀    █░█ █▀▀ █░░ █▀█ █▀▀ █▀█ █▀ 
-- █░▀░█ █ ▄█ █▄▄    █▀█ ██▄ █▄▄ █▀▀ ██▄ █▀▄ ▄█ 

local gtable = require("gears.table")
local task   = {}

local NUM_COMPONENTS = 4

function task:format_date(date, format)
  -- Taskwarrior returns due date as string
  -- Convert that to a lua timestamp
  local pattern = "(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)Z"
  local xyear, xmon, xday, xhr, xmin, xsec = date:match(pattern)
  local ts = os.time({
    year = xyear, month = xmon, day = xday,
    hour = xhr, min = xmin, sec = xsec })

  -- account for timezone (america/los_angeles: -8 hours)
  ts = ts - (8 * 60 * 60)

  format = format or '%A %B %d %Y'
  return os.date(format, ts)
end

function task:initializing()
  return not (self.inits_complete == NUM_COMPONENTS)
end

return function(_task)
  gtable.crush(_task, task, true)
end
