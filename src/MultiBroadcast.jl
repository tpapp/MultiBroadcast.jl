module MultiBroadcast

import Base: size, ndims, eltype, getindex, setindex!

import Base.Broadcast: _broadcast_eltype, broadcast_indices, broadcast!

export multi_broadcast

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

end # module
