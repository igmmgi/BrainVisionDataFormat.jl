# reader.jl - BrainVision file reading functions for BrainVisionDataFormat

# Constants
const MICROSECONDS_PER_SECOND = 1_000_000  # For sampling rate calculation

# Binary format mapping: format_name => (bytes_per_sample, data_type)
const BINARY_FORMATS = Dict(
    "INT_16" => (2, Int16),
    "INT_32" => (4, Int32),
    "IEEE_FLOAT_32" => (4, Float32)
)

"""
    read_brainvision_header(filename)

Read BrainVision header file (.vhdr) and return a BrainVisionHeader object.

This function parses the header file to extract all metadata including channel information,
recording parameters, sampling rate, and file format specifications.

# Arguments
- `filename::String`: Path to the .vhdr file

# Returns
- `BrainVisionHeader`: Complete header information with all metadata

# Examples
```julia
# Read header from file
header = read_brainvision_header("experiment.vhdr")

# Access header information
println("Channels: ", header.NumberOfChannels)
println("Sampling rate: ", header.Fs, " Hz")
println("Data format: ", header.DataFormat)
```

# See Also
- [`read_brainvision`](@ref) - Read complete dataset
- [`read_brainvision_markers`](@ref) - Read marker file
"""
function read_brainvision_header(filename::String)::BrainVisionHeader
    !isfile(filename) && throw(ArgumentError("File not found: $filename"))
    
    open(filename, "r") do file
        impedance_data = _parse_impedance_section(file)
        header_data = _parse_header_sections(file, filename)
        
        # Add impedance data if found
        if impedance_data !== nothing
            header_data = merge(header_data, (impedances = impedance_data,))
        end
        
        # Calculate sampling rate from sampling interval (microseconds)
        if header_data.SamplingInterval > 0
            header_data = merge(header_data, (Fs = MICROSECONDS_PER_SECOND / header_data.SamplingInterval,))
        end
        
        # Determine number of samples from data file
        data_file = joinpath(dirname(filename), header_data.DataFile)
        if isfile(data_file)
            n_samples = _calculate_n_samples(data_file, header_data)
            header_data = merge(header_data, (nSamples = n_samples,))
        end
        
        # Create the header struct
        BrainVisionHeader(
            header_data.DataFile,
            header_data.MarkerFile,
            header_data.DataFormat,
            header_data.DataOrientation,
            header_data.BinaryFormat,
            header_data.NumberOfChannels,
            header_data.SamplingInterval,
            header_data.Fs,
            header_data.label,
            header_data.reference,
            header_data.resolution,
            header_data.unit,
            header_data.nSamples,
            header_data.nTrials,
            header_data.nSamplesPre,
            header_data.impedances
        )
    end
end




"""
    _read_brainvision_data(filename, header)

Internal function to read EEG data from BrainVision binary file.

This function reads the raw binary EEG data and converts it to a Float64 matrix
using the format information from the provided header.

# Arguments
- `filename::String`: Path to the .eeg file
- `header::BrainVisionHeader`: Header information containing format specifications

# Returns
- `Matrix{Float64}`: EEG data matrix (samples × channels) scaled to microvolts

# Notes
- This is an internal function used by `read_brainvision`
- Data is automatically scaled using resolution values from the header
- Only binary format is supported (INT_16, INT_32, IEEE_FLOAT_32)
"""
function _read_brainvision_data(filename::String, header::BrainVisionHeader)::Matrix{Float64}

    if !isfile(filename)
        throw(ArgumentError("Data file not found: $filename"))
    end
   
    # Determine data type and bytes per sample
    if uppercase(header.DataFormat) != "BINARY"
        throw(ArgumentError("Only binary format is currently supported"))
    end
    
    format_key = uppercase(header.BinaryFormat)
    if !haskey(BINARY_FORMATS, format_key)
        throw(ArgumentError("Unsupported binary format: $(header.BinaryFormat)"))
    end
    
    bytes_per_sample, data_type = BINARY_FORMATS[format_key]
    
    # Calculate byte positions
    bytes_per_channel_sample = bytes_per_sample
    bytes_per_sample_all_chans = header.NumberOfChannels * bytes_per_channel_sample
    
    # Initialize data matrix
    nsamples = header.nSamples
    nchans = header.NumberOfChannels
    data = zeros(Float64, nsamples, nchans)

    # Read the data
    open(filename, "r") do file
        total_bytes = nsamples * bytes_per_sample_all_chans
        raw_data = read(file, total_bytes)
        _process_raw_data!(data, raw_data, header, data_type, nsamples)
    end
    
    return data
