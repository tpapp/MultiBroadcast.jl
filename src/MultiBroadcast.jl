module MultiBroadcast

import Base: size, ndims, eltype, getindex, setindex!

import Base.Broadcast: _broadcast_eltype, broadcast_indices, broadcast!

export multi_broadcast, @multi

"""
    TupleofArrays(arrays...)

Helper structure, maps tuple elements to elements in a tuple of arrays.

The main purpose is to define a `setindex!` method, so that multiple returned
values from tuples can be placed in the arrays without intermediate allocation.

**This is not part of the interface, just the implementation. Not exported.**
"""
struct TupleofArrays{S <: Tuple,T,N} <: AbstractArray{T,N}
    arrays::S
    function TupleofArrays(arrays::S) where S
        @assert !isempty(arrays)
        siz = size(first(arrays))
        ixs = indices(first(arrays))
        for a in Base.tail(arrays)
            @assert size(a) == siz "Incompatible dimensions"
            @assert indices(a) == ixs "Incompatible indexing"
        end
        T = Tuple{map(eltype, arrays)...}
        new{S,T,length(siz)}(arrays)
    end
end

size(toa::TupleofArrays) = size(toa.arrays[1])
getindex(toa::TupleofArrays, ixs...) = map(a->a[ixs...], toa.arrays)
eltype(toa::TupleofArrays{S,T,N}) where {S,T,N} = T
dims(toa::TupleofArrays{S,T,N}) where {S,T,N} = N
setindex!(toa::TupleofArrays, value, ixs...) =
    map((a,v)->setindex!(a, v, ixs...), toa.arrays, value)

function TupleofArrays(eltype, shape, booltobits = true)
    arraytype(T) = booltobits && T == Bool ? BitArray : Array{T}
    TupleofArrays(map(T -> similar(arraytype(T), shape),
                      tuple(eltype.parameters...)))
end

function broadcast!(f, result::NTuple{N,AbstractArray}, args...) where N
    toa = TupleofArrays(result)
    broadcast!(f, toa, args...)
    toa.arrays
end

function multi_broadcast(f, args...)
    T = _broadcast_eltype(f, args...)
    @assert(T <: Tuple && !(T.parameters[end] <: Vararg), # FIXME kludge
            "The inferred return type is not a fixed-length tuple.")
    shape = broadcast_indices(args...)
    toa = TupleofArrays(T, shape)
    broadcast!(f, toa, args...)
    toa.arrays
end

"""
    @multi f.(args...)

Replaces the outermost broadcast in the expanded expression with
`multi_broadcast`, which collects the results in multiple values.

```jldoctest
julia> f(x, y) = x+y, x*y
f (generic function with 1 method)
julia> a, b = @multi f.([1, 2], [3, 5]);
julia> a
2-element Array{Int64,1}:
 4
 7
julia> b
2-element Array{Int64,1}:
  3
 10
```
"""
macro multi(ex::Expr)
    ee = expand(ex)      # regularize broadcast(f, ...) and f.(...), is this OK?
    @assert(ee.head == :call && ee.args[1] == GlobalRef(Base, :broadcast),
            "@multi only works on broadcast calls")
    :(multi_broadcast($(map(esc, ee.args[2:end])...)))
end

end # module
