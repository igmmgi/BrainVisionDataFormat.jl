# test_utils.jl - Tests for utility functions

@testset "Utility Functions" begin
    @testset "get_markers_by_type" begin
        markers = [
            BrainVisionMarker("Stimulus", "S 1", 100, 1, nothing),
            BrainVisionMarker("Stimulus", "S 2", 200, 1, nothing),
            BrainVisionMarker("Response", "R 1", 300, 1, nothing),
            BrainVisionMarker("New Segment", "New Segment", 400, 1, nothing)
        ]
        
        # Create data containers for testing
        marker_data = BrainVisionMarkerData("test.vmrk", markers)
        brain_data = BrainVisionData("test", nothing, nothing, markers)
        
        @testset "Filter by type" begin
            stimulus_markers = get_markers_by_type(marker_data, "Stimulus")
            @test length(stimulus_markers) == 2
            @test all(m -> m.type == "Stimulus", stimulus_markers)
            
            response_markers = get_markers_by_type(marker_data, "Response")
            @test length(response_markers) == 1
            @test response_markers[1].value == "R 1"
            
            new_segment_markers = get_markers_by_type(marker_data, "New Segment")
            @test length(new_segment_markers) == 1
            @test new_segment_markers[1].value == "New Segment"
        end
        
        @testset "Non-existent type" begin
            empty_markers = get_markers_by_type(marker_data, "NonExistent")
            @test isempty(empty_markers)
        end
        
        @testset "Empty marker list" begin
            empty_data = BrainVisionMarkerData("empty.vmrk", BrainVisionMarker[])
            empty_markers = get_markers_by_type(empty_data, "Stimulus")
            @test isempty(empty_markers)
        end
        
        @testset "With BrainVisionData" begin
            stimulus_markers = get_markers_by_type(brain_data, "Stimulus")
            @test length(stimulus_markers) == 2
            @test all(m -> m.type == "Stimulus", stimulus_markers)
        end
    end
    
    @testset "get_markers_in_range" begin
        markers = [
            BrainVisionMarker("Stimulus", "S 1", 100, 1, nothing),
            BrainVisionMarker("Stimulus", "S 2", 200, 1, nothing),
            BrainVisionMarker("Response", "R 1", 300, 1, nothing),
            BrainVisionMarker("Stimulus", "S 3", 400, 1, nothing),
            BrainVisionMarker("Response", "R 2", 500, 1, nothing)
        ]
        
        # Create data containers for testing
        marker_data = BrainVisionMarkerData("test.vmrk", markers)
        brain_data = BrainVisionData("test", nothing, nothing, markers)
        
        @testset "Range within markers" begin
            range_markers = get_markers_in_range(marker_data, 150, 350)
            @test length(range_markers) == 2
            @test range_markers[1].sample == 200
            @test range_markers[2].sample == 300
        end
        
        @testset "Range at boundaries" begin
            range_markers = get_markers_in_range(marker_data, 200, 300)
            @test length(range_markers) == 2
            @test range_markers[1].sample == 200
            @test range_markers[2].sample == 300
        end
        
        @testset "Range outside markers" begin
            range_markers = get_markers_in_range(marker_data, 600, 700)
            @test isempty(range_markers)
        end
        
        @testset "Empty marker list" begin
            empty_data = BrainVisionMarkerData("empty.vmrk", BrainVisionMarker[])
            empty_markers = get_markers_in_range(empty_data, 100, 200)
            @test isempty(empty_markers)
        end
        
        @testset "With BrainVisionData" begin
            range_markers = get_markers_in_range(brain_data, 150, 350)
            @test length(range_markers) == 2
            @test range_markers[1].sample == 200
            @test range_markers[2].sample == 300
        end
    end
    
    @testset "samples_to_time" begin
        @testset "Basic conversion" begin
            # 1000 Hz sampling rate
            time = samples_to_time(1000, 1000.0)
            @test time == 1.0
            
            time = samples_to_time(500, 1000.0)
            @test time == 0.5
            
            time = samples_to_time(2000, 1000.0)
            @test time == 2.0
        end
        
        @testset "Different sampling rates" begin
            # 500 Hz sampling rate
            time = samples_to_time(1000, 500.0)
            @test time == 2.0
            
            # 2000 Hz sampling rate
            time = samples_to_time(1000, 2000.0)
            @test time == 0.5
        end
        
        @testset "Zero and negative samples" begin
            time = samples_to_time(0, 1000.0)
            @test time == 0.0
            
            time = samples_to_time(-100, 1000.0)
            @test time == -0.1
        end
        
        @testset "Vector input" begin
            times = samples_to_time([1000, 2000, 3000], 1000.0)
            @test times == [1.0, 2.0, 3.0]
        end
    end
    
    @testset "get_unique_types" begin
        @testset "Multiple types" begin
            markers = [
                BrainVisionMarker("Stimulus", "S 1", 100, 1, nothing),
                BrainVisionMarker("Stimulus", "S 2", 200, 1, nothing),
                BrainVisionMarker("Response", "R 1", 300, 1, nothing),
                BrainVisionMarker("New Segment", "New Segment", 400, 1, nothing),
                BrainVisionMarker("Response", "R 2", 500, 1, nothing)
            ]
            
            # Create data containers for testing
            marker_data = BrainVisionMarkerData("test.vmrk", markers)
            brain_data = BrainVisionData("test", nothing, nothing, markers)
            
            unique_types = get_unique_types(marker_data)
            @test length(unique_types) == 3
            @test "Stimulus" in unique_types
            @test "Response" in unique_types
            @test "New Segment" in unique_types
        end
        
        @testset "Single type" begin
            markers = [
                BrainVisionMarker("Stimulus", "S 1", 100, 1, nothing),
                BrainVisionMarker("Stimulus", "S 2", 200, 1, nothing)
            ]
            
            marker_data = BrainVisionMarkerData("test.vmrk", markers)
            unique_types = get_unique_types(marker_data)
            @test length(unique_types) == 1
            @test unique_types[1] == "Stimulus"
        end
        
        @testset "Empty marker list" begin
            empty_data = BrainVisionMarkerData("empty.vmrk", BrainVisionMarker[])
            unique_types = get_unique_types(empty_data)
            @test isempty(unique_types)
        end
        
        @testset "With BrainVisionData" begin
            markers = [
                BrainVisionMarker("Stimulus", "S 1", 100, 1, nothing),
                BrainVisionMarker("Response", "R 1", 200, 1, nothing)
            ]
            brain_data = BrainVisionData("test", nothing, nothing, markers)
            
            unique_types = get_unique_types(brain_data)
            @test length(unique_types) == 2
            @test "Stimulus" in unique_types
            @test "Response" in unique_types
        end
    end
    
    @testset "Edge cases and error handling" begin
        @testset "Invalid sampling rate" begin
            # The function doesn't validate input, so these will just return Inf or -Inf
            time1 = samples_to_time(100, 0.0)
            @test isinf(time1)
            
            time2 = samples_to_time(100, -100.0)
            @test isinf(time2) || time2 == -1.0  # -100/100 = -1.0
        end
        
        @testset "Large sample numbers" begin
            # Test with very large sample numbers
            time = samples_to_time(1000000, 1000.0)
            @test time == 1000.0
            
            time = samples_to_time(Int64(2^50), 1000.0)
            @test isfinite(time)
        end
        
        @testset "Floating point precision" begin
            # Test with non-integer sample numbers (round to nearest Int)
            time = samples_to_time(round(Int, 1000.5), 1000.0)
            @test time == 1.0  # 1001/1000 = 1.001, but we rounded to 1001
        end
    end
end
