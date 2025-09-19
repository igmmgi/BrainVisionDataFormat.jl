# test_validation.jl - Tests for file validation (adapted from JavaScript tests)

@testset "File Validation" begin
    test_data_dir = joinpath(@__DIR__, "data")
    
    @testset "File extension validation" begin
        @testset "Valid .vhdr extension" begin
            test_vhdr = joinpath(test_data_dir, "test.vhdr")
            @test endswith(test_vhdr, ".vhdr")
        end
        
        @testset "Invalid file extension" begin
            test_vmrk = joinpath(test_data_dir, "test.vmrk")
            @test !endswith(test_vmrk, ".vhdr")
        end
    end
    
    @testset "BrainVision triplet validation" begin
        @testset "Valid triplet" begin
            test_vhdr = joinpath(test_data_dir, "test.vhdr")
            test_vmrk = joinpath(test_data_dir, "test.vmrk")
            test_eeg = joinpath(test_data_dir, "test.eeg")
            
            # Check that all files exist
            @test isfile(test_vhdr)
            @test isfile(test_vmrk)
            @test isfile(test_eeg)
            
            # Read header and check internal links
            header = read_brainvision_header(test_vhdr)
            @test header.DataFile == "test.eeg"
            @test header.MarkerFile == "test.vmrk"
            
            # Check that marker file links to same data file
            markers = read_brainvision_markers(test_vmrk)
            # Note: The marker file doesn't directly contain DataFile info in the format,
            # but we can verify the files are consistent by checking they can be read together
            @test markers.n_events > 0
        end
        
        @testset "File consistency validation" begin
            # Test that the valid files are internally consistent
            test_vhdr = joinpath(test_data_dir, "test.vhdr")
            test_vmrk = joinpath(test_data_dir, "test.vmrk")
            test_eeg = joinpath(test_data_dir, "test.eeg")
            
            if isfile(test_vhdr) && isfile(test_vmrk) && isfile(test_eeg)
                # Read all components
                header = read_brainvision_header(test_vhdr)
                markers = read_brainvision_markers(test_vmrk)
                
                # Verify internal consistency
                @test header.DataFile == "test.eeg"
                @test header.MarkerFile == "test.vmrk"
                @test markers.n_events > 0
                
                # Verify that all marker samples are within reasonable range
                for marker in markers.markers
                    @test marker.sample > 0
                    @test marker.duration >= 0
                end
            end
        end
    end
    
    @testset "File existence validation" begin
        @testset "All required files exist" begin
            test_vhdr = joinpath(test_data_dir, "test.vhdr")
            test_vmrk = joinpath(test_data_dir, "test.vmrk")
            test_eeg = joinpath(test_data_dir, "test.eeg")
            
            if isfile(test_vhdr) && isfile(test_vmrk) && isfile(test_eeg)
                # Should be able to read complete dataset
                data = read_brainvision(joinpath(test_data_dir, "test"))
                @test isa(data, BrainVisionData)
                @test data.header !== nothing
                @test data.data !== nothing
                @test length(data.markers) > 0
            end
        end
        
        @testset "Missing files" begin
            # Test with non-existent base filename
            @test_throws ArgumentError read_brainvision("nonexistent")
        end
    end
    
    @testset "Data consistency validation" begin
        @testset "Header and data consistency" begin
            test_vhdr = joinpath(test_data_dir, "test.vhdr")
            test_eeg = joinpath(test_data_dir, "test.eeg")
            
            if isfile(test_vhdr) && isfile(test_eeg)
                header = read_brainvision_header(test_vhdr)
                data = read_brainvision(joinpath(test_data_dir, "test"))
                
                # Check that data dimensions match header
                @test size(data.data, 1) == header.NumberOfChannels
                @test size(data.data, 2) == header.nSamples
            end
        end
        
        @testset "Marker and data consistency" begin
            test_vhdr = joinpath(test_data_dir, "test.vhdr")
            test_vmrk = joinpath(test_data_dir, "test.vmrk")
            test_eeg = joinpath(test_data_dir, "test.eeg")
            
            if isfile(test_vhdr) && isfile(test_vmrk) && isfile(test_eeg)
                data = read_brainvision(joinpath(test_data_dir, "test"))
                
                # Check that all marker samples are within data range
                for marker in data.markers
                    @test marker.sample >= 1
                    @test marker.sample <= size(data.data, 2)
                end
            end
        end
    end
end
