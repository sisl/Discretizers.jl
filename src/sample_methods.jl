abstract AbstractSampleMethod
immutable SampleUniform        <: AbstractSampleMethod end
immutable SampleBinCenter      <: AbstractSampleMethod end
immutable SampleUniformZeroBin <: AbstractSampleMethod end

const SAMPLE_UNIFORM          = SampleUniform()
const SAMPLE_BIN_CENTER       = SampleBinCenter()
const SAMPLE_UNIFORM_ZERO_BIN = SampleUniformZeroBin()