
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- camera2d object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local camera2d = {}
camera2d.table = CAMERA2D
camera2d.debug = false
camera2d.pos = nil
camera2d.target = nil
camera2d.center = nil
camera2d.x_scale = 1
camera2d.y_scale = 1
camera2d.view_w = SCR_WIDTH
camera2d.view_h = SCR_HEIGHT

camera2d.min_scale = 1
camera2d.max_scale = 0.85
camera2d.act_scale = 1
camera2d.scale = 1
camera2d.scale_up_vel = 6
camera2d.scale_down_vel = 3

camera2d.mass = 1

local camera2d_mt = { __index = camera2d }
function camera2d:new()
  local pos = vector2:new(0, 0)
  local center = vector2:new(SCR_WIDTH/2, SCR_HEIGHT/2)
  
  -- for smooth movement
  local target = physics.steer:new(pos)
  target:set_dscale(1)
  target:set_target(pos)
  target:set_mass(camera2d.mass)  
  target:set_max_speed(500)
  target:set_force(1500)
  target:set_radius(300)
  
  -- for smooth scaling
  local scale_target = physics.steer:new()
  scale_target:set_target(vector2:new(camera2d.min_scale, 0))
  scale_target:set_position(vector2:new(camera2d.min_scale, 0))
  scale_target:set_mass(1)
  scale_target:set_max_speed(camera2d.scale_up_vel)
  
  local view_width, view_height = SCR_WIDTH, SCR_HEIGHT

  return setmetatable({ pos = pos,
                        center = center,
                        target = target,
                        scale_target = scale_target,
                        view_w = view_width,
                        view_h = view_height }, camera2d_mt)
end

------------------------------------------------------------------------------
function camera2d:set()
  lg.push()
  lg.scale(self.x_scale, self.y_scale)
  lg.translate(-self.pos.x, -self.pos.y)
end

-----------------------------------------------------------------------------
function camera2d:unset()
  love.graphics.pop()
end

-----------------------------------------------------------------------------
-- sets center of the screen at position pos
-- NOTE: if scaling, set_scale must be set before set_position
function camera2d:set_position(pos)
  self.pos = pos - self.center
end

function camera2d:set_target(pos, immediate)
  if immediate then
    self.target:set_position(pos)
    self:set_position(pos)
  end
  self.target:set_target(pos)
end

------------------------------------------------------------------------------
function camera2d:set_scale(sx, sy)
  self.x_scale = sx or 1
  self.y_scale = sy or self.x_scale
  self.view_w = SCR_WIDTH / self.x_scale
  self.view_h = SCR_HEIGHT / self.y_scale
  self.center:set(0.5*self.view_w, 0.5*self.view_h)
end

function camera2d:get_pos()
  return self.pos
end

function camera2d:get_center()
  return self.pos + self.center
end

function camera2d:get_size()
  return self.view_w, self.view_h
end

function camera2d:get_viewport()
  return self.pos.x, self.pos.y, self.view_w, self.view_h
end

------------------------------------------------------------------------------
function camera2d:update(dt)
  -- calculate what the camera should be scaled to
  local vel = self.target.point:get_velocity():mag()
  local max_vel = self.target.max_vel
  local r = vel / max_vel
  local act_scale = self.min_scale + r * (self.max_scale - self.min_scale)
  
  -- find the smooth scale value
  self.scale_target:set_target((vector2:new(act_scale,0)))
  self.scale_target:update(dt)
  if self.scale_target.point:get_velocity().x > 0 then
    self.scale_target:set_max_speed(self.scale_down_vel)
  else
    self.scale_target:set_max_speed(self.scale_up_vel)
  end
  self.scale = self.scale_target:get_position().x
  
  -- commit the scale
  self:set_scale(self.scale)
  
  -- set position
  self.target:update(dt)
  self:set_position(self.target:get_position())

end

------------------------------------------------------------------------------
function camera2d:draw()
  if self.debug then
    self.target:draw()
  end
end

return camera2d







