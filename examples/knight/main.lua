--load the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Knight Example")

--settings
local projectDir = "examples/knight/"

dream.clouds_enabled = false
dream.AO_enabled = false

dream:init()

knight = dream:loadObject(projectDir.. "knight")

love.graphics.setBackgroundColor(128/255, 218/255, 235/255)

function love.draw()
	dream:resetLight()
	
	dream:prepare()

	knight:reset()
	knight:rotateY(love.timer.getTime())
	
	dream:draw(knight, 0, 0, -8, 0.25)

	dream:present()
end
