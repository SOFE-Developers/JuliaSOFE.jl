export MixedFESpace
export subspaces, sub, subspace, add, addspace

#-------------------#
# Type MixedFESpace #
#-------------------#
type MixedFESpace <: AbstractFESpace
    subspaces :: Array{FESpace, 1}
end
MixedFESpace(spaces::FESpace...) = MixedFESpace([space for space in spaces])

# Associated Methods
# -------------------
"""

    subspaces(mfes::MixedFESpace)

  Return the each subspace of the mixed finite element space.
"""
subspaces(mfes::MixedFESpace) = getfield(mfes, :subspaces)

"""

    sub(mfes::MixedFESpace, i::Integer)

  Return the `i`th subspace of the mixed finite element space.
"""
sub(mfes::MixedFESpace, i::Integer) = subspaces(mfes)[i]
subspace(mfes::MixedFESpace, i::Integer) = sub(mfes, i)

"""

    add(mfes::MixedFESpace, fes::AbstractFESpace)

  Add the finite element space `fes` to the mixed finite element
  space `mfes`.
"""
add(mfes::MixedFESpace, fes::AbstractFESpace) = push!(mfes.subspaces, fes)
addspace(mfes::MixedFESpace, fes::AbstractFESpace) = add(mfes, fes)

fixedDoF(mfes::MixedFESpace) = mapreduce(fixedDoF, vcat, subspaces(mfes))
freeDoF(mfes::MixedFESpace) = mapreduce(freeDoF, vcat, subspaces(mfes))
nDoF(mfes::MixedFESpace) = mapreduce(nDoF, +, subspaces(mfes))

fixedDoF(mfes::MixedFESpace, i::Integer) = fixedDoF(subspace(mfes, i))
freeDoF(mfes::MixedFESpace, i::Integer) = freeDoF(freeDoF(subspace(mfes, i)))
nDoF(mfes::MixedFESpace, i::Integer) = nDoF(subspace(mfes, i))

# Iteration Interface
# --------------------
Base.getindex(mfes::MixedFESpace, i::Integer) = subspace(mfes, i)
Base.length(mfes::MixedFESpace) = length(subspaces(mfes))
Base.start(::MixedFESpace) = 1
Base.next(mfes::MixedFESpace, state::Integer) = (subspace(mfes, state), state+1)
Base.done(mfes::MixedFESpace, state::Integer) = state > length(mfes)
Base.eltype(::Type{MixedFESpace}) = FESpace
Base.endof(mfes::MixedFESpace) = length(mfes)
