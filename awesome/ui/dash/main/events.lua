
-- █▀▀ █░█ █▀▀ █▄░█ ▀█▀ █▀
-- ██▄ ▀▄▀ ██▄ █░▀█ ░█░ ▄█

-- Show upcoming events.

local wibox = require("wibox")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local colorize = require("helpers").ui.colorize_text
local wheader = require("helpers.ui").create_dash_widget_header
local box = require("helpers").ui.create_boxed_widget
local cal = require("core.system.cal")

------------------------------------

--- Inserts entry into events wibox.
-- @param date Event start date
-- @param time Event start time
-- @param desc Event title
local function create_calendar_entry(date, time, desc)
  local datetime_text = date .. " " .. time

  local datetime = wibox.widget({
    markup  = colorize(datetime_text, beautiful.fg),
    align   = "left",
    valign  = "center",
    font    = beautiful.base_small_font,
    widget  = wibox.widget.textbox,
  })

  local _desc = wibox.widget({
    markup  = colorize("   " .. desc, beautiful.fg),
    align   = "left",
    valign  = "center",
    font    = beautiful.base_small_font,
    widget  = wibox.widget.textbox,
  })

  return wibox.widget({
    datetime,
    _desc,
    layout = wibox.layout.fixed.horizontal,
  })
end

-- Uhows when there are no events to display
local placeholder = wibox.widget({
  markup  = colorize("No events found", beautiful.fg),
  align   = "center",
  valign  = "center",
  font    = beautiful.base_small_font,
  widget  = wibox.widget.textbox,
})

local header = wibox.widget({
  wheader("Events"),
  margins = dpi(5),
  widget = wibox.container.margin,
})

local events = wibox.widget({
  placeholder,
  spacing = dpi(3),
  layout = wibox.layout.flex.vertical,
})

-- Assemble final widget.
local events_widget = wibox.widget({
  {
    header,
    {
      events,
      widget = wibox.container.place,
    },
    layout = wibox.layout.fixed.vertical,
  },
  widget = wibox.container.margin,
  margins = dpi(5),
})

cal:connect_signal("ready::upcoming", function()
  local upcoming = cal:get_upcoming_events()
  if #upcoming > 0 then
    events:reset()
  end

  local max = 5
  for i = 1, #upcoming do
    if i > max then break end
    local date  = cal:format_date(upcoming[i][cal.START_DATE])
    local time  = upcoming[i][cal.START_TIME]
    local desc  = upcoming[i][cal.TITLE]
    local entry = create_calendar_entry(date, time, desc)
    events:add(entry)
  end
end)

return box(events_widget, dpi(0), dpi(190), beautiful.dash_widget_bg)
