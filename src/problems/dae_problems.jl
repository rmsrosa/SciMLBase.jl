@doc doc"""

Defines an implicit ordinary differential equation (ODE) or
differential-algebraic equation (DAE) problem.
Documentation Page: https://diffeq.sciml.ai/stable/types/dae_types/

## Mathematical Specification of an DAE Problem

To define a DAE Problem, you simply need to give the function ``f`` and the initial
condition ``u_0`` which define an ODE:

```math
0 = f(du,u,p,t)
```

`f` should be specified as `f(du,u,p,t)` (or in-place as `f(resid,du,u,p,t)`).
Note that we are not limited to numbers or vectors for `u₀`; one is allowed to
provide `u₀` as arbitrary matrices / higher dimension tensors as well.

## Problem Type

### Constructors

- `DAEProblem(f::DAEFunction,du0,u0,tspan,p=NullParameters();kwargs...)`
- `DAEProblem{isinplace}(f,du0,u0,tspan,p=NullParameters();kwargs...)` :
  Defines the DAE with the specified functions.
  `isinplace` optionally sets whether the function is inplace or not. This is
  determined automatically, but not inferred.

Parameters are optional, and if not given then a `NullParameters()` singleton
will be used which will throw nice errors if you try to index non-existent
parameters. Any extra keyword arguments are passed on to the solvers. For example,
if you set a `callback` in the problem, then that `callback` will be added in
every solve call.

For specifying Jacobians and mass matrices, see the
[DiffEqFunctions](@ref performance_overloads)
page.

### Fields

* `f`: The function in the ODE.
* `du0`: The initial condition for the derivative.
* `u0`: The initial condition.
* `tspan`: The timespan for the problem.
* `differential_vars`: A logical array which declares which variables are the
  differential (non algebraic) vars (i.e. `du'` is in the equations for this
  variable). Defaults to nothing. Some solvers may require this be set if an
  initial condition needs to be determined.
* `p`: The parameters for the problem. Defaults to `NullParameters`
* `kwargs`: The keyword arguments passed onto the solves.

## Example Problems

Examples problems can be found in [DiffEqProblemLibrary.jl](https://github.com/JuliaDiffEq/DiffEqProblemLibrary.jl/blob/master/src/dae_premade_problems.jl).

To use a sample problem, such as `prob_dae_resrob`, you can do something like:

```julia
#] add DiffEqProblemLibrary
using DiffEqProblemLibrary.DAEProblemLibrary
# load problems
DAEProblemLibrary.importdaeproblems()
prob = DAEProblemLibrary.prob_dae_resrob
sol = solve(prob,IDA())
```
"""
struct DAEProblem{uType, duType, tType, isinplace, P, F, K, D} <:
       AbstractDAEProblem{uType, duType, tType, isinplace}
    f::F
    du0::duType
    u0::uType
    tspan::tType
    p::P
    kwargs::K
    differential_vars::D
    @add_kwonly function DAEProblem{iip}(f::AbstractDAEFunction{iip},
                                         du0, u0, tspan, p = NullParameters();
                                         differential_vars = nothing,
                                         kwargs...) where {iip}
        # Defend against external solvers like Sundials breaking on non-uniform input dimensions.
        size(du0) == size(u0) ||
            throw(ArgumentError("Sizes of u0 `$(size(u0))` and du0 `$(size(u0))` must be the same."))
        if !isnothing(differential_vars)
            size(u0) == size(differential_vars) ||
                throw(ArgumentError("Sizes of u0 `$(size(u0))` and differential_vars `$(size(differential_vars))` must be the same."))
        end
        _tspan = promote_tspan(tspan)
        new{typeof(u0), typeof(du0), typeof(_tspan),
            isinplace(f), typeof(p),
            typeof(f), typeof(kwargs),
            typeof(differential_vars)}(f, du0, u0, _tspan, p,
                                       kwargs, differential_vars)
    end

    function DAEProblem{iip}(f, du0, u0, tspan, p = NullParameters(); kwargs...) where {iip}
        DAEProblem(DAEFunction{iip}(f), du0, u0, tspan, p; kwargs...)
    end
end

function DAEProblem(f::AbstractDAEFunction, du0, u0, tspan, p = NullParameters(); kwargs...)
    DAEProblem{isinplace(f)}(f, du0, u0, tspan, p; kwargs...)
end

function DAEProblem(f, du0, u0, tspan, p = NullParameters(); kwargs...)
    DAEProblem(DAEFunction(f), du0, u0, tspan, p; kwargs...)
end
