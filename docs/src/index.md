# BrainVisionDataFormat

A Julia package for reading and processing BrainVision EEG data files (.vhdr, .vmrk, .eeg format).

## Overview

BrainVision files are a standard format for EEG data storage, consisting of three interconnected files that store header metadata, event markers, and binary EEG data. This package provides comprehensive functionality to read and work with these files in Julia.

## Features

- **Complete BrainVision Support**: Read all three file types (.vhdr, .vmrk, .eeg)
- **Flexible Data Access**: Read complete datasets or individual components
- **Marker Processing**: Extract and filter event markers and triggers
- **Channel Management**: Access channel information, labels, and metadata
- **Data Validation**: Built-in file consistency checks
- **Utility Functions**: Time conversion, marker filtering, and data analysis tools

## Quick Start

```julia
using BrainVisionDataFormat

# Read complete BrainVision dataset
data = read_brainvision("experiment")

# Access EEG data and metadata
eeg_data = data.data  # Matrix{Float64} (channels × samples)
header = data.header      # BrainVisionHeader with all metadata
markers = data.markers    # Vector{BrainVisionMarker} with events

# Read individual components
header = read_brainvision_header("experiment.vhdr")
markers = read_brainvision_markers("experiment.vmrk")
eeg_data = read_brainvision_data("experiment.eeg")

# Work with markers
stimulus_markers = get_markers_by_type(data, "Stimulus")
early_events = get_markers_in_range(data, 1, 10000)
unique_types = get_unique_types(data)

# Convert samples to time
time_sec = samples_to_time(1000, header.Fs)  # Convert sample 1000 to seconds
```

## Installation

```julia
using Pkg
Pkg.add("BrainVisionDataFormat")
```

## Documentation

- [API Reference](@ref)
