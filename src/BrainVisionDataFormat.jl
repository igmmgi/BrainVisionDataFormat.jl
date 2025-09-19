"""
    BrainVisionDataFormat

Julia package for reading BrainVision EEG data files (.vhdr, .vmrk, .eeg format).

This package provides functionality to:
- Read BrainVision files (.vhdr, .vmrk, .eeg) into Julia data structures

# File Format
BrainVision files consist of three components:
- `.vhdr`: Header file with metadata and channel information
- `.vmrk`: Marker file with event/trigger information  
- `.eeg`: Binary data file with EEG samples

# Quick Start
```julia
using BrainVisionDataFormat

# Read complete BrainVision dataset
data = read_brainvision("experiment")

# Read only markers
markers = read_brainvision_markers("experiment.vmrk")

# Read only header
header = read_brainvision_header("experiment.vhdr")
```
"""
module BrainVisionDataFormat

# Include organized module files
include("types.jl")
include("reader.jl")
include("utils.jl")

export
  # Main reading functions
  read_brainvision,
  read_brainvision_header,
  read_brainvision_markers,
  # Data types
  BrainVisionData,
  BrainVisionHeader,
  BrainVisionMarker,
  BrainVisionMarkerData,
  # Utility functions
  get_markers_by_type,
  get_markers_in_range,
  samples_to_time,
  get_unique_types

end # module