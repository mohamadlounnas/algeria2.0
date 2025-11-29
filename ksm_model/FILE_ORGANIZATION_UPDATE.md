# File Organization Update

## Changes Made

### Organized Folder Structure
The API server now organizes all generated files into folders, one folder per source image:

**Before:**
```
static/
├── leaf_1_12345.jpg
├── heatmap_1_12345.jpg
├── overlay_1_12345.jpg
├── leaf_2_12346.jpg
├── heatmap_2_12346.jpg
└── overlay_2_12346.jpg
```

**After:**
```
static/
├── image01/
│   ├── leaf1.png
│   ├── heatmap1.png
│   ├── overlay1.png
│   ├── leaf2.png      (if multiple leaves detected)
│   ├── heatmap2.png
│   └── overlay2.png
├── image02/
│   ├── leaf1.png
│   ├── heatmap1.png
│   └── overlay1.png
└── image03/
    └── ...
```

### PNG Format
All generated images are now saved in PNG format instead of JPG:
- `leaf{N}.png` - Individual leaf images
- `heatmap{N}.png` - Anomaly detection heatmaps
- `overlay{N}.png` - Overlay of leaf and heatmap

### Multiple Leaves Handling
When an image contains multiple leaves:
- All leaves from the same source image are stored in the same folder
- Leaves are numbered sequentially: `leaf1.png`, `leaf2.png`, `leaf3.png`, etc.
- Corresponding heatmaps and overlays follow the same numbering

### API Response
The API URLs now reflect the new structure:
```json
{
  "leafs": [
    {
      "image": "http://192.168.1.100:8888/static/image01/leaf1.png",
      "heatmap": "http://192.168.1.100:8888/static/image01/heatmap1.png",
      "overlay": "http://192.168.1.100:8888/static/image01/overlay1.png",
      "diseases": {...}
    }
  ]
}
```

## Benefits

1. **Better Organization**: All files related to one source image are grouped together
2. **Easy Cleanup**: Delete an entire image folder to remove all related files
3. **Standard Format**: PNG format ensures consistent quality and transparency support
4. **Scalability**: Folder-based structure scales better with many images
5. **Clarity**: Clear naming convention (image01, image02, etc.) with numbered leaves

## Compatibility

- The static file handler automatically supports subdirectories
- Existing code doesn't need changes
- URLs are automatically generated with the correct folder structure
