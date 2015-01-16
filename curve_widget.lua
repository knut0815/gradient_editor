
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- curve_widget object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local curve_widget = {}
curve_widget.table = 'curve_widget'
curve_widget.x = 0
curve_widget.y = 0
curve_widget.width = 250
curve_widget.height = 250
curve_widget.rows = 40
curve_widget.cols = 40
curve_widget.tile_width = 0
curve_widget.tile_height = 0
curve_widget.bbox = nil
curve_widget.grid = nil
curve_widget.callback_func = nil

curve_widget.history = nil
curve_widget.mouse_i = nil
curve_widget.mouse_j = nil
curve_widget.selected = nil   -- table of selected tiles hashed by tile table

curve_widget.spline = nil
curve_widget.curve_points = nil              -- for drawing curve
curve_widget.curve_out_of_range = false
curve_widget.eps = 0.0001                    -- epsilon

local curve_widget_mt = { __index = curve_widget }
function curve_widget:new(x, y, callback)
  local bbox = bbox:new(x, y, curve_widget.width, curve_widget.height)
  
  -- construct grid of tiles
  local grid = {}
  local rows, cols = curve_widget.rows, curve_widget.cols
  local width = curve_widget.width / curve_widget.cols
  local height = curve_widget.height / curve_widget.rows
  for j=1,rows do
  
    local row = {}
    local yval = y + (j - 1) * height
    
    for i=1,cols do
      local tile = {}
      tile.x = x + (i - 1) * width
      tile.y = yval
      tile.cart_x = (i - 1) / (cols - 1)       -- (x, y) that tile represents
			tile.cart_y = (rows - j) / (rows - 1)
			tile.act_cart_x = nil                    -- for more refined x or y
      tile.act_cart_y = nil
      tile.highlight = false
      
      row[#row + 1] = tile
    end
    
    grid[#grid + 1] = row
  end
  
  local history = {}
  local selected_tiles = {}
  
  return setmetatable({ x = x,
                        y = y,
                        bbox = bbox,
                        grid = grid,
                        tile_height = height,
                        tile_width = width,
                        history = history,
                        selected = selected_tiles,
                        callback_func = callback}, curve_widget_mt)
end

function curve_widget:mousepressed(x, y, button)
  
  if button == 'l' and self.bbox:contains_point(vector2:new(x, y)) then
    self:click(self.mouse_i, self.mouse_j)
    self.curve_points = self:get_curve_draw_points()
    self:curve_update_callback()
  end
  
end

function curve_widget:keypressed(key)
  local mpos = vector2:new(love.mouse:getPosition())

  if key == 'z' and love.keyboard.isDown('lctrl') and 
     self.bbox:contains_point(mpos) then
    
    local history = self.history
		if #history > 0 then
			local action = history[#history]
			history[#history] = nil
			self:undo(action[1], action[2], action[3])
			self.curve_points = self:get_curve_draw_points()
			self:curve_update_callback()
		end
	end


end


-- x, y between 0 and 1
function curve_widget:set_point(x, y)
  local i = math.floor(x * self.rows)
  local j = math.floor((1 - y) * self.rows)
  local i = math.max(1, i)
  local j = math.max(1, j)
  
  --[[
  if self.grid[j][i].highlight then
    return
  end
  ]]--
  --self:click(i , j, x, y)
  
  local grid = self.grid
  for row=1,#grid do
    local t = grid[row][i]
    t.highlight = false
    t.act_cart_x = nil
    t.act_cart_y = nil
    self.selected[t] = nil
  end
  
  local tile = grid[j][i]
  tile.highlight = true
  tile.act_cart_x = x
  tile.act_cart_y = y
  
  self.selected[tile] = tile
  self.history[#self.history + 1] = {i, j, 0}
  
  self.curve_points = self:get_curve_draw_points()
  self:curve_update_callback()
end

function curve_widget:click(i, j, x, y)
  local grid = self.grid
  local tile = grid[j][i]
  local highlight = tile.highlight
  local history = self.history
  local selected = self.selected
  
  -- case 1: not highlighted, highlight tile, remove all highlights from column
	if not highlight then
		for row=1,#grid do
		  local t = grid[row][i]
			t.highlight = false
			t.act_cart_x = nil
			t.act_cart_y = nil
			selected[t] = nil
		end
		
		tile.highlight = true
		tile.act_cart_x = x
		tile.act_cart_y = y
		
		selected[tile] = tile
		history[#history + 1] = {i, j, 0}
	else
		-- case 2: highlighted, so unhighlight
		tile.highlight = false
		tile.act_cart_x = nil
		tile.act_cart_y = nil
		selected[tile] = nil
		history[#history + 1] = {i, j, 1}
	end
  
end

function curve_widget:undo(i, j, action)

  local grid = self.grid
	if action == 0 then
		grid[j][i].highlight = false
		self.selected[grid[j][i]] = nil
	end
	
	if action == 1 then
		for row=1,#grid do
			grid[row][i].highlight = false
		end
		grid[j][i].highlight = true
	end
end

function curve_widget:set_grid(grid)
  self.grid = grid
  
  -- unhighlight current tiles, highlight loaded tiles 
  for _,v in pairs(self.selected) do
    v.highlight = false
  end
  
  local selected = grid.selected
  self.selected = selected
  for _,v in pairs(selected) do
    v.highlight = true
  end
  
  self.curve_points = self:get_curve_draw_points()
  self:curve_update_callback()
end

function curve_widget:get_grid_copy()
  local grid = self.grid
  local rows, cols = self.rows, self.cols
  local grid_copy = {}
  for j=1,rows do
    local row = {}
    
    for i=1,cols do
      local t = grid[j][i]
      
      -- copy t into tile
      local tile = {}
      tile.x = t.x
      tile.y = t.y
      tile.cart_x = t.cart_x
      tile.cart_y = t.cart_y
      tile.act_cart_x = t.act_cart_x
      tile.act_cart_y = t.act_cart_y
      tile.highlight = t.highlight
      
      row[i] = tile
    end
    
    grid_copy[j] = row
  end
  
  --copy selected
  local s = self.selected
  local selected = {}
  for _,v in pairs(s) do
    selected[v] = v
  end
  grid_copy.selected = selected
  
  return grid_copy
end

function curve_widget:get_spline()
  return self.spline
end

function curve_widget:generate_points()
  local grid = self.grid
  
  points = {}
	
	-- first point
	local first_y = nil
	local first_x = nil
	for j=1,#grid do
		local tile = grid[j][1]
		if tile.highlight then
		  if tile.act_cart_x then
        first_y = tile.act_cart_y
        first_x = tile.act_cart_x
			else
			  first_y = tile.cart_y
			  first_x = tile.cart_x
			end
		end
	end
	if not first_y then
		first_x, first_y = 0, 0
	end
	points[1] = vector2:new(first_x, first_y)
	
	-- mid points
	for i=2,#grid[1]-1 do
		local x, y = nil
		for j=1,#grid do
			local tile = grid[j][i]
			if tile.highlight then
				if tile.act_cart_x then
          x = tile.act_cart_x
          y = tile.act_cart_y
        else
          x = tile.cart_x
          y = tile.cart_y
        end
				break
			end
		end
		
		if x then
			points[#points+1] = vector2:new(x, y)
		end
	end
	
	-- last point
	local last_y = nil
	local last_x = nil
	for j=1,#grid do
		local tile = grid[j][#grid[1]]
		if tile.highlight then
			if tile.act_cart_x then
          last_x = tile.act_cart_x
          last_y = tile.act_cart_y
        else
          last_x = tile.cart_x
          last_y = tile.cart_y
        end
		end
	end
	if not last_y then
		last_x, last_y = 1, 0
	end
	points[#points+1] = vector2:new(last_x, last_y)
	
	return points
end

function curve_widget:get_curve_draw_points()
  local grid = self.grid
	local points = self:generate_points()
	local sp = cubic_spline:new(points)
	
	local sp_points = {}
	local width = self.width
	local eps = self.eps
	local max = 0
	local min = 0
	for i=0,width do
		local x = i / width
		local y = sp:get_val(x)
		if math.abs(y) < eps then y = 0 end
		if math.abs(x - 1) < eps then x = 1 end
		
		sp_points[i + 1] = vector2:new(x, y)
		
		if y > max then max = y end
		if y < min then min = y end 
	end
	
	self.curve_out_of_range = max > 1 or min < 0
	
	self.spline = sp
	return sp_points
end

function curve_widget:curve_update_callback()
  if self.callback_func then
    if self.parent then
      self.callback_func(self.parent)
    else
      self.callback_func()
    end
  end
end

------------------------------------------------------------------------------
function curve_widget:update(dt)
  local mpos = vector2:new(love.mouse.getPosition())
  local mouse_i, mouse_j
  if self.bbox:contains_point(mpos) then
    mouse_i = math.floor((mpos.x - self.x) / self.tile_width) + 1
    mouse_j = math.floor((mpos.y - self.y) / self.tile_height) + 1
	end
	
	self.mouse_i = mouse_i
	self.mouse_j = mouse_j
	
end

------------------------------------------------------------------------------
function curve_widget:draw()
  
  if self.curve_out_of_range then
    lg.setColor(255, 0, 0, 200)
  else
    lg.setColor(0, 0, 255, 200)
  end
  lg.setLineWidth(2)
  self.bbox:draw()
  
  
  -- vertical lines
  local grid = self.grid
  lg.setColor(0,0,255,50)
	lg.setLineWidth(1)
	for i=1,#grid[1] do
		local x = grid[1][i].x
		lg.line(x, self.y, x, self.y + self.height)
	end
	
	-- horizontal lines
	for i=1,#grid do
		local y = grid[i][1].y
		lg.line(self.x, y, self.x + self.width, y)
	end
	
	-- draw tile hover
	if self.mouse_i then
	  local tile = grid[self.mouse_j][self.mouse_i]
	  lg.setColor(255, 0, 0, 100)
	  lg.rectangle("fill", tile.x, tile.y, self.tile_width, self.tile_height)
	end
	
	-- draw selected tiles
	lg.setColor(0, 0, 255, 255)
	local width, height = self.tile_width, self.tile_height
	for _,t in pairs(self.selected) do
	  local x, y = t.x, t.y
	  if t.act_cart_x then
	    local t_width = self.width / self.cols
	    x = t.act_cart_x * self.width + self.x
	    y = (1 - t.act_cart_y) * self.height + self.y - 0.5 * t_width
	  end
	  
	  lg.rectangle("fill", x, y, width, height)
	end
	
	-- draw curve
	lg.setColor(255, 0, 0, 255)
	lg.setPointSize(2)
	
	local sp_points = self.curve_points
	local x, y = self.x, self.y
	local width, height = self.width, self.height
	if sp_points and #sp_points >= 2 then
		for i=1,#sp_points-1 do
			local p1 = sp_points[i]
			local p2 = sp_points[i+1]
			
			local x1, y1 = x + p1.x * width, y + height - p1.y * height
			local x2, y2 = x + p2.x * width, y + height - p2.y * height
			lg.line(x1, y1, x2, y2)
		end
	end
  
end

return curve_widget


















