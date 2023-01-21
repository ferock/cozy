
-- █▀▀ █▀█ █▄░█ ▀█▀ █▀▀ █▄░█ ▀█▀ █▀ 
-- █▄▄ █▄█ █░▀█ ░█░ ██▄ █░▀█ ░█░ ▄█ 

-- Textbox showing log entry contents and a scrollbar, as well as a list of tags.

local wibox   = require("wibox")
local gears   = require("gears")
local beautiful   = require("beautiful")
local colorize    = require("helpers.ui").colorize_text
local xresources  = require("beautiful.xresources")
local core        = require("helpers.core")
local dpi     = xresources.apply_dpi
local journal = require("core.system.journal")

-- █░█ █ 
-- █▄█ █ 

local title_wibox = wibox.widget({
  font    = beautiful.alt_med_font,
  widget  = wibox.widget.textbox,
})

local datetime_wibox = wibox.widget({
  widget  = wibox.widget.textbox,
})

local contents_wibox = wibox.widget({
  id      = "texbox",
  text    = "placeholder",
  widget  = wibox.widget.textbox,
})

local tag_subheader = wibox.widget({
  markup = colorize("Tags", beautiful.main_accent),
  widget = wibox.widget.textbox,
})

local tag_list = wibox.widget({
  spacing = dpi(8),
  layout  = wibox.layout.fixed.horizontal,
  ----
  add_tag = function(self, tagtext)
    local tag = wibox.widget({
      {
        {
          markup = colorize(tagtext, beautiful.fg),
          widget = wibox.widget.textbox,
        },
        margins = dpi(5),
        widget = wibox.container.margin,
      },
      bg = beautiful.bg_l2,
      shape  = gears.shape.rounded_rect,
      widget = wibox.container.background,
    })
  self:add(tag)
  end
})

local header_and_contents_container = wibox.widget({
  { -- Header
    title_wibox,
    nil,
    datetime_wibox,
    layout = wibox.layout.align.horizontal,
  },
  contents_wibox,
  { -- Separator
    {
      color = beautiful.bg_l3,
      forced_height = dpi(5),
      widget = wibox.widget.separator,
    },
    bottom = dpi(5),
    widget = wibox.container.margin,
  },
  { -- Tags
    tag_subheader,
    tag_list,
    spacing = dpi(10),
    layout  = wibox.layout.fixed.horizontal,
  },
  spacing = dpi(5),
  layout = wibox.layout.fixed.vertical,
  visible = false,
})

local contents_container = wibox.widget({
  {
    {
      header_and_contents_container,
      margins = dpi(15),
      widget  = wibox.container.margin,
    },
    forced_width = dpi(1000),
    bg      = beautiful.dash_widget_bg,
    shape   = gears.shape.rounded_rect,
    widget  = wibox.container.background,
  },
  valign = "top",
  widget = wibox.container.place,
})

-- █▄▄ ▄▀█ █▀▀ █▄▀ █▀▀ █▄░█ █▀▄ 
-- █▄█ █▀█ █▄▄ █░█ ██▄ █░▀█ █▄▀ 

-- Find all tagged words (by jrnl default they start with @) and add to tag list
-- Also change color of all tags found
local function create_taglist(stdout)
  local new_stdout = stdout

  for tag in string.gmatch(stdout, "@[%a%d]+") do
    local colortag = colorize(tag, beautiful.main_accent)
    new_stdout = new_stdout:gsub(tag, colortag)
    tag_list:add_tag(tag)
  end

  return new_stdout
end

local function update_contents(title, date, time, stdout)
  tag_list:reset()
  local new_stdout = create_taglist(stdout)

  local markup
  markup = colorize(title, beautiful.main_accent)
  title_wibox:set_markup_silently(markup)

  markup = colorize(time .. " " .. date, beautiful.main_accent)
  datetime_wibox:set_markup_silently(markup)

  contents_wibox:set_markup_silently(colorize(new_stdout, beautiful.fg))
end

journal:connect_signal("lock", function()
  header_and_contents_container.visible = false
end)

journal:connect_signal("ready::entry_contents", function(_, index, stdout)
  local entry = journal:get_entry(index)
  local title = entry[journal.title]
  local date  = entry[journal.date]
  local time  = entry[journal.time]
  update_contents(title, date, time, stdout)
  header_and_contents_container.visible = true
end)

return function()
  return contents_container
end
