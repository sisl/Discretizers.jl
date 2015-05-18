abstract AbstractSampleMethod
immutable SampleUniform        <: AbstractSampleMethod end
immutable SampleBinCenter      <: AbstractSampleMethod end
immutable SampleUniformZeroBin <: AbstractSampleMethod end

const SAMPLE_UNIFORM          = SampleUniform()
const SAMPLE_BIN_CENTER       = SampleBinCenter()
const SAMPLE_UNIFORM_ZERO_BIN = SampleUniformZeroBin()


function decode{N<:FloatingPoint,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleUniform)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]
    convert(N, lo + rand()*(hi-lo))
end
function decode{N<:FloatingPoint,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleBinCenter)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]
    convert(N, (hi + lo)/2)
end
function decode{N<:FloatingPoint,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleUniformZeroBin)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]

    if lo ≤ 0.0 ≤ hi
        return 0.0
    end
    return convert(N, lo + rand()*(hi-lo))
end
decode{N<:FloatingPoint,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D) = decode(ld, d, SAMPLE_UNIFORM)

function decode{N<:Integer,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleUniform)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]
    if hi != ld.binedges[end]
        retval = rand(lo:hi-1)
    else
        retval = rand(lo:hi)
    end
    convert(N, retval)
end
function decode{N<:Integer,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleBinCenter)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]
    convert(N, div(lo+hi,2))
end
function decode{N<:Integer,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleUniformZeroBin)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]

    if lo ≤ 0 ≤ hi
        retval = 0
    elseif hi != ld.binedges[end]
        retval = rand(lo:hi-1)
    else
        retval = rand(lo:hi)
    end

    convert(N, retval)
end
decode{N<:Integer,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D) = decode(ld, d, SAMPLE_UNIFORM)

decode{N<:Real,D<:Integer,I<:Integer}(ld::LinearDiscretizer{N,D}, d::I, method::AbstractSampleMethod=SAMPLE_UNIFORM) =
    decode(ld, convert(D,d), method)

function decode{N,D<:Integer}(ld::LinearDiscretizer{N,D}, data::AbstractArray{D}, M::AbstractSampleMethod=SAMPLE_UNIFORM)
    arr = Array(N, length(data))
    for (i,d) in enumerate(data)
        arr[i] = decode(ld, d)
    end
    reshape(arr, size(data))
end