using MultiBroadcast
using Base.Test

function bivariate_multi_broadcast_test(f, x, y)
    a, b = multi_broadcast(f, x, y)
    @test a == first.(f.(x, y))
    @test b == last.(f.(x, y))
end

@testset "multibroadcast arrays" begin
    f(x, y) = x+y, x*y
    bivariate_multi_broadcast_test(f, 1:3, [5, 7, 11])
    bivariate_multi_broadcast_test(f, 1:3, [5, 7, 11]')
end