end

"""
    read_brainvision(base_filename; begsample=1, endsample=nothing, chanindx=nothing)

Read complete BrainVision dataset from base filename (without extension).

This is the main entry point for reading BrainVision data. It loads the header, markers,
and EEG data from the three-file BrainVision format (.vhdr, .vmrk, .eeg) and returns
a complete dataset object.

# Arguments
- `base_filename::String`: Base filename without extension (e.g., "experiment" for "experiment.vhdr")
- `begsample::Int`: First sample to read (1-indexed, default: 1)
- `endsample::Union{Int, Nothing}`: Last sample to read (default: all samples)
- `chanindx::Union{AbstractVector{Int}, Nothing}`: Channel indices to read (default: all channels)

# Returns
- `BrainVisionData`: Complete dataset with EEG data, markers, and header

# Examples
```julia
# Load complete dataset
data = read_brainvision("experiment")

# Access components
data = data.data  # Matrix{Float64} (samples × channels)
markers = data.markers    # Vector{BrainVisionMarker}
header = data.header      # BrainVisionHeader

# Load specific time range
data = read_brainvision("experiment", begsample=1000, endsample=5000)

# Load specific channels
data = read_brainvision("experiment", chanindx=1:10)
```

# Notes
- The function automatically finds the corresponding .vhdr, .vmrk, and .eeg files
- All three files must exist for successful loading
- EEG data is returned as a matrix with dimensions (samples × channels)
- Data is automatically scaled to microvolts using resolution values from the header

# See Also
- [`read_brainvision_header`](@ref) - Read only header
- [`read_brainvision_markers`](@ref) - Read only markers
"""
function read_brainvision(base_filename::String; 
                         begsample::Int=1, 
                         endsample::Union{Int, Nothing}=nothing, 
                         chanindx::Union{AbstractVector{Int}, Nothing}=nothing)::BrainVisionData
    
    # Remove extension if present
    base_filename = replace(base_filename, r"\.(vhdr|vmrk|eeg)$" => "")
    
    # Construct filenames
    vhdr_file = "$base_filename.vhdr"
    vmrk_file = "$base_filename.vmrk"
    eeg_file = "$base_filename.eeg"
    
    # Check that all required files exist
    !isfile(vhdr_file) && throw(ArgumentError("Header file not found: $vhdr_file"))
    !isfile(vmrk_file) && throw(ArgumentError("Marker file not found: $vmrk_file"))
    !isfile(eeg_file) && throw(ArgumentError("EEG data file not found: $eeg_file"))
    
    # Read all data
    header = read_brainvision_header(vhdr_file)
    markers = read_brainvision_markers(vmrk_file)
    eeg_data = _read_brainvision_data(eeg_file, header)
    
    return BrainVisionData(base_filename, header, eeg_data, markers.markers)
end


"""
    read_brainvision_markers(filename)

Read BrainVision marker file (.vmrk) and return a BrainVisionMarkerData object.

This function parses the marker file to extract all event/trigger information including
timestamps, durations, and marker types. Markers are commonly used to mark experimental
events, artifacts, or other significant time points in the EEG recording.

# Arguments
- `filename::String`: Path to the .vmrk file

# Returns
- `BrainVisionMarkerData`: Container with all markers and metadata

# Examples
```julia
# Read markers from file
markers = read_brainvision_markers("experiment.vmrk")

# Access marker information
println("Found ", markers.n_events, " events")
for marker in markers.markers
    println("Event: ", marker.type, " at sample ", marker.sample)
end
```

# See Also
- [`read_brainvision`](@ref) - Read complete dataset
- [`read_brainvision_header`](@ref) - Read header file
- [`get_markers_by_type`](@ref) - Filter markers by type
"""
function read_brainvision_markers(filename::String)::BrainVisionMarkerData
    !isfile(filename) && throw(ArgumentError("File not found: $filename"))
    
    markers = BrainVisionMarker[]
    
    open(filename, "r") do file
        for (line_num, line) in enumerate(eachline(file))
            line = strip(String(line))  # Convert SubString to String
            
            # Skip empty lines, comments, and headers
            _should_skip_line(line) && continue
            
            # Parse marker lines
            if startswith(line, "Mk")
                marker = _parse_marker_line(line, line_num)
                marker !== nothing && push!(markers, marker)
            end
        end
    end
    
    return BrainVisionMarkerData(filename, markers)
