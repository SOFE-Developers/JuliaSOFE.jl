__precompile__()

module Elements

import ..Helpers: dimension

export AbstractElement, PElement, QElement, Element
export LagrangeP1, LagrangeQ1
export dimension, order, nBasis, nVertices, dofTuple, nDoF, evalBasis, isnodal

abstract AbstractElement
abstract PElement <: AbstractElement
abstract QElement <: AbstractElement

typealias ElementTypes Union{PElement, QElement}

typealias Float AbstractFloat

#--------------#
# Type Element #
#--------------#
type Element{T<:ElementTypes} <: AbstractElement
    dimension :: Int
    type_ :: Type
end
Element{T<:ElementTypes}(::Type{T}, dim::Integer) = Element{T}(dim, T)

# Associated methods
# -------------------
"""

    dimension(el::Element)

  The topological dimension of the element.
"""
@inline dimension(el::Element) = el.dimension

"""

    type_(el::Element)

  Return the concrete child type of the element.
"""
@inline type_(el::Element) = el.type_

"""

    order(el::Element)

  The polynomial order of the element's basis (shape) functions.
"""
function order(el::Element)
end

"""

    nBasis(el::Element, [d::Integer])

  The number of basis (shape) functions associated with the 
  `d`-dimensional entities of the element.
"""
@inline nBasis(el::Element, d::Integer) = nBasis(el)[d]

"""

    nVertices(el::Element, [d::Integer])

  The number of vertices that define the `d`-dimensional
  entities of the element.
"""
@inline nVertices(el::Element, d::Integer) = nVertices(el)[d]
@inline nVertices{T<:PElement}(el::Element{T}) = tuple(2:(dimension(el)+1)...)
@inline nVertices{T<:QElement}(el::Element{T}) = tuple(2.^(1:dimension(el))...)

@inline nDoF(el::Element) = nDoF(el, dimension(el))
function nDoF{T<:PElement}(el::Element{T}, d::Integer)
    #return map(*, dofTuple(el), binomial(dimension(el)+1, k) for k = 1:dimension(el)+1)
    return map(*, dofTuple(el), binomial(d+1, k) for k = 1:d+1)
end
function nDoF{T<:QElement}(el::Element{T})
    if dimension(el) == 1
        return map(*, dofTuple(el), (2,1))
    elseif dimension(el) == 2
        return map(*, dofTuple(el), (4,4,1))
    elseif dimension(el) == 3
        return map(*, dofTuple(el), (8,12,6,1))
    else
        error("Invalid element dimension ", dimension(el))
    end
end

"""

    evalBasis{T<:AbstractFloat}(el::Element, points::AbstractArray{T,1}, deriv::Integer=0)

  Evaluate the element's shape (basis) functions at given `points`
  on the reference domain.
"""
function evalBasis{T<:AbstractFloat}(el::Element,
                                     points::AbstractArray{T,2},
                                     deriv::Integer=0)
    nP, nW = size(points)
    nB = nBasis(el, nW)
    nC = 1

    if deriv == 0
        B = zeros(T, nB, nP, nC)
        return evalD0Basis!(el, points, B) # nB x nP x nC
    elseif deriv == 1
        B = zeros(T, nB, nP, nC, nW)
        return evalD1Basis!(el, points, B) # nB x nP x nC x nW
    elseif deriv == 2
        B = zeros(T, nB, nP, nC, nW, nW)
        return evalD2Basis!(el, points, B) # nB x nP x nC x nW x nW
    else
        error("Invalid derivation order! ($deriv)")
    end
end

#-----------------#
# Type LagrangeP1 #
#-----------------#
type LagrangeP1 <: PElement
end
LagrangeP1(dim::Integer) = Element(LagrangeP1, dim)

isnodal(::Element{LagrangeP1}) = true
order(::Element{LagrangeP1}) = 1
nBasis(el::Element{LagrangeP1}) = tuple(2:(dimension(el)+1)...)
dofTuple(el::Element{LagrangeP1}) = (1, 0, 0, 0)[1:dimension(el)+1]

# Associated Methods
# -------------------
function evalD0Basis!{T<:Float}(el::Element{LagrangeP1}, points::AbstractArray{T,2}, out::Array{T,3})
    for ip = 1:size(points, 1)
        out[1,ip,1] = one(T)
        for id = 1:size(points, 2)
            out[1,ip,1] -= points[ip,id]
            out[id+1,ip,1] = points[ip,id]
        end
    end
    return out
end

function evalD1Basis!{T<:Float}(el::Element{LagrangeP1}, points::AbstractArray{T,2}, out::Array{T,4})
    out[1,:,1,:] = -one(T)
    for k = 1:size(out, 1)-1
        out[k+1,:,1,k] = one(T)
    end
    return out
end

function evalD2Basis!{T<:Float}(el::Element{LagrangeP1}, points::AbstractArray{T,2}, out::Array{T,5})
    out[:] = zero(T)
    return out
