
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- gradient_editor object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local gradient_editor = {}
local ge = gradient_editor
ge.master_timer = nil
ge.h_curve = nil
ge.s_curve = nil
ge.l_curve = nil
ge.color_picker = nil
ge.num_colors = nil
ge.gradient = nil

ge.graph_x = nil                  -- x,y values of curve widget coordinates
ge.graph_y = nil
ge.hover_widget = nil             -- curve widget that mouse is on

-- buttons
ge.none_button = nil
ge.initial_button = nil
ge.final_button = nil
ge.selected_button = nil
ge.save_button = nil

ge.save_alpha = 0
ge.save_timer = 0
ge.save_time = 0.5

local gradient_editor_mt = { __index = gradient_editor }
function gradient_editor:new(x, y, num_colors)
  
  local color_picker = color_widget:new(x + 270, y, gradient_editor.slider_changed)

  object =  setmetatable({color_picker = color_picker}, gradient_editor_mt)
              
  object.num_colors = num_colors
              
  local ystep = 275
  local h_curve = curve_widget:new(x, y, object.curve_changed)
  local s_curve = curve_widget:new(x, y + ystep, object.curve_changed)
  local l_curve = curve_widget:new(x, y + ystep * 2, object.curve_changed)
  
  object.h_curve = h_curve
  object.s_curve = s_curve
  object.l_curve = l_curve
  
  h_curve.parent = object
  s_curve.parent = object
  l_curve.parent = object
  
  h_curve:set_point(0, 0)
  h_curve:set_point(1, 0)
  s_curve:set_point(0, 0.5)
  s_curve:set_point(1, 0.5)
  l_curve:set_point(0, 0)
  l_curve:set_point(1, 1)
  
  color_picker.parent = object
  
  -- buttons
  local bw, bh = 20, 20 
  local x, y = color_picker.x + 10, color_picker.y + 700
  local ystep = 35
  object.none_button = bbox:new(x, y, bw, bh)
  object.initial_button = bbox:new(x, y + ystep, bw, bh)
  object.final_button = bbox:new(x, y + ystep * 2, bw, bh)
  object.save_button = bbox:new(20, 835, 570, 25)
  object.selected_button = object.none_button
  
  return object
end

function gradient_editor:curve_changed()
  self:generate_gradient()
  self:update_preview_gradient()
end

function gradient_editor:slider_changed(name, value)
  if self.selected_button == self.none_button then
    return
  end
  
  local hval = self.color_picker.slider_h.value
  local sval = self.color_picker.slider_s.value
  local lval = self.color_picker.slider_l.value
  
  local x = nil
  if self.selected_button == self.initial_button then
    x = 0
  else
    x = 1
  end
  self.h_curve:set_point(x, hval)
  self.s_curve:set_point(x, sval)
  self.l_curve:set_point(x, lval)
end

function gradient_editor:mousepressed(x, y, button)
  self.h_curve:mousepressed(x, y, button)
  self.s_curve:mousepressed(x, y, button)
  self.l_curve:mousepressed(x, y, button)
  
  -- check if button clicked
  local mpos = vector2:new(x, y)
  local selected = self.selected_button
  if     self.none_button:contains_point(mpos) then
    if selected == self.none_button then
      self.selected_button = self.none_button
    else
      self.selected_button = self.none_button
    end
  elseif self.initial_button:contains_point(mpos) then
    if selected == self.initial_button then
      self.selected_button = self.none_button
    else
      self.selected_button = self.initial_button
    end
  elseif self.final_button:contains_point(mpos) then
    if selected == self.final_button then
      self.selected_button = self.none_button
    else
      self.selected_button = self.final_button
    end
  end
  
  if self.save_button:contains_point(mpos) then
    self:print_gradient()
    self.save_timer = self.save_time
  end
end

function gradient_editor:keypressed(key)
  self.h_curve:keypressed(key)
  self.s_curve:keypressed(key)
  self.l_curve:keypressed(key)
  
  if key == 't' then
	  self:print_gradient()
	end
end

function gradient_editor:set_current_layer(idx)
  -- save hsl curves
  local curve_copies = self.layer_curve_copies
  curve_copies[self.current_layer_idx] = {}
  local copy = curve_copies[self.current_layer_idx]
  copy.h = self.h_curve:get_grid_copy()
  copy.s = self.s_curve:get_grid_copy()
  copy.l = self.l_curve:get_grid_copy()
end

function gradient_editor:get_gradient()
  return self.gradient
end

function gradient_editor:print_gradient()
  function round(num)
    return math.floor(num + 0.5)
  end

  local g = self:get_gradient()
  local str = "{\n"
  local len = #g
  for i=1,#g do
    local s = g[i]
    str = str.."{"..round(s[1])..","..round(s[2])..","..
                    round(s[3])..","..round(s[4]).."}" 
    if i == len then
      str = str.."\n}"
    else
      str = str..",\n"
    end
  end
  
  love.system.setClipboardText(str)
end

function gradient_editor:generate_gradient()
  local num = self.num_colors
  local h_curve = self.h_curve:get_spline()
  local s_curve = self.s_curve:get_spline()
  local l_curve = self.l_curve:get_spline()
  
  if not (h_curve and s_curve and l_curve) then
    return
  end
  
  local x = 0
  local xstep = 1 / num
  local gradient = {}
  for i=1,num do
    local r, g, b = self:hsl_to_rgb(h_curve:get_val(x) * 360, 
                                    s_curve:get_val(x), 
                                    l_curve:get_val(x))
    gradient[i] = {r, g, b, 255}
    x = x + xstep
  end
  
  self.gradient = gradient
