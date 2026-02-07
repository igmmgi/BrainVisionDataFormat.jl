# test_reader.jl - Tests for BrainVision file reading functions

@testset "Reader Functions" begin
    # Test data paths
    test_data_dir = joinpath(@__DIR__, "data")
    test1_vhdr = joinpath(test_data_dir, "test1.vhdr")
    test1_vmrk = joinpath(test_data_dir, "test1.vmrk")
    test1_eeg = joinpath(test_data_dir, "test1.eeg")
    test2_vhdr = joinpath(test_data_dir, "test2.vhdr")
    test2_vmrk = joinpath(test_data_dir, "test2.vmrk")
    test2_eeg = joinpath(test_data_dir, "test2.eeg")

    @testset "read_brainvision_header" begin
        @testset "test1 - IEEE_FLOAT_32, 2 channels" begin
            header = read_brainvision_header(test1_vhdr)

            # Test basic properties
            @test header.DataFile == "test1.eeg"
            @test header.MarkerFile == "test1.vmrk"
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

        @testset "test2 - INT_16, 32 channels" begin
            header = read_brainvision_header(test2_vhdr)

            # Test basic properties
            @test header.DataFile == "test2.eeg"
            @test header.MarkerFile == "test2.vmrk"
            @test header.DataFormat == "BINARY"
            @test header.DataOrientation == "MULTIPLEXED"
            @test header.BinaryFormat == "INT_16"
            @test header.NumberOfChannels == 32
            @test header.SamplingInterval == 1000.0
            @test header.Fs == 1000.0

            # Test channel information
            @test length(header.label) == 32
            @test header.label[1] == "FP1"
            @test header.label[end] == "ReRef"
            @test length(header.resolution) == 32
            @test all(r -> r == 0.5, header.resolution)
        end

        @testset "File not found" begin
            @test_throws ArgumentError read_brainvision_header("nonexistent.vhdr")
        end
    end

    @testset "read_brainvision_markers" begin
        @testset "test1 - 10 stimulus markers" begin
            markers = read_brainvision_markers(test1_vmrk)

            @test markers.filename == test1_vmrk
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

        @testset "test2 - 14 mixed marker types" begin
            markers = read_brainvision_markers(test2_vmrk)

            @test markers.filename == test2_vmrk
            @test markers.n_events == 14
            @test length(markers.markers) == 14

            # Test first marker (New Segment)
            first_marker = markers.markers[1]
            @test first_marker.type == "New Segment"
            @test first_marker.sample == 1

            # Test last marker (Optic)
            last_marker = markers.markers[end]
            @test last_marker.type == "Optic"
            @test last_marker.value == "O  1"
            @test last_marker.sample == 7700

            # Test diverse marker types are present
            types = [m.type for m in markers.markers]
            @test "New Segment" in types
            @test "Stimulus" in types
            @test "Event" in types
            @test "Response" in types
            @test "SyncStatus" in types
            @test "Optic" in types
        end

        @testset "File not found" begin
            @test_throws ArgumentError read_brainvision_markers("nonexistent.vmrk")
        end
    end

    @testset "read_brainvision (complete dataset)" begin
        @testset "test1 - 2 channel float dataset" begin
            if isfile(test1_eeg)
                data = read_brainvision(joinpath(test_data_dir, "test1"))

                @test isa(data, BrainVisionData)
                @test data.filename == joinpath(test_data_dir, "test1")
                @test data.header !== nothing
                @test data.data !== nothing
                @test length(data.markers) == 10
                @test data.header.Fs == 1000.0

                # Test header properties
                @test data.header.DataFile == "test1.eeg"
                @test data.header.MarkerFile == "test1.vmrk"
                @test data.header.NumberOfChannels == 2

                # Test EEG data
                @test size(data.data, 2) == 2  # 2 channels
                @test size(data.data, 1) > 0   # Should have samples

                # Test markers
                @test length(data.markers) == 10
                @test data.markers[1].type == "Stimulus"
            else
                @warn "test1.eeg not found, skipping test1 complete dataset test"
            end
        end

        @testset "test2 - 32 channel INT_16 dataset" begin
            if isfile(test2_eeg)
                data = read_brainvision(joinpath(test_data_dir, "test2"))

                @test isa(data, BrainVisionData)
                @test data.filename == joinpath(test_data_dir, "test2")
                @test data.header !== nothing
                @test data.data !== nothing

                # Test data dimensions (7900 samples × 32 channels)
                @test size(data.data) == (7900, 32)

                # Test header properties
                @test data.header.DataFile == "test2.eeg"
                @test data.header.MarkerFile == "test2.vmrk"
                @test data.header.NumberOfChannels == 32
                @test data.header.BinaryFormat == "INT_16"
                @test data.header.Fs == 1000.0

                # Test markers
                @test length(data.markers) == 14
                @test data.markers[1].type == "New Segment"
                @test data.markers[1].sample == 1
            else
                @warn "test2.eeg not found, skipping test2 complete dataset test"
            end
        end

        @testset "Missing files" begin
            @test_throws ArgumentError read_brainvision("nonexistent")
        end
    end
end