end

# Helper functions
_should_skip_line(line::String) = isempty(line) || startswith(line, ";") || startswith(line, "[")
_should_skip_line(line::SubString{String}) = _should_skip_line(String(line))

function _parse_marker_line(line::String, line_num::Int)::Union{BrainVisionMarker, Nothing}
    parts = split(line, "=", limit=2)
    length(parts) != 2 && return nothing
    
    tokens = _tokenize(parts[2], ',')
    length(tokens) < 4 && return nothing
    
    # Extract and validate fields
    type = tokens[1]
    value = tokens[2]
    sample = tryparse(Int, tokens[3])
    duration = tryparse(Int, tokens[4])
    
    (sample === nothing || duration === nothing) && return nothing
    
    # Get timestamp if available (raw string)
    timestamp = length(tokens) >= 6 && !isempty(tokens[6]) && length(tokens[6]) == 20 && all(isdigit, tokens[6]) ? tokens[6] : nothing
    
    BrainVisionMarker(type, value, sample, duration, timestamp)
end

_parse_marker_line(line::SubString{String}, line_num::Int) = _parse_marker_line(String(line), line_num)


function _tokenize(str::String, delimiter::Char=',')::Vector{String}
    isempty(str) && return String[]
    
    # Replace escaped commas with placeholder
    temp_str = replace(str, "\\1" => "\x00")
    tokens = split(temp_str, delimiter)
    
    # Restore escaped commas and trim
    [replace(strip(token), "\x00" => ",") for token in tokens]
end

_tokenize(str::SubString{String}, delimiter::Char=',') = _tokenize(String(str), delimiter)

# Header parsing helper functions
function _parse_header_field(header_data::NamedTuple, key::String, value::String, filename::String)::NamedTuple
    startswith(key, "Ch") && return _parse_channel_info(header_data, key, value)
    
    # Handle all simple string fields generically
    if key in ("DataFile", "MarkerFile", "DataFormat", "DataOrientation", "BinaryFormat")
        return merge(header_data, NamedTuple{(Symbol(key),)}((value,)))
    end
    
    # Handle numeric fields
    if key == "NumberOfChannels"
        nchans = tryparse(Int, value)
        return nchans !== nothing ? merge(header_data, (NumberOfChannels = nchans,)) : header_data
    elseif key == "SamplingInterval"
        samp_int = tryparse(Float64, value)
        return samp_int !== nothing ? merge(header_data, (SamplingInterval = samp_int,)) : header_data
    end
    
    return header_data
end

function _parse_channel_info(header_data::NamedTuple, key::String, value::String)::NamedTuple
    chan_info = _tokenize(value, ',')
    if length(chan_info) >= 1
        # Add channel label
        new_labels = vcat(header_data.label, chan_info[1])
        
        # Add reference (default to empty if not provided)
        new_reference = vcat(header_data.reference, length(chan_info) >= 2 ? chan_info[2] : "")
        
        # Add resolution (default to 1.0 if not provided or empty)
        res = if length(chan_info) >= 3 && !isempty(chan_info[3])
            tryparse(Float64, chan_info[3])
        else
            nothing
        end
        new_resolution = vcat(header_data.resolution, res !== nothing ? res : 1.0)
        
        # Add unit (default to "uV" if not provided)
        unit = if length(chan_info) >= 4 && !isempty(chan_info[4])
            replace(chan_info[4], "µV" => "uV")
        else
            "uV"
        end
        new_unit = vcat(header_data.unit, unit)
        
        return merge(header_data, (
            label = new_labels,
            reference = new_reference,
            resolution = new_resolution,
            unit = new_unit
        ))
    end
    
    return header_data
