# test_reader.jl - Tests for BrainVision file reading functions

@testset "Reader Functions" begin
    # Test data paths
    test_data_dir = joinpath(@__DIR__, "data")
    test_vhdr = joinpath(test_data_dir, "test.vhdr")
    test_vmrk = joinpath(test_data_dir, "test.vmrk")
    test_eeg = joinpath(test_data_dir, "test.eeg")
    
    @testset "read_brainvision_header" begin
        @testset "Valid header file" begin
            header = read_brainvision_header(test_vhdr)
            
            # Test basic properties
            @test header.DataFile == "test.eeg"
            @test header.MarkerFile == "test.vmrk"
            @test header.DataFormat == "BINARY"
            @test header.DataOrientation == "MULTIPLEXED"
            @test header.BinaryFormat == "IEEE_FLOAT_32"
            @test header.NumberOfChannels == 2
            @test header.SamplingInterval == 1000.0
            @test header.Fs == 1000.0  # 1e6 / 1000
            
            # Test channel information
            @test length(header.label) == 2
            @test header.label[1] == "chan1"
            @test header.label[2] == "chan2"
            @test length(header.resolution) == 2
            @test header.resolution[1] == 0.1
            @test header.resolution[2] == 0.1
            @test length(header.unit) == 2
            @test header.unit[1] == "uV"
            @test header.unit[2] == "uV"
        end
        
        @testset "File not found" begin
            @test_throws ArgumentError read_brainvision_header("nonexistent.vhdr")
        end
        
    end
    
    @testset "read_brainvision_markers" begin
        @testset "Valid marker file" begin
            markers = read_brainvision_markers(test_vmrk)
            
            @test markers.filename == test_vmrk
            @test markers.n_events == 10
            @test length(markers.markers) == 10
            
            # Test first marker
            first_marker = markers.markers[1]
            @test first_marker.type == "Stimulus"
            @test first_marker.value == "S  1"
            @test first_marker.sample == 500
            @test first_marker.duration == 1
            
            # Test last marker
            last_marker = markers.markers[end]
            @test last_marker.type == "Stimulus"
            @test last_marker.value == "S  1"
            @test last_marker.sample == 9500
            @test last_marker.duration == 1
        end
        
        @testset "File not found" begin
            @test_throws ArgumentError read_brainvision_markers("nonexistent.vmrk")
        end
    end
    
    
    @testset "read_brainvision (complete dataset)" begin
        @testset "Valid complete dataset" begin
            if isfile(test_eeg)
                data = read_brainvision(joinpath(test_data_dir, "test"))
                
                @test isa(data, BrainVisionData)
                @test data.filename == joinpath(test_data_dir, "test")
                @test data.header !== nothing
                @test data.data !== nothing
                @test length(data.markers) == 10
                @test data.header.Fs == 1000.0
                
                # Test header properties
                @test data.header.DataFile == "test.eeg"
                @test data.header.MarkerFile == "test.vmrk"
                @test data.header.NumberOfChannels == 2
                
                # Test EEG data
                @test size(data.data, 2) == 2  # 2 channels
                @test size(data.data, 1) > 0   # Should have samples
                
                # Test markers
                @test length(data.markers) == 10
                @test data.markers[1].type == "Stimulus"
            else
                @warn "Test EEG file not found, skipping complete dataset test"
            end
        end
        
        @testset "Missing files" begin
            @test_throws ArgumentError read_brainvision("nonexistent")
        end
    end
end
