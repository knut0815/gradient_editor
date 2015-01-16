
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- gui_slider object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local gui_slider = {}
gui_slider.table = 'gui_slider'
gui_slider.parent = nil
gui_slider.name = nil
gui_slider.x = nil
gui_slider.y = nil
gui_slider.width = nil
gui_slider.height = nil
gui_slider.bbox = nil
gui_slider.min = nil
gui_slider.max = nil

gui_slider.value = 0              -- between 0 and 1
gui_slider.callback_value = 0     -- between min and max
gui_slider.value_callback = nil   -- calback function

gui_slider.mouse_clicked = false
gui_slider.is_active = false

-- sliding bar
gui_slider.bar_bbox = nil
gui_slider.bar_width = 25
gui_slider.bar_height = 10



local gui_slider_mt = { __index = gui_slider }
function gui_slider:new(x, y, width, height, min, max, callback, name, parent)
  local name = name or "undefined"

  local bbox = bbox:new(x, y, width, height)
  
  local bar_bbox = bbox:new(x, y, gui_slider.bar_width, gui_slider.bar_height)
  return setmetatable({ bbox = bbox,
                        bar_bbox = bar_bbox,
                        min = min,
                        max = max,
                        value_callback = callback,
                        name = name}, gui_slider_mt)
end


function gui_slider:set_value(value)
    value = math.min(value, self.max)
    value = math.max(value, self.min)
    
    self.callback_value = value
    self.value = (value - self.min) / (self.max - self.min)
end

function gui_slider:get_value()
    return self.callback_value
end

------------------------------------------------------------------------------
function gui_slider:update(dt)
  -- check if slider should be activated
  local mpos = vector2:new(love.mouse.getPosition())
  if love.mouse.isDown('l') and not self.mouse_clicked then
    self.mouse_clicked = true
    if self.bbox:contains_point(mpos) or self.bar_bbox:contains_point(mpos) then
      self.is_active = true
    end
  elseif not love.mouse.isDown('l') then
    self.is_active = false
    self.mouse_clicked = false
  end

  -- calc value of slider
  if self.is_active then
    -- 0 to 1 value
    self.value = 1 - ((mpos.y - self.bbox.y) / self.bbox.height)
    self.value = math.min(self.value, 1)
    self.value = math.max(self.value, 0)
    
    -- min to max value
    local new_value = self.min + self.value * (self.max - self.min)
    local value_changed = new_value ~= self.callback_value
    self.callback_value = new_value
        
    if value_changed and self.value_callback then
      if self.parent then
        self.value_callback(self.parent, self.name, self.callback_value)
      else
        self.value_callback(self.name, self.callback_value)
      end
    end
  end

end

------------------------------------------------------------------------------
function gui_slider:draw()
  -- draw outline
  local x, y = self.bbox.x, self.bbox.y
  local w, h = self.bbox.width, self.bbox.height
  
  lg.setColor(0, 0, 255, 150)
  if self.is_active then
    lg.setColor(255, 0, 0, 150)
  end
  lg.rectangle('line', x, y, w, h)
  lg.line(x + 0.5 * w, y, x + 0.5 * w, y + h)
  
  -- draw sliding bar
  local sval = self.value
  local bar_bbox = self.bar_bbox
  local barw, barh = bar_bbox.width, bar_bbox.height
  local barx = x + 0.5 * w - 0.5 * barw
  local bary = y - 0.5 * barh + (1 - sval) * h
  bar_bbox.x, bar_bbox.y = barx, bary
  
  
  
  lg.setColor(0, 0, 255, 200)
  lg.rectangle('fill', barx, bary, barw, barh)
  
  -- draw value text
  local px, py = x, y - 20
  local value = 0
  if self.max - self.min < 20 then       -- display as float
    local digits = 2
    value = math.floor(self.callback_value * 10^digits) / (10^digits)
  else
    value = math.floor(self.callback_value)
  end
    lg.print(self.name..": "..value, px, py)
end

return gui_slider


















