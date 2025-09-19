"""
    get_markers_by_type(data, type)

Get all markers of a specific type.

# Arguments
- `data::Union{BrainVisionData, BrainVisionMarkerData}`: BrainVision data container
- `type::String`: Marker type to filter by (e.g., "Stimulus", "Response")

# Returns
- `Vector{BrainVisionMarker}`: Filtered markers of the specified type

# Example
```julia
stimuli = get_markers_by_type(data, "Stimulus")
println("Found \$(length(stimuli)) stimulus events")
```
"""
get_markers_by_type(data::BrainVisionData, type::String) = filter(m -> m.type == type, data.markers)
get_markers_by_type(data::BrainVisionMarkerData, type::String) = filter(m -> m.type == type, data.markers)

"""
    get_markers_in_range(data, start_sample, end_sample)

Get all markers within a sample range.

# Arguments
- `data::Union{BrainVisionData, BrainVisionMarkerData}`: BrainVision data container
- `start_sample::Int`: First sample number (inclusive)
- `end_sample::Int`: Last sample number (inclusive)

# Returns
- `Vector{BrainVisionMarker}`: Markers within the specified sample range

# Example
```julia
early_events = get_markers_in_range(data, 1, 100000)
println("Found \$(length(early_events)) events in first 100k samples")
```
"""
get_markers_in_range(data::BrainVisionData, start_sample::Int, end_sample::Int) = filter(m -> start_sample <= m.sample <= end_sample, data.markers)
get_markers_in_range(data::BrainVisionMarkerData, start_sample::Int, end_sample::Int) = filter(m -> start_sample <= m.sample <= end_sample, data.markers)

"""
    samples_to_time(samples, sampling_rate)

Convert sample numbers to time in seconds.

# Arguments
- `samples::Union{Int, Vector{Int}}`: Sample number(s) to convert
- `sampling_rate::Float64`: Sampling rate in Hz

# Returns
- `Union{Float64, Vector{Float64}}`: Time in seconds

# Example
```julia
time_sec = samples_to_time(1000, 500.0)  # 2.0 seconds
times = samples_to_time([1000, 2000, 3000], 500.0)  # [2.0, 4.0, 6.0] seconds
```
"""
samples_to_time(samples::Int, sampling_rate::Float64) = samples / sampling_rate
samples_to_time(samples::Vector{Int}, sampling_rate::Float64) = samples ./ sampling_rate

"""
    get_unique_types(data)

Get all unique marker types in the data.

# Arguments
- `data::Union{BrainVisionData, BrainVisionMarkerData}`: BrainVision data container

# Returns
- `Vector{String}`: Unique marker types found in the data

# Example
```julia
types = get_unique_types(data)
println("Found types: \$types")
```
"""
get_unique_types(data::BrainVisionData) = unique([m.type for m in data.markers])
get_unique_types(data::BrainVisionMarkerData) = unique([m.type for m in data.markers])

