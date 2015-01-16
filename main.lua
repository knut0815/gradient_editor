lg = love.graphics

function love.keypressed(key)
  if key == 'escape' then
    love.event.push('quit')
  end
  
  if DISPLAY_EDITOR then
    gradient_editor:keypressed(key)
  end
end

function love.mousepressed(x, y, button)
  if DISPLAY_EDITOR then
    gradient_editor:mousepressed(x, y, button)
  end
end

function love.load()
  --[[
    USAGE:
      love ./ tilemap_images_folder save_filename_prefix
  ]]--

  -- globals
  DISPLAY_EDITOR = true
  SCR_WIDTH = love.graphics.getWidth()
  SCR_HEIGHT = love.graphics.getHeight()
  TILE_WIDTH = 32
  TILE_HEIGHT = 32
  MAX_IMAGE_WIDTH = 2048                  -- in pixels
  MAX_IMAGE_HEIGHT = 2048
  C_BLACK = {0, 0, 0, 255}
  C_WHITE = {255, 255, 255, 255}

  local num_colors = arg[2] or 400
  SAVE_ID = 1

  love.filesystem.setIdentity("gradients")
  
  -- objects
  lg.setBackgroundColor(255,255,255,255)
  --local timers = require('pe-timers')
  --timer, master_timer = timers[1], timers[2]
  vector2 = require('pe-vector2')
  bbox = require('pe-bbox')
  gui_slider = require('gui_slider')
  cubic_spline = require('pe-cubic_spline')
  color_widget = require('color_widget')
  curve_widget = require('curve_widget')
  gradient_editor = require('gradient_editor')
  
  if DISPLAY_EDITOR then
   gradient_editor = gradient_editor:new(120, 20, tonumber(num_colors))
  end
  
end

function love.update(dt)
  
  if DISPLAY_EDITOR then
    gradient_editor:update(dt)
  end

end

function love.draw()
  if DISPLAY_EDITOR then
    gradient_editor:draw()
  end
end

















