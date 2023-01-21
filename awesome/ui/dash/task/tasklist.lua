
-- ▀█▀ ▄▀█ █▀ █▄▀ █░░ █ █▀ ▀█▀
-- ░█░ █▀█ ▄█ █░█ █▄▄ █ ▄█ ░█░

local beautiful   = require("beautiful")
local wibox       = require("wibox")
local xresources  = require("beautiful.xresources")
local gears       = require("gears")
local keynav      = require("modules.keynav")
local colorize    = require("helpers.ui").colorize_text
local format_due_date = require("helpers.dash").format_due_date
local dpi   = xresources.apply_dpi
local task  = require("core.system.task")

local MAX_TASKS_SHOWN = 21
local MAX_TASKLIST_HEIGHT = dpi(580)

local first_position_index = 1

-- █░█ █ 
-- █▄█ █ 

-- These overflow containers are for UI elements only, not navitems
local overflow_top    = {}
local overflow_bottom = {}

local function total_overflow()
  return #overflow_top + #overflow_bottom
end

local tasklist = wibox.widget({
  spacing = dpi(8),
  layout = wibox.layout.fixed.vertical,
})

-- Maximum and handle_width are set later
local scrollbar = wibox.widget({
  {
    id            = "bar",
    value         = 0,
    forced_height = dpi(5), -- since it's rotated, this is width
    bar_color     = beautiful.task_scrollbar_bg,
    handle_color  = beautiful.task_scrollbar_fg,
    handle_border_width = 0,
    bar_shape     = gears.shape.rounded_rect,
    widget        = wibox.widget.slider,
  },
  direction = "west",
  widget    = wibox.container.rotate,
})

local scrollbar_cont = wibox.widget({
  scrollbar,
  right   = dpi(15),
  visible = total_overflow() > 0,
  widget  = wibox.container.margin,
})

local tasklist_widget = wibox.widget({
  {
    scrollbar_cont,
    tasklist,
    layout = wibox.layout.align.horizontal,
  },
  height = MAX_TASKLIST_HEIGHT,
  widget = wibox.container.constraint,
})

-- █▄▄ ▄▀█ █▀▀ █▄▀ █▀▀ █▄░█ █▀▄ 
-- █▄█ █▀█ █▄▄ █░█ ██▄ █░▀█ █▄▀ 

-- UI element generation and keynav ------------------------
local nav_tasklist = keynav.area({
  name = "nav_tasklist",
  keys = require("ui.dash.task.tasklist_keybinds"),
  circular = true
})

--- Creates a single task wibox.
local function create_task_wibox(task_table)
  local desc  = task_table["description"]
  local due   = task_table["due"] or ""
  local start = task_table["start"]
  local wait  = task_table["wait"]

  desc = desc:gsub("%^l", string.upper)
  local taskname_color = (start and beautiful.green) or (wait and beautiful.fg_sub) or beautiful.fg
  local taskname = wibox.widget({
    markup = colorize(desc, taskname_color),
    font = beautiful.base_small_font,
    ellipsize = "end",
    widget = wibox.widget.textbox,
  })

  local due_text = format_due_date(due)
  local due_color = task_table["urgency"] > 7 and beautiful.red or beautiful.fg_sub
  local due_ = wibox.widget({
    markup = colorize(due_text, due_color),
    font   = beautiful.base_small_font,
    halign = "right",
    align  = "center",
    widget = wibox.widget.textbox,
  })

  return wibox.widget({
    taskname,
    nil,
    due_,
    forced_height = dpi(20),
    layout = wibox.layout.align.horizontal,
  })
end

local function create_task_nav(task_wibox, task_table, index)
  return keynav.navitem.textbox({
    widget = task_wibox.children[1], -- highlight description only
    index  = index,
    fg_off = (task_table["start"] and beautiful.green)
      or (task_table["wait"] and beautiful.fg_sub) or beautiful.fg,
    custom_on = function(self)
      task:set_focused_task(task_table, self.index)
      task:emit_signal("selected::task")
    end,
  })
end

--- note from a month later: dont really understand this anymore lol but it works
-- Handles switching to the correct index after redrawing because a task
-- was added/deleted/completed
local function update_wibox_index()
  if task.need_switch_index then
    task:emit_signal("tasklist::switch_index", task.switch_index)
    task.need_switch_index = false
  end
end

