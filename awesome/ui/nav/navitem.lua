
-- █▄░█ ▄▀█ █░█ █ ▀█▀ █▀▀ █▀▄▀█ 
-- █░▀█ █▀█ ▀▄▀ █ ░█░ ██▄ █░▀░█ 

-- Class definitions for making widgets navigable
-- with the keyboard

local beautiful = require("beautiful")

-- █▄▄ ▄▀█ █▀ █▀▀ 
-- █▄█ █▀█ ▄█ ██▄ 
-- Only responsible for defining basic vars
-- Functions must be overridden in derived classes
local Base = {}
function Base:new(widget)
  local o = {}
  o.widget      = widget
  o.selected    = false
  o.is_area     = false
  o.is_navitem  = true
  o.visited     = false
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Override these 3 functions in your custom definition.
function Base:select_on()      end
function Base:select_off()     end
function Base:release()    end

function Base:select_toggle()
  if self.selected then
    self:select_off()
  else
    self:select_on()
  end
end

-- █▀▀ █░░ █▀▀ █░█ ▄▀█ ▀█▀ █▀▀ █▀▄ 
-- ██▄ █▄▄ ██▄ ▀▄▀ █▀█ ░█░ ██▄ █▄▀ 
local Elevated = Base:new(widget)

function Elevated:select_on()
  self.selected = true
  self.widget:nav_hl_on()
end

function Elevated:select_off()
  self.selected = false
  self.widget:nav_hl_off()
end

function Elevated:release()
  self.widget:nav_release()
end

-- █░█ ▄▀█ █▄▄ █ ▀█▀ █▀ 
-- █▀█ █▀█ █▄█ █ ░█░ ▄█ 
local Habit = Base:new(widget)

function Habit:select_on()
  self.selected = true
  local box = self.widget.children[1]
  box.check_color = "#bf616a"
  box.bg = "#bf616a"
end

function Habit:select_off()
  self.selected = false
  local box = self.widget.children[1]
  box.bg = not box.checked and beautiful.hab_uncheck_bg
  box.check_color = beautiful.hab_check_bg
end

function Habit:release()
  self.widget:emit_signal("button::press")
end

-- █▀▄ ▄▀█ █▀ █░█    █░█░█ █ █▀▄ █▀▀ █▀▀ ▀█▀ 
-- █▄▀ █▀█ ▄█ █▀█    ▀▄▀▄▀ █ █▄▀ █▄█ ██▄ ░█░ 
local Dashwidget = Base:new(widget)

function Dashwidget:select_on()
  self.selected = true
  self.widget.children[1].bg = beautiful.surface0
end

function Dashwidget:select_off()
  self.selected = false
  self.widget.children[1].bg = beautiful.dash_widget_bg
end

-- █▀▄ ▄▀█ █▀ █░█    ▀█▀ ▄▀█ █▄▄ █▀ 
-- █▄▀ █▀█ ▄█ █▀█    ░█░ █▀█ █▄█ ▄█ 
local Dashtab = Base:new(widget)

function Dashtab:select_on()
  self.selected = true
  self.widget:set_color(beautiful.main_accent)
  self.widget:nav_release()
  self.widget:nav_hl_on()
end

function Dashtab:select_off()
  self.selected = false
  self.widget:nav_hl_off()
  self.widget:set_color(beautiful.dash_tab_fg)
end

function Dashtab:release()
  self.widget:nav_release()
end

-- Return class definitions
return {
  Elevated = Elevated,
  Habit = Habit,
  Dashtab = Dashtab,
  Dashwidget = Dashwidget,
}
