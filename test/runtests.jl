using MultiBroadcast
using Base.Test

@testset "multibroadcast vectors" begin
    x = 1:3
    y = [5,7,11]
    f(x, y) = x+y, x*y
    a, b = multi_broadcast(f, x, y)
    @test a == x .+ y
    @test b == x .* y
end