-- Scrollbar ------------------------
local function scroll_up()
  local bar = scrollbar.children[1]
  bar.value = bar.value - 1
  first_position_index = first_position_index - 1

  -- For scroll up, the last task gets hidden
  -- Prepend to overflow_bottom buffer
  local last_task_shown
  if #tasklist.children > (first_position_index + 20) then
    last_task_shown = first_position_index + MAX_TASKS_SHOWN - 1
  else
    last_task_shown = #tasklist.children
  end
  table.insert(overflow_bottom, 1, tasklist.children[last_task_shown])
  tasklist:remove(#tasklist.children)

  -- Prepend last task from overflow_top to tasklist 
  tasklist:insert(1, overflow_top[#overflow_top])
  table.remove(overflow_top, #overflow_top)
end

local function scroll_down()
  local bar = scrollbar.children[1]
  bar.value = bar.value + 1
  first_position_index = first_position_index + 1

  -- When scrolling down, the first visible task gets hidden
  -- Append to overflow_top buffer
  overflow_top[#overflow_top+1] = tasklist.children[1]
  tasklist:remove(1)

  -- Append the first task from overflow_bottom 
  tasklist:add(overflow_bottom[1])
  table.remove(overflow_bottom, 1)
end

local function jump_top()
  while #overflow_top > 0 do
    scroll_up()
  end

  nav_tasklist:set_curr_item(#overflow_top + 1)
end

local function jump_end()
  -- is this necessary? idk
  nav_tasklist:set_curr_item(#task:get_pending_tasks() - #overflow_bottom)

  while #overflow_bottom > 0 do
    scroll_down()
  end
  nav_tasklist:set_curr_item(#task:get_pending_tasks())
end

local function update_scrollbar(num_tasks)
  if not num_tasks then return end
  local scrollbar_height = ((MAX_TASKS_SHOWN / num_tasks) * MAX_TASKLIST_HEIGHT)
  local maximum = (total_overflow() > 1 and total_overflow()) or 1

  local bar = scrollbar.children[1]
  bar.handle_width  = scrollbar_height
  bar.maximum       = maximum
  scrollbar_cont.visible  = true
end

-- █▀ █ █▀▀ █▄░█ ▄▀█ █░░ █▀ 
-- ▄█ █ █▄█ █░▀█ █▀█ █▄▄ ▄█ 

--- Draw all tasks for a project
task:connect_signal("tasklist::update", function(_, tag, project)
  tasklist:reset()
  nav_tasklist:reset()
  overflow_top    = {}
  overflow_bottom = {}

  local json_tasklist = task.tags[tag].projects[project].tasks
  for i = 1, #json_tasklist do
    local task_wibox = create_task_wibox(json_tasklist[i])
    local ntask = create_task_nav(task_wibox, json_tasklist[i], i)

    if json_tasklist[i]["wait"] and not task.show_waiting then
      goto continue
    end

    nav_tasklist:append(ntask)
    if i > MAX_TASKS_SHOWN then
      overflow_bottom[#overflow_bottom+1] = task_wibox
    else
      tasklist:add(task_wibox)
    end

    ::continue::
  end

  -- Scrollbar UI
  if #json_tasklist > MAX_TASKS_SHOWN then
    update_scrollbar(#json_tasklist)
  else
    scrollbar_cont.visible = false
  end

  -- Restore position on reload
  if task.restore_required then
    task.restore_required = false
    if #nav_tasklist.items < task.task_index then
      task.task_index = #nav_tasklist.items
    end
    nav_tasklist:set_curr_item(task.task_index)
    nav_tasklist.nav:set_area("tasklist")
  end

  update_wibox_index()
end)

-- Determine which new tasks to show when scrolling
task:connect_signal("selected::task", function()
  if total_overflow() == 0 then return end

  local last_position_index = first_position_index + MAX_TASKS_SHOWN - 1
  local index     = task:focused_task_index()
  local old_index = task:old_focused_task_index()
  local gap = math.abs(index - old_index)
  local pending_tasks = #task.tags[task.focused_tag].projects[task.focused_project].tasks -- ew

  if index == 1 and gap > 1 then
    if first_position_index == 1 then return end
    jump_top()
  elseif index == pending_tasks and gap > 1 then
    if first_position_index == #task:get_pending_tasks() then return end
    jump_end()
  elseif index < first_position_index then
    scroll_up()
  elseif index > last_position_index then
    scroll_down()
  end
end)

return function()
  return tasklist_widget, nav_tasklist
end
