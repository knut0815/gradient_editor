
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- color_widget object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local color_widget = {}
color_widget.table = 'color_widget'
color_widget.x = nil
color_widget.y = nil
color_widget.width = 200
color_widget.height = 800
color_widget.bbox = nil
color_widget.callback_func = nil

color_widget.slider_r = nil
color_widget.slider_g = nil
color_widget.slider_b = nil
color_widget.slider_h = nil
color_widget.slider_s = nil
color_widget.slider_l = nil

color_widget.color = nil

local color_widget_mt = { __index = color_widget }
function color_widget:new(x, y, callback_func)
  local width, height = color_widget.width, color_widget.height
  local bbox = bbox:new(x, y, width, height)
  
  s_width = 40
  s_height = 200
  
  local sy = y + 225
  local s1x = x + (width / 4) - 0.5 * s_width - 10
  local s2x = x + (width / 2) - 0.5 * s_width
  local s3x = x + (width / 4) * 3 - 0.5 * s_width + 10
  
  local callback = color_widget.value_changed
  local slider_r = gui_slider:new(s1x, sy, s_width, s_height, 0, 255, callback, "R")
  local slider_g = gui_slider:new(s2x, sy, s_width, s_height, 0, 255, callback, "G")
  local slider_b = gui_slider:new(s3x, sy, s_width, s_height, 0, 255, callback, "B")
  
  slider_r:set_value(255/2)
  slider_g:set_value(255/2)
  slider_b:set_value(255/2)
  
  sy = sy + s_height + 50
  local slider_h = gui_slider:new(s1x, sy, s_width, s_height, 0, 360, callback, "H")
  local slider_s = gui_slider:new(s2x, sy, s_width, s_height, 0, 1, callback, "S")
  local slider_l = gui_slider:new(s3x, sy, s_width, s_height, 0, 1, callback, "L")
  
  local color = {0, 0, 0, 0}
  
  local object = setmetatable({x = x,
                             y = y,
                             bbox = bbox,
                             slider_r = slider_r, 
                             slider_g = slider_g, 
                             slider_b = slider_b,
                             slider_h = slider_h, 
                             slider_s = slider_s, 
                             slider_l = slider_l,
                             color = color,
                             callback_func = callback_func}, color_widget_mt)
  
  slider_r.parent = object
  slider_g.parent = object
  slider_b.parent = object
  slider_h.parent = object
  slider_s.parent = object
  slider_l.parent = object
                             
  return object
  
end

function color_widget:value_changed(name, value)

  if name == "R" or name == "G" or name == "B" then
    local r = self.slider_r:get_value()
    local g = self.slider_g:get_value()
    local b = self.slider_b:get_value()
    
    local h, s, l = self:rgb_to_hsl(r, g, b)
    self.slider_h:set_value(h)
    self.slider_s:set_value(s)
    self.slider_l:set_value(l)
    
  else
    local h = self.slider_h:get_value()
    local s = self.slider_s:get_value()
    local l = self.slider_l:get_value()
    
    local r, g, b = self:hsl_to_rgb(h, s, l)
    self.slider_r:set_value(r)
    self.slider_g:set_value(g)
    self.slider_b:set_value(b)
  end
  
  if self.callback_func then
    if self.parent then
      self.callback_func(self.parent, name, value)
    else
      self.callback_func(name, value)
    end
  end
end

------------------------------------------------------------------------------
-- h in range [0-360] in integer
-- s and l in range [0,1] in float
function color_widget:hsl_to_rgb(h, s, l)
  h = h % 360

  local C = (1 - math.abs(2 * l - 1)) * s
  local X = C * (1 - math.abs((h / 60) % 2 - 1))
  local m = l - 0.5 * C
  local index = math.floor(h / 60)
  
  local r, g, b
  if     index == 0 then r, g, b = C, X, 0
  elseif index == 1 then r, g, b = X, C, 0
  elseif index == 2 then r, g, b = 0, C, X
  elseif index == 3 then r, g, b = 0, X, C
  elseif index == 4 then r, g, b = X, 0, C
  elseif index == 5 then r, g, b = C, 0, X end
  r, g, b = r + m, g + m, b + m
  r, g, b = 255 * r, 255 * g, 255 * b
  
  return r, g, b
end

------------------------------------------------------------------------------
-- r, g, b in range [0-255] in integer
function color_widget:rgb_to_hsl(r, g, b)
  r, g, b = r/255, g/255, b/255
  
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local avg = 0.5 * (max + min)
  local h, s, l = avg, avg, avg
  
  if max == min then
    h, s = 0, 0
  else
    local d = max - min
    if l > 0.5 then
      s = d / (2 - max - min)
    else
      s = d / (max + min)
    end
    
    if     max == r then
      local val = 0
      if g < b then val = 6 end
      h = (g - b) / d + val
    elseif max == g then
      h = (b - r) / d + 2
    elseif max == b then
      h = (r - g) / d + 4
    end
    
    h = h * 60
  end
  
  return h, s, l
end

------------------------------------------------------------------------------
function color_widget:update(dt)

  self.slider_r:update(dt)
  self.slider_g:update(dt)
  self.slider_b:update(dt)
  
  self.slider_h:update(dt)
  self.slider_s:update(dt)
  self.slider_l:update(dt)
  
  -- get color
  local r = self.slider_r:get_value()
  local g = self.slider_g:get_value()
  local b = self.slider_b:get_value()
  self.color[1], self.color[2], self.color[3], self.color[4] = r, g, b, 255
end

------------------------------------------------------------------------------
function color_widget:draw()
  lg.setColor(0, 0, 255, 200)
  self.bbox:draw()
  
  self.slider_r:draw()
  self.slider_g:draw()
  self.slider_b:draw()
  
  self.slider_h:draw()
  self.slider_s:draw()
  self.slider_l:draw()
  
  -- draw color square
  local color = self.color
  
  local bdr = 10
  local swidth = self.width - 2 * bdr
  local sx = self.x + bdr
  local sy = self.y + bdr
  
  lg.setColor(color)
  lg.rectangle('fill', sx, sy, swidth, swidth)
  
  lg.setColor(0, 0, 0, 255)
  lg.rectangle('line', sx, sy, swidth, swidth)
  
end

return color_widget




























