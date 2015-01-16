
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- curve_builder object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local cb = {}
cb.table = 'cb'
cb.bbox = nil
cb.active_region = nil
cb.x = nil
cb.y = nil
cb.width = nil
cb.height = nil
cb.y_axis = nil
cb.points = nil
cb.point_radius = 8

cb.grabbed_point = nil
cb.head = nil
cb.tail = nil
cb.head_snap_bbox = nil
cb.tail_snap_bbox = nil
cb.snap_width = 10

cb.out_of_range = false
cb.contains_positive = false
cb.contains_negative = false

cb.num_y_guides = 4
cb.num_x_guides = 8

local cb_mt = { __index = cb }
function cb:new(x, y, width, height, filename)
  local cb = setmetatable({}, cb_mt)
  
  cb.bbox = bbox:new(x, y, width, height)
  cb.x, cb.y, cb.width, cb.height = x, y, width, height
  cb.y_axis = y + 0.5 * height
  cb.filename = filename
  
  cb.points = {}
  cb._add_point(cb, x, cb.y_axis)
  cb._add_point(cb, x + width, cb.y_axis)
  cb.head = cb.points[1]
  cb.tail = cb.points[2]
  
  local rpad = 30
  cb.active_region = bbox:new(x - rpad, y - rpad, width + 2*rpad, height+2*rpad)
  
  cb.draw_points = {}
  cb._refresh_spline(cb)
  
  local w = cb.snap_width
  local x, y = cb.points[1].x - 0.5 * w, cb.points[1].y - 0.5*w
  cb.head_snap_bbox = bbox:new(x, y, w, w)
  local x, y = cb.points[2].x - 0.5 * w, cb.points[2].y - 0.5*w
  cb.tail_snap_bbox = bbox:new(x, y, w, w)
  
  return cb
end

function cb:keypressed(key)
end

function cb:mousepressed(x, y, button)
  if not self.active_region:contains_coordinate(x, y) then
    return
  end
  
  if button == 'l' then
    local grabbed_point = self:_get_point_at_position(x, y)
    if grabbed_point then
      self.grabbed_point = grabbed_point
      return
    end
    self:_add_point(x, y)
  end
  
  if button == 'r' then
    local point = self:_get_point_at_position(x, y)
    if point then
      self:_remove_point(point)
    end
  end
end

function cb:mousereleased(x, y, button)
  self.grabbed_point = nil
end

function cb:_refresh_spline()
  if #self.points < 2 then
    return
  end
  self.spline = cubic_spline:new(self.points)
  self.draw_points = self.spline:get_points()
  
  local contains_positive = false
  local contains_negative = false
  local out_of_range = false
  local b = self.bbox
  for i=1,#self.draw_points-2,2 do
    local x, y = self.draw_points[i], self.draw_points[i+1]
    if y <= self.y_axis then
      contains_positive = true
    end
    if y > self.y_axis then
      contains_negative = true
    end
    if x < b.x or x > b.x + b.width or y < b.y or y > b.y + b.height then
      out_of_range = true
    end
  end
  
  for i=1,#self.points-1 do
    if self.points[i].x == self.points[i+1].x then
      out_of_range = true
    end
  end
  
  self.out_of_range = out_of_range
  self.contains_positive = contains_positive
  self.contains_negative = contains_negative
end

function cb:_point_to_table_string(p)
  return "{x="..p.x..",y="..p.y.."}"
end

function cb:write_to_file()
  local points = self:_get_normalized_points()
  local str = "return {"
  
  for i=1,#points do
    str = str..self:_point_to_table_string(points[i])
    if i < #points then
      str = str..","
    end
  end
  
  str = str.."}"
  love.filesystem.setIdentity(IDENTITY)
  local file = love.filesystem.newFile(self.filename)
  file:open("w")
  file:write(str)
  file:close()

  print("Wrote to file: "..self.filename)
  print(str)
  print()
end

function cb:_get_normalized_points()
  local npoints = {}
  local points = self.points
  local width = self.width
  local height = 0.5 * self.height
  local y_axis = self.y_axis
  
  for i=1,#points do
    local x, y = points[i].x, points[i].y
    local x = (x - self.x) / width
    local y = -(y - y_axis) / height
    
    if y == 0 then y = 0 end  -- stop y from being -0
    
    local np = {x=x, y=y}
    npoints[i] = np
  end
  
  return npoints
end

