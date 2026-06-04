using Test

# Import the package
using BrainVisionDataFormat

println("Running BrainVisionDataFormat.jl Test Suite")
println("=" ^ 40)

@testset "BrainVisionDataFormat" begin
    include("test_reader.jl")
    include("test_types.jl")
    include("test_validation.jl")
    include("test_utils.jl")
end

println("\nAll tests completed!")
