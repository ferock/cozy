
-- █▀▄ █▀▀ ▄▀█ █▀▄ █░░ █ █▄░█ █▀▀ █▀ 
-- █▄▀ ██▄ █▀█ █▄▀ █▄▄ █ █░▀█ ██▄ ▄█ 

-- TODO refactor using core

local beautiful = require("beautiful")
local colorize = require("helpers").ui.colorize_text
local wibox = require("wibox")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local awful = require("awful")
local json = require("modules.json")
local format_due_date = require("helpers").dash.format_due_date

local tasklist = wibox.widget({
  wibox.widget({
    markup = colorize("No tasks due this week. Yay!", beautiful.fg_sub),
    font   = beautiful.base_small_font,
    align  = "center",
    valign = "center",
    widget = wibox.widget.textbox,
  }),
  spacing = dpi(5),
  layout = wibox.layout.flex.vertical,
})

--- Creates a task wibox.
-- @param desc Task description.
-- @param due Task due date.
local function create_task(desc, due)
  local desc_wibox = wibox.widget({
    markup = colorize(desc, beautiful.fg),
    align = "left",
    ellipsize = "end",
    forced_width = dpi(290),
    widget = wibox.widget.textbox,
  })

  local formatted_due_date = format_due_date(due)
  local due_wibox = wibox.widget({
    markup = colorize(formatted_due_date, beautiful.task_due_fg),
    align = "right",
    widget = wibox.widget.textbox,
  })

  local task_wibox = wibox.widget({
    desc_wibox,
    nil,
    due_wibox,
    layout = wibox.layout.align.horizontal,
  })

  return task_wibox
end

--- Generate a list of tasks that are due this week, then
-- populate the tasklist wibox.
local function generate_tasklist()
  local cmd = "task +WEEK export rc.json.array=on"
  awful.spawn.easy_async_with_shell(cmd, function(stdout)
    local json_arr = json.decode(stdout)
    if #json_arr > 0 then tasklist:reset() end
    for i = 1, #json_arr do
      local desc = json_arr[i]["description"]
      local due = json_arr[i]["due"] or ""
      local task = create_task(desc, due)
      tasklist:add(task)
    end
  end)
end

generate_tasklist()

local widget = wibox.widget({
  wibox.widget({
    markup  = colorize("Due this week", beautiful.fg),
    font    = beautiful.alt_large_font,
    align   = "center",
    valign  = "center",
    widget  = wibox.widget.textbox,
  }),
  tasklist,
  spacing = dpi(10),
  layout  = wibox.layout.fixed.vertical,
})

return widget