end

#-----------------#
# Type LagrangeQ1 #
#-----------------#
type LagrangeQ1 <: QElement
end
LagrangeQ1(dim::Integer) = Element(LagrangeQ1, dim)

isnodal(::Element{LagrangeQ1}) = true
order(::Element{LagrangeQ1}) = 1
nBasis(el::Element{LagrangeQ1}) = tuple(2.^(1:dimension(el))...)
dofTuple(el::Element{LagrangeQ1}) = (1, 0, 0, 0)[1:dimension(el)+1]

# Associated Methods
# -------------------
function evalD0Basis!{T<:Float}(el::Element{LagrangeQ1}, points::AbstractArray{T,2}, out::Array{T,3})
    nD = size(points, 2)
    if nD == 1
        out[1,:,1] = 1-points[:,1];
        out[2,:,1] = points[:,1];
    elseif nD == 2
        out[1,:,1] = (1-points[:,1]).*(1-points[:,2]);
        out[2,:,1] = points[:,1].*(1-points[:,2]);
        out[3,:,1] = (1-points[:,1]).*points[:,2];
        out[4,:,1] = points[:,1].*points[:,2];
    elseif nD == 3
        out[1,:,1] = (1-points[:,1]).*(1-points[:,2]).*(1-points[:,3]);
        out[2,:,1] = points[:,1].*(1-points[:,2]).*(1-points[:,3]);
        out[3,:,1] = (1-points[:,1]).*points[:,2].*(1-points[:,3]);
        out[4,:,1] = points[:,1].*points[:,2].*(1-points[:,3]);
        out[5,:,1] = (1-points[:,1]).*(1-points[:,2]).*points[:,3];
        out[6,:,1] = points[:,1].*(1-points[:,2]).*points[:,3];
        out[7,:,1] = (1-points[:,1]).*points[:,2].*points[:,3];
        out[8,:,1] = points[:,1].*points[:,2].*points[:,3];
    else
        error("Invalid point dimension ", nD)
    end
    return out
end

function evalD1Basis!{T<:Float}(el::Element{LagrangeQ1}, points::AbstractArray{T,2}, out::Array{T,4})
    nD = size(points, 2)
    if nD == 1
        out[1,:,1,1] = -1;
        out[2,:,1,1] = 1;
    elseif nD == 2
        out[1,:,1,1] = -(1-points[:,2]);
        out[1,:,1,2] = -(1-points[:,1]);
        out[2,:,1,1] = 1-points[:,2];
        out[2,:,1,2] = -points[:,1];
        out[3,:,1,1] = -points[:,2];
        out[3,:,1,2] = 1-points[:,1];
        out[4,:,1,1] = points[:,2];
        out[4,:,1,2] = points[:,1];
    elseif nD == 3
        out[1,:,1,1] = -(1-points[:,2]).*(1-points[:,3]);
        out[1,:,1,2] = -(1-points[:,1]).*(1-points[:,3]);
        out[1,:,1,3] = -(1-points[:,1]).*(1-points[:,2]);

        out[2,:,1,1] = (1-points[:,2]).*(1-points[:,3]);
        out[2,:,1,2] = -points[:,1].*(1-points[:,3]);
        out[2,:,1,3] = -points[:,1].*(1-points[:,2]);

        out[3,:,1,1] = -points[:,2].*(1-points[:,3]);
        out[3,:,1,2] = (1-points[:,1]).*(1-points[:,3]);
        out[3,:,1,3] = -(1-points[:,1]).*points[:,2];

        out[4,:,1,1] = points[:,2].*(1-points[:,3]);
        out[4,:,1,2] = points[:,1].*(1-points[:,3]);
        out[4,:,1,3] = -points[:,1].*points[:,2];

        out[5,:,1,1] = -(1-points[:,2]).*points[:,3];
        out[5,:,1,2] = -(1-points[:,1]).*points[:,3];
        out[5,:,1,3] = (1-points[:,1]).*(1-points[:,2]);
        
        out[6,:,1,1] = (1-points[:,2]).*points[:,3];
        out[6,:,1,2] = -points[:,1].*points[:,3];
        out[6,:,1,3] = points[:,1].*(1-points[:,2]);
        
        out[7,:,1,1] = -points[:,2].*points[:,3];
        out[7,:,1,2] = (1-points[:,1]).*points[:,3];
        out[7,:,1,3] = (1-points[:,1]).*points[:,2];
        
        out[8,:,1,1] = points[:,2].*points[:,3];
        out[8,:,1,2] = points[:,1].*points[:,3];
        out[8,:,1,3] = points[:,1].*points[:,2];
    else
        error("Invalid point dimension ", nD)
    end
    return out
end

function evalD2Basis!{T<:Float}(el::Element{LagrangeQ1}, points::AbstractArray{T,2}, out::Array{T,5})
  out[:] = zero(T)
  return out
end

end # of module Elements

