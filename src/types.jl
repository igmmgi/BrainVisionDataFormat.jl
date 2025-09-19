# types.jl - Type definitions and constants for BrainVisionDataFormat

"""
    BrainVisionMarker

Represents a single marker event from a BrainVision .vmrk file.

# Fields
- `type::String`: Event type (e.g., "Stimulus", "Response", "New Segment")
- `value::String`: Event value/description
- `sample::Int`: Sample number (position in data points)
- `duration::Int`: Duration in data points
- `timestamp::Union{String, Nothing}`: Timestamp if available (raw string format)

# Example
```julia
marker = BrainVisionMarker("Stimulus", "S 11", 209263, 1, nothing)
println("Type: \$(marker.type), Sample: \$(marker.sample)")
```
"""
struct BrainVisionMarker
    type::String
    value::String
    sample::Int
    duration::Int
    timestamp::Union{String, Nothing}
end

"""
    BrainVisionHeader

Represents header information from a BrainVision .vhdr file.

# Fields
- `DataFile::String`: Name of the EEG data file
- `MarkerFile::String`: Name of the marker file
- `DataFormat::String`: Data format (e.g., "BINARY")
- `DataOrientation::String`: Data orientation (e.g., "MULTIPLEXED")
- `BinaryFormat::String`: Binary format specification
- `NumberOfChannels::Int`: Number of channels
- `SamplingInterval::Float64`: Sampling interval in microseconds
- `Fs::Float64`: Sampling rate in Hz
- `label::Vector{String}`: Channel labels
- `reference::Vector{String}`: Reference information
- `resolution::Vector{Float64}`: Resolution values
- `unit::Vector{String}`: Unit information
- `nSamples::Int`: Number of samples
- `nTrials::Int`: Number of trials
- `nSamplesPre::Int`: Number of pre-stimulus samples
- `impedances::Union{NamedTuple, Nothing}`: Impedance information if available

# Example
```julia
header = read_brainvision_header("experiment.vhdr")
println("Sampling rate: \$(header.Fs) Hz")
println("Number of channels: \$(header.NumberOfChannels)")
```
"""
struct BrainVisionHeader
    DataFile::String
    MarkerFile::String
    DataFormat::String
    DataOrientation::String
    BinaryFormat::String
    NumberOfChannels::Int
    SamplingInterval::Float64
    Fs::Float64
    label::Vector{String}
    reference::Vector{String}
    resolution::Vector{Float64}
    unit::Vector{String}
    nSamples::Int
    nTrials::Int
    nSamplesPre::Int
    impedances::Union{NamedTuple, Nothing}
end

"""
    BrainVisionData

Container for complete BrainVision data including EEG data, markers, and header metadata.

# Fields
- `data::Union{Matrix{Float64}, Nothing}`: EEG data matrix (channels × samples)
- `markers::Vector{BrainVisionMarker}`: Array of marker events
- `header::Union{BrainVisionHeader, Nothing}`: Header information
- `filename::String`: Source filename

# Example
```julia
data = read_brainvision_complete("experiment.vhdr")
println("EEG data shape: \$(size(data.data))")
println("Found \$(length(data.markers)) events")
```
"""
struct BrainVisionData
    filename::String
    header::Union{BrainVisionHeader, Nothing}
    data::Union{Matrix{Float64}, Nothing}
    markers::Vector{BrainVisionMarker}
    
    function BrainVisionData(filename::String,
                           header::Union{BrainVisionHeader, Nothing},
                           data::Union{Matrix{Float64}, Nothing}, 
                           markers::Vector{BrainVisionMarker})
        new(filename, header, data, markers)
    end
end

"""
    BrainVisionMarkerData

Legacy container for BrainVision data with only markers and metadata.

# Fields
- `markers::Vector{BrainVisionMarker}`: Array of marker events
- `filename::String`: Source filename
- `n_events::Int`: Number of events
- `sampling_rate::Union{Float64, Nothing}`: Sampling rate if available

# Example
```julia
data = read_brainvision("experiment.vmrk")
println("Found \$(length(data.markers)) events")
```
"""
struct BrainVisionMarkerData
    filename::String
    n_events::Int
    markers::Vector{BrainVisionMarker}
    
    function BrainVisionMarkerData(filename::String, markers::Vector{BrainVisionMarker})
        new(filename, length(markers), markers)
    end
end

# Custom show methods for better display
function Base.show(io::IO, header::BrainVisionHeader)
    println(io, "BrainVisionHeader")
    println(io, "  DataFile: $(header.DataFile)")
    println(io, "  MarkerFile: $(header.MarkerFile)")
    println(io, "  DataFormat: $(header.DataFormat)")
    println(io, "  DataOrientation: $(header.DataOrientation)")
    println(io, "  BinaryFormat: $(header.BinaryFormat)")
    println(io, "  NumberOfChannels: $(header.NumberOfChannels)")
    println(io, "  SamplingInterval: $(header.SamplingInterval) μs")
    println(io, "  Fs: $(header.Fs) Hz")
    println(io, "  nSamples: $(header.nSamples)")
    println(io, "  nTrials: $(header.nTrials)")
    println(io, "  nSamplesPre: $(header.nSamplesPre)")
    if isempty(header.label)
        println(io, "  Channels: [No channel information found]")
    else
        println(io, "  Channels: $(header.label[1:min(5, length(header.label))])...")
    end
    if header.impedances === nothing
        println(io, "  Impedances: [No impedance data available]")
    else
        println(io, "  Impedances: $(length(header.impedances.channels)) channels, ground=$(header.impedances.ground) kOhm")
    end
end

function Base.show(io::IO, data::BrainVisionData)
    println(io, "BrainVisionData from $(data.filename)")
    if data.data !== nothing
        println(io, "  EEG data: $(size(data.data))")
    else
        println(io, "  EEG data: not loaded (use load_eeg=true or check if .eeg file exists)")
    end
    println(io, "  Events: $(length(data.markers))")
    if data.header !== nothing
        println(io, "  Channels: $(data.header.NumberOfChannels)")
        println(io, "  Sampling rate: $(data.header.Fs) Hz")
    end
    if !isempty(data.markers)
        println(io, "  First event: $(data.markers[1].type) at sample $(data.markers[1].sample)")
    end
end

function Base.show(io::IO, data::BrainVisionMarkerData)
    println(io, "BrainVisionMarkerData from $(data.filename)")
    println(io, "  Events: $(data.n_events)")
    if !isempty(data.markers)
        println(io, "  Markers:")
        n_markers = length(data.markers)
        
        # Show first 5 markers
        for i in 1:min(5, n_markers)
            print(io, "    $i. ")
            show(io, data.markers[i])
            println(io)
        end
        
        # Show ellipsis if there are more than 10 markers
        if n_markers > 10
            println(io, "    ...")
        end
        
        # Show last 5 markers (if more than 5 total)
        if n_markers > 5
            start_idx = max(6, n_markers - 4)
            for i in start_idx:n_markers
                print(io, "    $i. ")
                show(io, data.markers[i])
                println(io)
            end
        end
    end
end

# Custom show method for markers
function Base.show(io::IO, marker::BrainVisionMarker)
    timestamp_str = marker.timestamp === nothing ? "no timestamp" : marker.timestamp
    print(io, "BrainVisionMarker($(marker.type), $(marker.value), sample=$(marker.sample), $(timestamp_str))")
end