function cb:_add_point(x, y)
  local b = self.bbox
  if x < b.x or x > b.x + b.width or y < b.y or y > b.y + b.height then
    return
  end
  
  local gpoint = {x = x, y = y}
  self.points[#self.points + 1] = gpoint
  table.sort(self.points, function(a,b) return a.x<b.x end)
  
  if love.mouse.isDown('l') then
    self.grabbed_point = gpoint
  end
  
  self:_refresh_spline()
end

function cb:_remove_point(point)
  if point == self.head or point == self.tail then
    return
  end

  local points = self.points
  for i=1,#points do
    if points[i] == point then
      table.remove(points, i)
      self:_refresh_spline()
      return
    end
  end
end

function cb:_get_point_at_position(x, y)
  local r = self.point_radius
  local points = self.points
  for i=1,#points do
    local dx, dy = points[i].x - x, points[i].y - y
    local dsq = dx*dx + dy*dy
    if dsq < r*r then
      return points[i]
    end
  end
  
  return false
end

function cb:_update_grabbed_point()
  local gpoint = self.grabbed_point
    local x, y = love.mouse.getPosition()
    
    if not self.active_region:contains_coordinate(x, y) then
      return 
    end
    
    if x < self.bbox.x then
      x = self.bbox.x
    end
    if x > self.bbox.x + self.bbox.width then
      x = self.bbox.x + self.bbox.width
    end
    if y < self.bbox.y then
      y = self.bbox.y
    end
    if y > self.bbox.y + self.bbox.height then
      y = self.bbox.y + self.bbox.height
    end
    
    if gpoint == self.head or gpoint == self.tail then
      gpoint.y = y
      
      if self.head_snap_bbox:contains_coordinate(x, y) then
        gpoint.x = self.x
        gpoint.y = self.y_axis
      end
      if self.tail_snap_bbox:contains_coordinate(x, y) then
        gpoint.x = self.x + self.width
        gpoint.y = self.y_axis
      end
    else
      gpoint.x, gpoint.y = x, y
    end
    
    table.sort(self.points, function(a,b) return a.x<b.x end)
    self:_refresh_spline()
end

------------------------------------------------------------------------------
function cb:update(dt)
  if self.grabbed_point then
    self:_update_grabbed_point()
  end
end

------------------------------------------------------------------------------
function cb:draw()
  lg.setColor(0, 0, 255, 255)
  lg.setLineWidth(1)
  self.bbox:draw()
  
  local points = self.draw_points
  local dx = self.width / #points
  for i=1,#points-2,2 do
    lg.line(points[i], points[i + 1], points[i + 2], points[i + 3])
  end
  
  lg.print(self.filename, self.x + 4, self.y + 4)
  
  lg.setPointSize(3)
  lg.setColor(0, 0, 255, 255)
  lg.line(self.x, self.y_axis, self.x + self.width, self.y_axis)
  
  local y_guides = self.num_y_guides
  local y_axis = self.y_axis
  local h = 0.5 * self.height / y_guides
  lg.setColor(0, 0, 255, 50)
  for i=1,y_guides - 1 do
    lg.line(self.x, y_axis + i * h, self.x + self.width, y_axis + i * h)
    lg.line(self.x, y_axis - i * h, self.x + self.width, y_axis - i * h)
  end
  
  local x_guides = self.num_x_guides
  local w = self.width / x_guides
  lg.setColor(0, 0, 255, 50)
  for i=1,x_guides - 1 do
    lg.line(self.x + i * w, self.y,self.x + i * w, self.y + self.height)
  end
  
  for i=1,#self.points do
    local x, y = self.points[i].x, self.points[i].y
    lg.setColor(255, 0, 0, 255)
    if self.grabbed_point == self.points[i] then
      lg.setColor(0, 200, 0, 255)
    end
    lg.setPointSize(2)
    lg.setPointStyle('rough')
    lg.point(x, y)
    lg.circle("line", x, y, self.point_radius)
  end
  
  if self.contains_positive then
    lg.setLineWidth(4)
    lg.setColor(0, 0, 255, 100)
    --lg.line(self.x, self.y - 5, self.x + self.width, self.y - 5)
  end
  if self.contains_negative then
    lg.setLineWidth(4)
    lg.setColor(0, 0, 255, 100)
    lg.line(self.x, self.y + 5 + self.height, self.x + self.width, self.y + 5 + self.height)
  end
  
  if self.out_of_range then
    lg.setLineWidth(5)
    lg.setColor(255, 0, 0, 255)
    self.bbox:draw()
  end
  
end

return cb





















