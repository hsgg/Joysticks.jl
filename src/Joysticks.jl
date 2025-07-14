#= MIT License

Copyright (c) 2022 Uwe Fechner, José Joaquín Zubieta Rico

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. =#

module Joysticks

export find_gamepad, get_gamepad_state

using Observables

import GLFW

using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2


const DEFAULT_DEADZONE = 0.07f0


# Axes and triggers
struct GamepadAxesState
    LX::Float32  # Left x-axis
    LY::Float32  # Left y-axis
    RX::Float32  # Right x-axis
    RY::Float32  # Right y-axis
    LT::Float32  # Left trigger
    RT::Float32  # Right trigger
end

# normalize_to_float(x::Integer, T=Float32) = (2 * T(x) + 1) / (T(typemax(x)) - T(typemin(x)))
# normalize_to_float(x::Integer, T=Float32) = T(x) / (1 + T(typemax(x)))
normalize_to_float(x::Integer, T=Float32) = T(x) / (x >= 0 ? T(typemax(x)) : abs(T(typemin(x))))

normalize_to_float(x::Real) = x

function GamepadAxesState(LX_in, LY_in, RX_in, RY_in, LT_in, RT_in, deadzone)
    LX = zero_deadzone(normalize_to_float(LX_in), deadzone)
    LY = zero_deadzone(normalize_to_float(LY_in), deadzone)
    RX = zero_deadzone(normalize_to_float(RX_in), deadzone)
    RY = zero_deadzone(normalize_to_float(RY_in), deadzone)
    LT = normalize_to_float(LT_in)
    RT = normalize_to_float(RT_in)
    return GamepadAxesState(LX, LY, RX, RY, LT, RT)
end

function zero_deadzone(axis, deadzone=DEFAULT_DEADZONE)
    if abs(axis) < deadzone
        return zero(axis)
    elseif axis > 0
        return (axis - deadzone)/(1-deadzone)
    else
        return (axis + deadzone)/(1-deadzone)
    end
end


# Buttons
struct GamepadButtonsState
    A::Bool  # A button
    B::Bool  # B button
    X::Bool  # X button
    Y::Bool  # Y button
    LB::Bool  # Left bumper
    RB::Bool  # Right bumper
    BACK::Bool   # WIN
    START::Bool  # MENU
    GUIDE::Bool  # HOME
    LS::Bool  # Left thumb/stick
    RS::Bool  # Right thumb/stick
    DPAD_UP::Bool
    DPAD_RIGHT::Bool
    DPAD_DOWN::Bool
    DPAD_LEFT::Bool
    MISC1::Bool
end


function find_gamepad(; glfw=false)
    if glfw
        println("Using GLFW3.")
        for joy in instances(GLFW.Joystick)
            if GLFW.JoystickIsGamepad(joy)
                name = GLFW.GetGamepadName(joy)
                println("Found gamepad '$name' as $joy.")
                return joy
            end
        end

    else
        println("Using SDL2.")

        if SDL_WasInit(SDL_INIT_GAMECONTROLLER) == 0
            ret = SDL_Init(SDL_INIT_GAMECONTROLLER)
            if ret != 0
                @warn("ERROR: Could not initialize SDL gamecontroller subsystem: ret=$ret")
                return nothing
            end
        end

        for i in 0:SDL_NumJoysticks()-1
            if SDL_IsGameController(i) == SDL_TRUE
                joy = SDL_GameControllerOpen(i)
                println("Found game controller '$(SDL_GameControllerGetType(joy))'.")
                return joy
            end
        end
    end

    return nothing
end


function get_gamepad_state(::Nothing; kwargs...)
    return nothing, nothing
end


function get_gamepad_state(gp::GLFW.Joystick; deadzone=DEFAULT_DEADZONE)

    state = GLFW.GetGamepadState(gp)

    if isnothing(state)
        return nothing, nothing
    end

    ax = GamepadAxesState(state.axes[GLFW.GAMEPAD_AXIS_LEFT_X+1],
                          state.axes[GLFW.GAMEPAD_AXIS_LEFT_Y+1],
                          state.axes[GLFW.GAMEPAD_AXIS_RIGHT_X+1],
                          state.axes[GLFW.GAMEPAD_AXIS_RIGHT_Y+1],
                          state.axes[GLFW.GAMEPAD_AXIS_LEFT_TRIGGER+1],
                          state.axes[GLFW.GAMEPAD_AXIS_RIGHT_TRIGGER+1],
                          deadzone)

    btn = GamepadButtonsState(state.buttons[GLFW.GAMEPAD_BUTTON_A+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_B+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_X+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_Y+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_LEFT_BUMPER+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_RIGHT_BUMPER+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_BACK+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_START+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_GUIDE+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_LEFT_THUMB+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_RIGHT_THUMB+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_DPAD_UP+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_DPAD_RIGHT+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_DPAD_DOWN+1],
                              state.buttons[GLFW.GAMEPAD_BUTTON_DPAD_LEFT+1],
                              false)
    return ax, btn
end


function get_gamepad_state(gp::Ptr{SDL_GameController}; deadzone=DEFAULT_DEADZONE)

    if SDL_GameControllerGetAttached(gp) != SDL_TRUE
        return nothing, nothing
    end

    SDL_GameControllerUpdate()

    ax = GamepadAxesState(SDL_GameControllerGetAxis(gp, SDL_CONTROLLER_AXIS_LEFTX),
                          SDL_GameControllerGetAxis(gp, SDL_CONTROLLER_AXIS_LEFTY),
                          SDL_GameControllerGetAxis(gp, SDL_CONTROLLER_AXIS_RIGHTX),
                          SDL_GameControllerGetAxis(gp, SDL_CONTROLLER_AXIS_RIGHTY),
                          SDL_GameControllerGetAxis(gp, SDL_CONTROLLER_AXIS_TRIGGERLEFT),
                          SDL_GameControllerGetAxis(gp, SDL_CONTROLLER_AXIS_TRIGGERRIGHT),
                          deadzone)

    btn = GamepadButtonsState(SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_A),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_B),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_X),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_Y),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_LEFTSHOULDER),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_RIGHTSHOULDER),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_BACK),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_START),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_GUIDE),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_LEFTSTICK),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_RIGHTSTICK),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_DPAD_UP),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_DPAD_RIGHT),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_DPAD_DOWN),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_DPAD_LEFT),
                              SDL_GameControllerGetButton(gp, SDL_CONTROLLER_BUTTON_MISC1))
    return ax, btn
end



end