end

------------------------------------------------------------------------------
-- h in range [0-360] in integer
-- s and l in range [0,1] in float
function gradient_editor:hsl_to_rgb(h, s, l)
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
function gradient_editor:update(dt)
  self.h_curve:update(dt)
  self.s_curve:update(dt)
  self.l_curve:update(dt)
  self.color_picker:update(dt)

  -- display coordinates if mouse is in curve widget
  local mpos = vector2:new(love.mouse.getPosition())
  local width = self.h_curve.width
  local x, y
  if     self.h_curve.bbox:contains_point(mpos) then
    x = (mpos.x - self.h_curve.x) / width
    y = 1 - (mpos.y - self.h_curve.y) / width
    self.hover_widget = self.h_curve
  elseif self.s_curve.bbox:contains_point(mpos) then
    x = (mpos.x - self.s_curve.x) / width
    y = 1 - (mpos.y - self.s_curve.y) / width
    self.hover_widget = self.s_curve
  elseif self.l_curve.bbox:contains_point(mpos) then
    x = (mpos.x - self.l_curve.x) / width
    y = 1 - (mpos.y - self.l_curve.y) / width
    self.hover_widget = self.l_curve
  end
  self.graph_x = x
  self.graph_y = y
  
  if self.save_timer > 0 then
    self.save_timer = self.save_timer - dt
    if self.save_timer < 0 then 
      self.save_timer = 0
    end
  end
  local min_alpha, max_alpha = 0, 100
  local x = self.save_timer/self.save_time
  local t = x*x*(3 - 2*x)
  self.save_alpha = min_alpha + t*(max_alpha - min_alpha)
end



function gradient_editor:update_preview_gradient()
  if self.gradient and self.tile_layer then
    self.preview_color_changed = true
  end
end

------------------------------------------------------------------------------
function gradient_editor:draw()
  local hx, hy = self.h_curve.x, self.h_curve.y
  local sx, sy = self.s_curve.x, self.s_curve.y
  local lx, ly = self.l_curve.x, self.l_curve.y
  local width = self.h_curve.width
  local fwidth = lg.getFont():getWidth('H')
  
  lg.setColor(0, 0, 255, 40)
  --lg.setFont(big_font)
  
  lg.print('H', hx + 0.5 * width - 0.5*fwidth, hy + 0.5 * width - 0.5 * fwidth)
  lg.print('S', sx + 0.5 * width - 0.5*fwidth, sy + 0.5 * width - 0.5 * fwidth)
  lg.print('L', lx + 0.5 * width - 0.5*fwidth, ly + 0.5 * width - 0.5 * fwidth)
  
  --lg.setFont(default_font)

  self.h_curve:draw()
  self.s_curve:draw()
  self.l_curve:draw()
  self.color_picker:draw()
  
  -- draw graph coordinates
  if self.graph_x then
    local gx, gy = self.graph_x, self.graph_y
    local x, y = self.hover_widget.x, self.hover_widget.y - 20
    local pad = 100
    lg.setColor(0, 0, 0, 255)
    lg.print("x: "..gx, x, y)
    lg.print("y: "..gy, x + pad, y)
  end
  
  -- draw buttons
  lg.setColor(0, 0, 255, 200)
  self.none_button:draw()
  self.initial_button:draw()
  self.final_button:draw()
  self.save_button:draw()
  
  lg.setColor(0, 0, 255, self.save_alpha)
  self.save_button:draw("fill")
  
  local mx, my = love.mouse.getPosition()
  if self.save_button:contains_point(vector2:new(mx, my)) then
    lg.setColor(0, 0, 255, 20)
    self.save_button:draw("fill")
  end
  
  lg.setColor(0, 0, 255, 200)
  -- button labels
  lg.print("Set none", self.none_button.x + 30, self.none_button.y + 3)
  lg.print("Set initial color", self.initial_button.x + 30, self.initial_button.y + 3)
  lg.print("Set final color", self.final_button.x + 30, self.final_button.y + 3)
  lg.print("Save to Clipboard", self.save_button.x + 230, self.save_button.y + 6)
  
  -- draw selected button
  local x, y
  local w, h = self.none_button.width, self.none_button.height
  local pad = 3
  local selected = self.selected_button
  if     selected == self.none_button then
    x, y = self.none_button.x, self.none_button.y
  elseif selected == self.initial_button then
    x, y = self.initial_button.x, self.initial_button.y
  elseif selected == self.final_button then
    x, y = self.final_button.x, self.final_button.y
  end
  lg.rectangle('fill', x + pad, y + pad, w - 2 * pad, h - 2 * pad)
  
  -- draw gradient
  if self.gradient then
    local gradient = self.gradient
    local x, y = 20, 20
    local width = 80
    local height = 800
    local num = #gradient
    local ystep = height / num
    for i=1,#gradient do
      lg.setColor(gradient[i])
      lg.rectangle('fill', x, y, width, ystep)
      y = y + ystep
    end
  end 
  
end

return gradient_editor


























