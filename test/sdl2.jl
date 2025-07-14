using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2


@assert SDL_Init(SDL_INIT_GAMECONTROLLER) == 0

@show SDL_NumJoysticks()
# js = SDL_JoystickOpen(1)
# @show js

for i in 0:SDL_NumJoysticks()-1
    @show i,SDL_IsGameController(i)
end
gc = SDL_GameControllerOpen(0)
@show gc
@show SDL_GameControllerPath(gc)
@show SDL_GameControllerName(gc)
@show SDL_GameControllerGetType(gc)
@show SDL_GameControllerGetAttached(gc)
@show SDL_GameControllerHasRumble(gc)
for axis in instances(SDL_GameControllerAxis)[2:end]
    v = SDL_GameControllerGetAxis(gc, axis)
    SDL_GameControllerUpdate()
    sleep(0.01)
    @show SDL_GameControllerHasAxis(gc, axis),v
end
SDL_GameControllerUpdate()
for btn in instances(SDL_GameControllerButton)
    v = SDL_GameControllerGetButton(gc, btn)
    @show btn,SDL_GameControllerHasButton(gc, btn),v
end
@show SDL_GameControllerHasLED(gc)
for sens in instances(SDL_SensorType)
    @show SDL_GameControllerHasSensor(gc, sens),SDL_GameControllerIsSensorEnabled(gc, sens)
end
SDL_GameControllerRumble(gc, 0xEFFF, 0xEFFF, 4000)
@show SDL_GameControllerMapping(gc)

sleep(1)
SDL_Quit()
