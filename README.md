# BrainVisionDataFormat

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://igmmgi.github.io/BrainVisionDataFormat.jl/)
[![Build Status](https://github.com/igmmgi/BrainVisionDataFormat.jl/workflows/Documentation/badge.svg)](https://github.com/igmmgi/BrainVisionDataFormat.jl/actions)
[![CI](https://github.com/igmmgi/BrainVisionDataFormat.jl/workflows/Tests/badge.svg)](https://github.com/igmmgi/BrainVisionDataFormat.jl/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Julia package for reading BrainVision EEG data files (.vhdr, .vmrk, .eeg format).

## Features

- Read BrainVision files (.vhdr, .vmrk, .eeg) into Julia data structures

## Installation

```julia
] # julia pkg manager
add https://github.com/igmmgi/BrainVisionDataFormat.jl.git # install from GitHub
test BrainVisionDataFormat # optional
```

## File Format

BrainVision files consist of three components:

- **`.vhdr`**: Header file with metadata, channel information, and sampling parameters
- **`.vmrk`**: Marker file with event/trigger information and timestamps
- **`.eeg`**: Binary data file with EEG samples (multiple formats supported)

## Quick Start

```julia
using BrainVisionDataFormat

# Read complete BrainVision dataset
data = read_brainvision("experiment")

# Access EEG data and metadata
eeg_data = data.data  # Matrix{Float64} (samples × channels)
header = data.header      # BrainVisionHeader with all metadata
markers = data.markers    # Vector{BrainVisionMarker} with events

# Read individual components
header = read_brainvision_header("experiment.vhdr")
markers = read_brainvision_markers("experiment.vmrk")
eeg_data = read_brainvision_data("experiment.eeg")
```

## Documentation

- [API Reference](https://igmmgi.github.io/BrainVisionDataFormat.jl/)
