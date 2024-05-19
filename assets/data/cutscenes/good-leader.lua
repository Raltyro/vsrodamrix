function create()
	state.currentTransition = Transition(State.defaultTransIn, "in", state)

	local x, y = state.boyfriend:getMidpoint()
	state.camFollow:set(
		x - 100 - (state.boyfriend.cameraPosition.x - state.stage.boyfriendCam.x),
		y - 100 + (state.boyfriend.cameraPosition.y + state.stage.boyfriendCam.y)
	)
	local zoom = game.camera.zoom
	game.camera.zoom = zoom + .23
	game.camera:snapToTarget()

	Timer.tween(1.5, game.camera, {zoom = zoom}, "out-quad", function()
		state:startCountdown()
		close()
	end)
end