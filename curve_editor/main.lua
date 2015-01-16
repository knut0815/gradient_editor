lg = love.graphics
lf = love.filesystem
lk = love.keyboard

function love.keypressed(key)
  if key == "escape" then
    love.event.push("quit")
  end
  
  for i,cb in ipairs(CURVE_BUILDERS) do
    cb:keypressed(key)
  end
  
  if key == "w" then
    for i,cb in ipairs(CURVE_BUILDERS) do
      cb:write_to_file()
    end
  end
end

function love.mousepressed(x, y, button)
  for i,cb in ipairs(CURVE_BUILDERS) do
    cb:mousepressed(x, y, button)
  end
end

function love.mousereleased(x, y, button)
  for i,cb in ipairs(CURVE_BUILDERS) do
    cb:mousereleased(x, y, button)
  end
end

function parse_arguments(args)
  SCR_WIDTH = args[2]
  SCR_HEIGHT = args[3]
  IDENTITY = "curve_editor"
  
  local filenames = {}
  for i=4,#args do
    if args[i] ~= "--console" then
      filenames[#filenames + 1] = args[i]
    end
  end
  
  if #filenames == 0 then
    print("USAGE: love ./ screen_width screen_height filename1 filename2 ...")
    love.update = function() end
    lg.setColor(255,255,255,255)
    love.draw = function() lg.print("error", 100, 100) end
  end
  FILENAMES = filenames
  NUM_FILES = #filenames
  
  for i=1,#filenames do
    print(i..". "..filenames[i])
  end
  love.window.setMode(SCR_WIDTH, SCR_HEIGHT)
  lg.setBackgroundColor(255, 255, 255, 255)
  
end

function init_curve_builders()
  local LEFT_PAD = 50
  local RIGHT_PAD = 50
  local TOP_PAD = 25
  local BOTTOM_PAD = 0
  local STACK_PAD = 25
  
  bbox = require('bbox')
  cubic_spline = require("cubic_spline")
  curve_builder = require("curve_builder")
  CURVE_BUILDERS = {}
  
  local x, y = LEFT_PAD, TOP_PAD
  local width = SCR_WIDTH - LEFT_PAD - RIGHT_PAD
  local height = SCR_HEIGHT - TOP_PAD - BOTTOM_PAD
  local num_cb = NUM_FILES
  local cb_width = width
  local cb_height = (height / num_cb) - STACK_PAD
  
  for i=1,num_cb do
    local cx, cy = x, y + (i-1) * (cb_height + STACK_PAD)
    CURVE_BUILDERS[i] = curve_builder:new(cx, cy, cb_width, cb_height, FILENAMES[i])
  end
  
end

function love.load(args)
  parse_arguments(args)
  init_curve_builders()
end

function love.update(dt)
  for i,cb in ipairs(CURVE_BUILDERS) do
    cb:update(dt)
  end
end

function love.draw()
  for i,cb in ipairs(CURVE_BUILDERS) do
    cb:draw()
  end
end
























