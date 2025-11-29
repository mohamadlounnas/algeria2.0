# Disease Detection API - Enhanced JSON Response

## Overview
The API server now returns detailed disease information in the JSON response, including:
- **Disease Names** - Specific disease identified
- **Confidence Scores** - Detection confidence (0.0 to 1.0)
- **Coverage Percentage** - Percentage of leaf affected
- **Disease Description** - Visual characteristics
- **Severity Level** - Disease severity (none, low, medium, high)
- **Treatment Recommendations** - Suggested treatments and prevention

## Files Added/Modified

### New Files:
1. **disease_characteristics.py** - Disease database with 11 diseases
   - Contains detailed information about each disease
   - Includes color ranges, shape characteristics, descriptions, and treatments
   - Helper functions to retrieve disease information

2. **test_disease_response.py** - Test script to verify JSON response format

### Modified Files:
1. **api_server.py** - Enhanced to return detailed disease information
   - Imports disease characteristics database
   - Returns structured disease objects instead of simple confidence values

## Supported Diseases

The system can detect 11 different grape leaf conditions:

1. **Black Rot** - High severity
2. **Esca (Black Measles)** - High severity  
3. **Leaf Blight (Isariopsis Leaf Spot)** - Medium severity
4. **Anthracnose** - High severity
5. **Septoria Leaf Spot** - Medium severity
6. **Bacterial Leaf Spot** - Medium severity
7. **Bacterial Spot** - Medium severity
8. **Rust** - Medium severity
9. **Downy Mildew** - High severity
10. **Powdery Mildew** - High severity
11. **Healthy Tissue** - No severity

## JSON Response Format

### Single Image Request
```
GET http://localhost:8888/api/process?url=<image_url>
```

### Response Structure:
```json
{
  "leafs": [
    {
      "image": "http://192.168.1.100:8888/static/leaf_1.jpg",
      "heatmap": "http://192.168.1.100:8888/static/heatmap_1.jpg",
      "overlay": "http://192.168.1.100:8888/static/overlay_1.jpg",
      "diseases": {
        "Black Rot": {
          "confidence": 0.87,
          "percentage": 15.3,
          "description": "Very dark brown to black circular lesions with concentric rings",
          "severity": "high",
          "treatment": "Apply fungicides containing mancozeb or captan. Remove infected leaves and improve air circulation."
        },
        "Anthracnose": {
          "confidence": 0.72,
          "percentage": 8.5,
          "description": "Circular brown lesions with darker margins",
          "severity": "high",
          "treatment": "Apply chlorothalonil or mancozeb. Remove infected plant debris and ensure good drainage."
        }
      },
      "anomaly_score": 0.85,
      "is_diseased": true
    }
  ],
  "summary": {
    "total_leafs": 1,
    "diseased_leafs": 1,
    "healthy_leafs": 0
  },
  "timestamp": "2025-11-29T12:34:56.789",
  "image_processed": true
}
```

### Bulk Request (Multiple Images)
```
GET http://localhost:8888/api/process?urls=<url1>,<url2>,<url3>
```

Returns an array of results (one per image).

## Disease Information Fields

Each detected disease includes:

| Field | Type | Description |
|-------|------|-------------|
| `confidence` | float | Detection confidence (0.0 - 1.0) |
| `percentage` | float | Percentage of leaf covered by disease |
| `description` | string | Visual characteristics of the disease |
| `severity` | string | Severity level: none, low, medium, high |
| `treatment` | string | Recommended treatment and prevention measures |

## Usage Examples

### Python Example:
```python
import requests
import json

# Single image
url = "http://localhost:8888/api/process?url=file:///C:/path/to/image.jpg"
response = requests.get(url)
data = response.json()

# Access disease information
for leaf in data['leafs']:
    print(f"Leaf is {'diseased' if leaf['is_diseased'] else 'healthy'}")
    
    for disease_name, disease_info in leaf['diseases'].items():
        print(f"\n{disease_name}:")
        print(f"  Confidence: {disease_info['confidence']:.1%}")
        print(f"  Coverage: {disease_info['percentage']:.1f}%")
        print(f"  Severity: {disease_info['severity']}")
        print(f"  Treatment: {disease_info['treatment']}")
```

### JavaScript Example:
```javascript
fetch('http://localhost:8888/api/process?url=file:///C:/path/to/image.jpg')
  .then(response => response.json())
  .then(data => {
    data.leafs.forEach(leaf => {
      console.log(`Leaf is ${leaf.is_diseased ? 'diseased' : 'healthy'}`);
      
      Object.entries(leaf.diseases).forEach(([name, info]) => {
        console.log(`\n${name}:`);
        console.log(`  Confidence: ${(info.confidence * 100).toFixed(1)}%`);
        console.log(`  Coverage: ${info.percentage.toFixed(1)}%`);
        console.log(`  Severity: ${info.severity}`);
        console.log(`  Treatment: ${info.treatment}`);
      });
    });
  });
```

## Testing

Run the test script to verify the response format:
```bash
cd ksm
python test_disease_response.py
```

This will display:
- JSON structure validation
- Disease information summary
- Complete JSON response example

## Starting the API Server

```bash
cd ksm
python api_server.py
```

Or specify a custom port:
```bash
python api_server.py 9000
```

## Error Handling

### No Leaves Detected (404):
```json
{
  "error": "No grape leaves detected in the image",
  "status": 404,
  "timestamp": "2025-11-29T12:34:56.789"
}
```

### Processing Error (500):
```json
{
  "error": "Detection error: <error message>",
  "status": 500,
  "timestamp": "2025-11-29T12:34:56.789"
}
```

## Notes

- The API uses YOLO disease detection model (`yolo_disease_detection.pt`) to identify specific diseases
- Disease names returned by YOLO are matched against the disease characteristics database
- If a disease is not in the database, generic information is provided
- Multiple diseases can be detected on a single leaf
- The `percentage` field shows what portion of the leaf is affected by each disease
- All confidence values are normalized to 0.0-1.0 range (multiply by 100 for percentage)

## Requirements

- Python 3.8+
- All dependencies from `requirements.txt`
- Model files: `yolo_leaf_detection.pt`, `yolo_disease_detection.pt`, `mobile_sam.pt`, `patchcore_anomaly.pth`

## Future Enhancements

Potential improvements:
- Add disease images to the response
- Include confidence thresholds per disease
- Add historical tracking of disease progression
- Multi-language support for descriptions and treatments
- Add disease prevention recommendations
- Include economic impact estimates
