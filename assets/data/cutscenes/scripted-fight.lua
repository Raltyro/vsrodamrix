local video

local function after()
	state.camNotes.visible = true
	state.camHUD.visible = true
	game.camera.visible = true
	state:remove(video)

	state.currentTransition = Transition(State.defaultTransIn, "in", state)

	state.camFollow:set(state.gf:getGraphicMidpoint())
	game.camera:snapToTarget()
	local zoom = game.camera.zoom
	game.camera.zoom = zoom + .5

	Timer.tween(3, game.camera, {zoom = zoom}, "out-quad", function()
		state:startCountdown()
		close()
	end)
end

function create()
	state.camNotes.visible = false
	state.camHUD.visible = false
	game.camera.visible = false

	video = Video(paths.getVideo('Cutscene1'), true, after):fitToScreen()
	video.cameras = {state.camOther}
	state:add(video)
end

function postCreate()
	video:play()
end