# API Reference

## Module

```@docs
BrainVisionDataFormat
```

## Data Structures

```@docs
BrainVisionDataFormat.BrainVisionHeader
BrainVisionDataFormat.BrainVisionMarker
BrainVisionDataFormat.BrainVisionData
BrainVisionDataFormat.BrainVisionMarkerData
```

## File Reading Functions

### Complete Dataset Reading

```@docs
BrainVisionDataFormat.read_brainvision
```

### Individual Component Reading

```@docs
BrainVisionDataFormat.read_brainvision_header
BrainVisionDataFormat.read_brainvision_markers
BrainVisionDataFormat.read_brainvision_data
```

## Utility Functions

### Marker Processing

```@docs
BrainVisionDataFormat.get_markers_by_type
BrainVisionDataFormat.get_markers_in_range
BrainVisionDataFormat.get_unique_types
```

### Time Conversion

```@docs
BrainVisionDataFormat.samples_to_time
```
