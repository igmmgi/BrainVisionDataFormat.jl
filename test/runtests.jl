using Test

# Import the package
using BrainVisionDataFormat

# Clean up old coverage files at the start
if Base.JLOptions().code_coverage != 0
    println("\nCleaning up old coverage files...")
    using Coverage
    Coverage.clean_folder(joinpath(@__DIR__, "..", "src"))
    Coverage.clean_folder(@__DIR__)
end

println("Running BrainVisionDataFormat.jl Test Suite")
println("=" ^ 40)

@testset "BrainVisionDataFormat" begin
    include("test_reader.jl")
    include("test_types.jl")
    include("test_validation.jl")
    include("test_utils.jl")
end

println("\nAll tests completed!")
