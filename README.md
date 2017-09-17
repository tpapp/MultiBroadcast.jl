# MultiBroadcast

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.org/tpapp/MultiBroadcast.jl.svg?branch=master)](https://travis-ci.org/tpapp/MultiBroadcast.jl)
[![Coverage Status](https://coveralls.io/repos/tpapp/MultiBroadcast.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tpapp/MultiBroadcast.jl?branch=master)
[![codecov.io](http://codecov.io/github/tpapp/MultiBroadcast.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/MultiBroadcast.jl?branch=master)

## Introduction

This is an **experimental** Julia package that explores broadcasting functions
with multiple values (cf
[#23734](https://github.com/JuliaLang/julia/issues/23734)). The only
exported function is `multi_broadcast`, which is best explained with
an example:

```julia
f(x) = x+1, 2*x
a, b = multi_broadcast(f, 1:10)
a == collect(2:11)
b == collect(2:2:20)
```
There is a convenience syntax for this with the `@multi` macro:
```julia
@multi f.(1:10)
```

The package also extends `broadcast!`, so if you preallocate for the output, you can do
```julia
x = 1:10
a = similar(BitArray, x)
b = similar(Array{Int}, x)
f(x) = isodd(x), 3*x
a, b .= f.(a, b) # note: no new syntax required
```

## Implementation

I am relying on the existing implementation of `broadcast` as much as
possible, saving values in a thin wrapper type that contains a tuple
of arrays. Whether this is a viable approach remains to be seen.

I wrote this up so that I can experiment with the interface, and
because I find the functionality useful. If you have suggestions for
improvement, please open an issue or make a PR.
