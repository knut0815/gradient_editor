-- enums
DSCALE = 32   -- in pixels per metre
EPSILON = 0.0000001
VECT_ZERO = vector2:new(0, 0)


--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- point object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local point = {}
point.table = PHYS_POINT
point.dscale = DSCALE
point.pos = nil
point.vel = nil
point.mass = 1
point.force = nil
point.forces = nil       -- format: {vect1, timer1, vect2, timer2, ...}
point.has_force = false

local point_mt = { __index = point }
function point:new(pos)
  local pos = pos or vector2:new(0, 0)
  local vel = vector2:new(0, 0)
  local force = vector2:new(0, 0)
  local forces = {}
  
  return setmetatable({ pos = pos,
                        vel = vel,
                        force = force,
                        forces = forces}, point_mt)
end

function point:set_position(pos) 
  self.pos = pos 
end
function point:set_velocity(vel) self.vel = vel end
function point:set_mass(mass) self.mass = mass end
function point:set_dscale(s) self.dscale = s end

function point:get_position()
  return self.pos 
end
function point:get_velocity() return self.vel end

-----------------------------------------------------------------------------
-- applies force vect for time t (miliseconds)
-- force is only applied once if t not specifided
function point:add_force(vect, t)
  if t then
    local len = #self.forces
    local p = timer:new(t)
    self.forces[len+1] = vect
    self.forces[len+2] = p
    p:start()
  else
    self.force = self.force + vect
  end
  
  self.has_force = true
end


-----------------------------------------------------------------------------
-- adds timed forces to self.force
function point:_apply_forces()
  local forces = self.forces
  for i=#forces, 1, -2 do
    local force = forces[i-1]
    local timer = forces[i]
    self.force = self.force + force
    
    -- remove entry if finished
    if timer:isfinished() then
      table.remove(forces, i)
      table.remove(forces, i-1)
    end
  end
end

------------------------------------------------------------------------------
function point:update(dt)
  if #self.forces > 0 then
    self:_apply_forces()
  end
  
  -- newton
  local acc = VECT_ZERO
  if self.has_force then
    acc = self.force / self.mass
  end
  
  
  local vel = self.vel + acc * dt
  if vel:mag() < EPSILON then
    vel:set(0, 0)
  end
  
  local pos = self.pos + vel * self.dscale * dt    -- (m/s)*(px/m) = (px/s)
  
  
  self.pos = pos
  self.vel = vel
  
  -- clear force
  self.force:set(0, 0)
  self.has_force = false
end

------------------------------------------------------------------------------
function point:draw()
  lg.setColor(255,0,0,255)
  lg.setPoint(4, "smooth")
  lg.point(self.pos:get_vals())
end



--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- steer object - a point that steers toward it's target
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local steer = {}
steer.table = PHYS_STEER
steer.dscale = DSCALE
steer.point = nil
steer.target = nil
steer.max_force = 10
steer.max_vel = 30         -- meters/s
steer.slow_radius = 400     -- in pixels
steer.approach_factor = 1


local steer_mt = { __index = steer }
function steer:new(pos)
  pos = pos or VECT_ZERO
  point = point:new(pos)
  target = pos
  
  return setmetatable({ point = point,
                        target = target}, steer_mt)
end

function steer:set_target(target)
  self.target = target
end

function steer:set_position(pos)
  self.point:set_position(pos)
end

function steer:set_force(f)  -- scalar
  self.max_force = f
end

function steer:set_max_speed(s)
  self.max_vel = s
end

function steer:set_radius(r)
  self.slow_radius = r
end

function steer:set_mass(m)
  self.point:set_mass(m)
end

function steer:set_dscale(s)
	self.dscale = s
	self.point:set_dscale(s)
end

function steer:set_approach_factor(f)
	self.approach_factor = f
end

function steer:get_position()
  return self.point:get_position()
end

------------------------------------------------------------------------------
function steer:_get_steer_force()
  local desired = self.target - self.point:get_position()
  desired = desired:normalize()
  
  -- set length of desired vector
  local r = self.slow_radius
  local dist_sq = vector2:dist_sq(self.point.pos, self.target)
  if dist_sq < r * r then
    desired = desired * self.max_vel * (math.sqrt(dist_sq) / r) * self.approach_factor
  else
    desired = desired * self.max_vel
  end
  
  
  local force = desired - self.point.vel
  force = force:limit(self.max_force)
  
  return force
end

------------------------------------------------------------------------------
function steer:update(dt)
  if self.target then
    local force = self:_get_steer_force()
    self.point:add_force(force)
  end
  
  self.point:update(dt)
  
end

------------------------------------------------------------------------------
function steer:draw()
  lg.setColor(255,0,0,255)
  lg.setPoint(4, "smooth")
  lg.point(self.point.pos:get_vals())
  
  if self.target then
    lg.setColor(0,255,0,150)
    lg.point(self.target:get_vals())
    lg.circle("line", self.target.x, self.target.y, self.slow_radius)
  end
end


return { point = point,
         steer = steer}












