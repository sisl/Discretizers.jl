abstract type AbstractSampleMethod end
struct SampleUniform        <: AbstractSampleMethod end
struct SampleBinCenter      <: AbstractSampleMethod end

const SAMPLE_UNIFORM          = SampleUniform()
const SAMPLE_BIN_CENTER       = SampleBinCenter()