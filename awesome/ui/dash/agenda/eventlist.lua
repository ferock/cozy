
-- █░█ █▀█ █▀▀ █▀█ █▀▄▀█ █ █▄░█ █▀▀ 
-- █▄█ █▀▀ █▄▄ █▄█ █░▀░█ █ █░▀█ █▄█ 

-- View upcoming events.

local wibox = require("wibox")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local navbg = require("modules.keynav.navitem").Background
local dpi = xresources.apply_dpi
local cal = require("core.system.cal")
local area    = require("modules.keynav.area")
local navtext = require("modules.keynav.navitem").Textbox
local box = require("helpers.ui").create_boxed_widget
local colorize = require("helpers.ui").colorize_text
local prompt   = require("ui.dash.agenda.prompt")

local MAX_EVENTS_SHOWN = 23

local MONTH_NAMES = { "January", "February", "March", "April", "May",
  "June", "July", "August", "September", "October", "November", "December" }

-- Keyboard navigation
local nav_events = area({
  name = "events",
  keys = require("ui.dash.agenda.commands"),
  circular = true,
})

-- Assemble a single event box and its corresponding keynav items
local function create_event(event)
  local title     = event[cal.TITLE]
  local date      = event[cal.START_DATE]
  local starttime = event[cal.START_TIME]
  local endtime   = event[cal.END_TIME]
  local place     = event[cal.LOCATION] or ""

  local displaytitle = title
  if string.find(title, "birthday") or string.find(title, "bday") then
    displaytitle = " " .. title
  end
  local name = wibox.widget({
    markup  = colorize(displaytitle, beautiful.fg),
    align   = "left",
    valign  = "top",
    font    = beautiful.font_name .. "11",
    ellipsize = "end",
    forced_height = 15,
    forced_width = 220,
    widget  = wibox.widget.textbox,
  })

  local time
  if starttime == "00:00" and starttime == endtime then
    time = "All day"
  else
    time = starttime .. " - " .. endtime
  end
  local times = wibox.widget({
    markup = colorize(time, beautiful.fg),
    align = "left",
    font    = beautiful.font_name .. "11",
    valign = "top",
    ellipsize = "end",
    forced_height = 15,
    forced_width  = 150,
    widget = wibox.widget.textbox,
  })

  local _place = wibox.widget({
    markup  = colorize(place, beautiful.fg),
    font    = beautiful.font_name .. "11",
    align   = "left",
    valign  = "top",
    ellipsize = "end",
    forced_height = 15,
    forced_width = 250,
    widget = wibox.widget.textbox,
  })

  local details = wibox.widget({
    name,
    times,
    _place,
    spacing = dpi(8),
    layout  = wibox.layout.fixed.horizontal,
  })

  local event_wibox = wibox.widget({
    details,
    widget = wibox.container.place
  })

  local navevent = navtext({
    widget = name,
    title  = title,
    date   = date,
    loc    = place,
  })
  function navevent:custom_on()  end
  function navevent:custom_off() end

  return event_wibox, navevent
end

local event_list_placeholder = wibox.widget({
  markup = colorize("No events found.", beautiful.fg),
  align  = "center",
  valign = "center",
  font   = beautiful.font_name .. "11",
  widget = wibox.widget.textbox,
})

local event_list = wibox.widget({
  event_list_placeholder,
  spacing = dpi(15),
  layout = wibox.layout.fixed.vertical,
  ----
  init = function(self)
    self:reset()
    self:add(event_list_placeholder)
  end
})

local datelist = wibox.widget({
  spacing = dpi(15),
  widget  = wibox.layout.fixed.vertical,
})

local function create_date_box(date)
  return wibox.widget({
    markup = colorize(cal:format_date(date), beautiful.fg),
    font   = beautiful.font_name .. "11",
    align  = "left",
    valign = "top",
    forced_width = 150,
    widget = wibox.widget.textbox,
  })
end

-- █▀ █ █▀▀ █▄░█ ▄▀█ █░░ █▀ 
-- ▄█ █ █▄█ █░▀█ █▀█ █▄▄ ▄█ 

cal:connect_signal("ready::upcoming", function()
  local upcoming = cal:get_upcoming_events()
  datelist:reset()
  event_list:init()
  nav_events:remove_all_items()
  nav_events:reset()

  if #upcoming == 0 then return end

  event_list:reset()

  -- Events are grouped by date.
  -- while event has same date as prev event, add to cureventbox
  -- if date != prevdate, add cureventbox to UI, then clear cureventbox and restart
  local cureventbox
  local prev_date = upcoming[1][cal.START_DATE]
  for i = 1, #upcoming do
    if i > MAX_EVENTS_SHOWN then break end

    local date = upcoming[i][cal.START_DATE]
    local entry, navevent= create_event(upcoming[i])

    -- Add to view
    if date ~= prev_date or i == MAX_EVENTS_SHOWN then
      if i == MAX_EVENTS_SHOWN then
        cureventbox:add(entry)
        nav_events:append(navevent)
        prev_date = date
      end

      local date_wibox = create_date_box(prev_date)
      local date_and_events = wibox.widget({
        date_wibox,
        cureventbox,
        spacing = dpi(15),
        layout = wibox.layout.fixed.horizontal,
      })
      event_list:add(date_and_events)
      cureventbox = nil
      prev_date = date
    end

    if not cureventbox then
      cureventbox = wibox.widget({
        spacing = dpi(15),
        layout = wibox.layout.fixed.vertical,
      })
    end

    cureventbox:add(entry)
    nav_events:append(navevent)
  end
end)

cal:connect_signal("input::request_get_info", function(_, type)
  local cur_navevent = nav_events:get_curr_item()
  cal.cur_title = cur_navevent.title
  cal.cur_date  = cur_navevent.date
  cal.cur_loc   = cur_navevent.loc
  cal:emit_signal("input::request", type)
end)

local header = wibox.widget({
  markup  = colorize("Upcoming Events", beautiful.fg),
  font    = beautiful.alt_large_font,
  align   = "center",
  valign  = "center",
  widget  = wibox.widget.textbox,
  -----
})

cal:connect_signal("selected::date", function(_, year, month, date)
  month = MONTH_NAMES[month]
  local mkup = colorize('From ' .. month .. ' ' .. date .. ' ' .. year, beautiful.fg)
  header:set_markup_silently(colorize(mkup, beautiful.fg))
end)

cal:connect_signal("deselected", function()
  local mkup = colorize("Upcoming Events", beautiful.fg)
  header:set_markup_silently(mkup)
end)

local widget = wibox.widget({
  header,
  wibox.widget({
    event_list,
    widget = wibox.container.place,
  }),
  -- wibox.widget({
  --   color = beautiful.bg_l3,
  --   forced_height = dpi(5),
  --   span_ratio = 0.95,
  --   widget = wibox.widget.separator,
  -- }),
  prompt,
  spacing = dpi(15),
  layout = wibox.layout.fixed.vertical,
})

local argh = box(widget, dpi(1000), dpi(700), beautiful.dash_widget_bg)
nav_events.widget = navbg({ widget = argh.children[1] })

return function()
  return argh, nav_events
end
