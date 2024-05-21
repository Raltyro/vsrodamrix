local video

local function after()
	video:reset(true)

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

	--video = SkippableVideo(paths.getVideo('Cutscene1'), false, function()
	--	Timer.tween(.2, video, {alpha = 0}, "in-sine", after)
	--end):fitToScreen()
	video = SkippableVideo(paths.getVideo('Cutscene1'), true, after)
	video.cameras = {state.camOther}
	state:add(video)
end

function postCreate()
	video:play()
end