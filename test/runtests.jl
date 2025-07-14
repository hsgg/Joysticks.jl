using Joysticks
using Test

@testset "Joysticks.jl" begin
    @testset "normalize_to_float" begin
        @test Joysticks.normalize_to_float(typemin(Int16)) == -1
        @test Joysticks.normalize_to_float(typemax(Int16)) == 1
        @test Joysticks.normalize_to_float(typemax(Int16)) isa Real
    end
end
