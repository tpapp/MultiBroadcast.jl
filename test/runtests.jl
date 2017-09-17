using MultiBroadcast
using Base.Test

"""
    ≅(x, y)

Test that arrays `x` and `y` are equal (`==`), and have the same type.
"""
≅(x, y) = false
≅(x::Array{T,N}, y::Array{T,N}) where {T,N} = x == y
≅(x::BitArray{N}, y::BitArray{N}) where {N} = x == y

function bivariate_multi_broadcast_test(f, x, y)
    a, b = multi_broadcast(f, x, y)
    @test a ≅ first.(f.(x, y))
    @test b ≅ last.(f.(x, y))
end

@testset "multibroadcast arrays" begin
    f(x, y) = x+y, x*y
    bivariate_multi_broadcast_test(f, 1:3, [5, 7, 11])
    bivariate_multi_broadcast_test(f, 1:3, [5, 7, 11]')
end

@testset "multibroadcast bitarray" begin
    f(x, y) = x == y, x+y
    x = 1:3
    y = [2,3,5]
    a, b = multi_broadcast(f, x, y)
    @test a ≅ (x .== y)
    @test b ≅ (x .+ y)
end