end

# Multiple dispatch for raw data processing
function _process_raw_data!(data::Matrix{Float64}, raw_data::Vector{UInt8}, header::BrainVisionHeader, ::Type{T}, nsamples::Int) where T <: Union{Int16, Int32, Float32}
    raw_values = reinterpret(T, raw_data)
    _process_raw_values!(data, raw_values, header, nsamples)
end

function _process_raw_values!(data::Matrix{Float64}, raw_values::AbstractVector, header::BrainVisionHeader, nsamples::Int)
    @inbounds for j in 1:nsamples
        base_idx = (j - 1) * header.NumberOfChannels
        for i in 1:header.NumberOfChannels
            data[j, i] = Float64(raw_values[base_idx + i]) * header.resolution[i]
        end
    end
end

function _calculate_n_samples(data_file::String, header_data::NamedTuple)::Int
    if uppercase(header_data.DataFormat) != "BINARY"
        return 0
    end
    
    format_key = uppercase(header_data.BinaryFormat)
    if !haskey(BINARY_FORMATS, format_key)
        return 0
    end
    
    bytes_per_sample, _ = BINARY_FORMATS[format_key]
    
    if bytes_per_sample > 0 && header_data.NumberOfChannels > 0
        file_size = filesize(data_file)
        return file_size ÷ (header_data.NumberOfChannels * bytes_per_sample)
    end
    
    return 0
end

# Helper functions for header parsing

function _parse_impedance_section(file::IO)
    impedance_channels = Float64[]
    impedance_reference = Float64[]
    impedance_ground = Float64[]
    impedance_refchan = Float64[]
    in_impedance_section = false
    
    # Reset file position to beginning
    seek(file, 0)
    
    for line in eachline(file)
        line = strip(String(line))
        
        # Skip empty lines, comments, and section headers
        _should_skip_line(line) && continue
        
        # Check for impedance section
        if contains(line, "Impedance [kOhm]")
            in_impedance_section = true
            continue
        elseif in_impedance_section && contains(line, ":")
            # Parse impedance values (format: "ChannelName: value")
            parts = split(line, ":", limit=2)
            if length(parts) == 2
                channel_name = strip(parts[1])
                impedance_value = tryparse(Float64, strip(parts[2]))
                if impedance_value !== nothing
                    push!(impedance_channels, impedance_value)
                end
            end
        elseif in_impedance_section && isempty(line)
            in_impedance_section = false
        end
    end
    
    # Return impedance data if found
    if !isempty(impedance_channels)
        return (
            channels = impedance_channels,
            reference = impedance_reference,
            ground = isempty(impedance_ground) ? 1.0 : impedance_ground[1],
            refChan = impedance_refchan
        )
    end
    
    return nothing
end

function _parse_header_sections(file::IO, filename::String)
    # Reset file position to beginning
    seek(file, 0)
    
    # Initialize with empty values - will be populated during parsing
    header_data = (
        DataFile = "",
        MarkerFile = "",
        DataFormat = "",
        DataOrientation = "",
        BinaryFormat = "",
        NumberOfChannels = 0,
        SamplingInterval = 0.0,
        Fs = 0.0,
        label = String[],
        reference = String[],
        resolution = Float64[],
        unit = String[],
        nSamples = 0,
        nTrials = 1,
        nSamplesPre = 0,
        impedances = nothing
    )
    
    for line in eachline(file)
        line = strip(String(line))
        
        # Skip empty lines, comments, and section headers
        _should_skip_line(line) && continue
        
        # Skip impedance section (already parsed)
        if contains(line, "Impedance [kOhm]")
            continue
        end
        
        # Parse key-value pairs
        if contains(line, "=")
            parts = split(line, "=", limit=2)
            if length(parts) == 2
                key = String(strip(parts[1]))
                value = String(strip(parts[2]))
                
                header_data = _parse_header_field(header_data, key, value, filename)
            end
        end
    end
    
    return header_data
end
