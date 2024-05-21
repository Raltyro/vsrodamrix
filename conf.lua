local Project = require "project"

function love.conf(t)
	t.identity = Project.package
	t.console = Project.DEBUG_MODE
	t.gammacorrect = false
	t.highdpi = false

	-- In Mobile, it's Vulkan
	--t.renderers = {"vulkan"}
	t.renderers = {"metal", "opengl"}

	-- we'll initialize the window in loxel/init.lua
	-- reason why is, we need it for mobile window to not be bugging
	t.modules.window = false
	t.modules.physics = false
	t.modules.touch = false
	--t.modules.video = false
end
