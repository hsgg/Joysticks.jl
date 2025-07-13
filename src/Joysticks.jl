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

import GLFW


const DEFAULT_DEADZONE = 0.01f0


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
end

# Axes and triggers
struct GamepadAxesState
    LX::Float32  # Left x-axis
    LY::Float32  # Left y-axis
    RX::Float32  # Right x-axis
    RY::Float32  # Right y-axis
    LT::Float32  # Left trigger
    RT::Float32  # Right trigger
end

function GamepadAxesState(LX, LY, RX, RY, LT, RT, deadzone)
    LX = zero_deadzone(LX, deadzone)
    LY = zero_deadzone(LY, deadzone)
    RX = zero_deadzone(RX, deadzone)
    RY = zero_deadzone(RY, deadzone)
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



function find_gamepad()
    for joy in instances(GLFW.Joystick)
        if GLFW.JoystickIsGamepad(joy)
            name = GLFW.GetGamepadName(joy)
            println("Found gamepad '$name' as $joy.")
            return joy
        end
    end
    return nothing
end


function get_gamepad_state(gp; deadzone=DEFAULT_DEADZONE)
    if isnothing(gp)
        return nothing, nothing
    end

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
                              state.buttons[GLFW.GAMEPAD_BUTTON_DPAD_LEFT+1])
    return ax, btn
end



end
