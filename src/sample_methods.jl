abstract type AbstractSampleMethod end
struct SampleUniform        <: AbstractSampleMethod end
struct SampleBinCenter      <: AbstractSampleMethod end
struct SampleUniformZeroBin <: AbstractSampleMethod end

const SAMPLE_UNIFORM          = SampleUniform()
const SAMPLE_BIN_CENTER       = SampleBinCenter()
const SAMPLE_UNIFORM_ZERO_BIN = SampleUniformZeroBin()