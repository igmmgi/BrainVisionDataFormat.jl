# test_types.jl - Tests for type definitions and constructors

@testset "Type Definitions" begin
    @testset "BrainVisionMarker" begin
        @testset "Constructor" begin
            marker = BrainVisionMarker("Stimulus", "S 11", 1000, 1, nothing)
            
            @test marker.type == "Stimulus"
            @test marker.value == "S 11"
            @test marker.sample == 1000
            @test marker.duration == 1
            @test marker.timestamp === nothing
        end
        
        @testset "With timestamp" begin
            marker = BrainVisionMarker("Response", "R 1", 2000, 1, "20231201120000000000")
            
            @test marker.type == "Response"
            @test marker.value == "R 1"
            @test marker.sample == 2000
            @test marker.duration == 1
            @test marker.timestamp == "20231201120000000000"
        end
    end
    
    @testset "BrainVisionHeader" begin
        @testset "Constructor" begin
            header = BrainVisionHeader(
                "test.eeg",           # DataFile
                "test.vmrk",          # MarkerFile
                "BINARY",             # DataFormat
                "MULTIPLEXED",        # DataOrientation
                "IEEE_FLOAT_32",      # BinaryFormat
                2,                    # NumberOfChannels
                1000.0,               # SamplingInterval
                1000.0,               # Fs
                ["chan1", "chan2"],   # label
                ["", ""],             # reference
                [0.1, 0.1],           # resolution
                ["uV", "uV"],         # unit
                10000,                # nSamples
                1,                    # nTrials
                0,                    # nSamplesPre
                nothing               # impedances
            )
            
            @test header.DataFile == "test.eeg"
            @test header.MarkerFile == "test.vmrk"
            @test header.DataFormat == "BINARY"
            @test header.DataOrientation == "MULTIPLEXED"
            @test header.BinaryFormat == "IEEE_FLOAT_32"
            @test header.NumberOfChannels == 2
            @test header.SamplingInterval == 1000.0
            @test header.Fs == 1000.0
            @test header.label == ["chan1", "chan2"]
            @test header.reference == ["", ""]
            @test header.resolution == [0.1, 0.1]
            @test header.unit == ["uV", "uV"]
            @test header.nSamples == 10000
            @test header.nTrials == 1
            @test header.nSamplesPre == 0
            @test header.impedances === nothing
        end
        
        @testset "With impedances" begin
            impedances = (
                channels = [5.2, 3.1, 4.8],
                reference = Float64[],
                ground = 1.0,
                refChan = Float64[]
            )
            
            header = BrainVisionHeader(
                "test.eeg", "test.vmrk", "BINARY", "MULTIPLEXED", "IEEE_FLOAT_32",
                2, 1000.0, 1000.0, ["chan1", "chan2"], ["", ""], [0.1, 0.1], ["uV", "uV"],
                10000, 1, 0, impedances
            )
            
            @test header.impedances !== nothing
            @test header.impedances.channels == [5.2, 3.1, 4.8]
            @test header.impedances.ground == 1.0
        end
    end
    
    @testset "BrainVisionData" begin
        @testset "Constructor" begin
            header = BrainVisionHeader(
                "test.eeg", "test.vmrk", "BINARY", "MULTIPLEXED", "IEEE_FLOAT_32",
                2, 1000.0, 1000.0, ["chan1", "chan2"], ["", ""], [0.1, 0.1], ["uV", "uV"],
                1000, 1, 0, nothing
            )
            
            eeg_data = rand(2, 1000)
            markers = [
                BrainVisionMarker("Stimulus", "S 1", 100, 1, nothing),
                BrainVisionMarker("Response", "R 1", 200, 1, nothing)
            ]
            
            data = BrainVisionData("test", header, eeg_data, markers)
            
            @test data.filename == "test"
            @test data.header === header
            @test data.data === eeg_data
            @test data.markers == markers
            @test length(data.markers) == 2
            @test data.header.Fs == 1000.0
        end
        
        @testset "Constructor with automatic n_events calculation" begin
            markers = [
                BrainVisionMarker("Stimulus", "S 1", 100, 1, nothing),
                BrainVisionMarker("Stimulus", "S 2", 200, 1, nothing),
                BrainVisionMarker("Response", "R 1", 300, 1, nothing)
            ]
            
            data = BrainVisionData("test", nothing, nothing, markers)
            
            @test length(data.markers) == 3
        end
    end
    
    @testset "BrainVisionMarkerData" begin
        @testset "Constructor" begin
            markers = [
                BrainVisionMarker("Stimulus", "S 1", 100, 1, nothing),
                BrainVisionMarker("Stimulus", "S 2", 200, 1, nothing)
            ]
            
            data = BrainVisionMarkerData("test.vmrk", markers)
            
            @test data.filename == "test.vmrk"
            @test data.markers == markers
            @test length(data.markers) == 2
        end
    end
end
