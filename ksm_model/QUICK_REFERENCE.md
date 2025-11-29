# Quick Reference: Disease Names in API Response

## ✅ What Changed

The API now returns **detailed disease information** instead of just confidence scores.

### Before (Old Format):
```json
"diseases": {
  "Black Rot": 0.87,
  "healthy": 0.96
}
```

### After (New Format):
```json
"diseases": {
  "Black Rot": {
    "confidence": 0.87,
    "percentage": 15.3,
    "description": "Very dark brown to black circular lesions",
    "severity": "high",
    "treatment": "Apply fungicides containing mancozeb or captan..."
  },
  "healthy": {
    "confidence": 0.96,
    "percentage": 0.0,
    "description": "Healthy green leaf tissue",
    "severity": "none",
    "treatment": "No treatment needed"
  }
}
```

## 📋 Files Added to ksm/ Folder

1. ✅ **disease_characteristics.py** - Disease database (11 diseases)
2. ✅ **test_disease_response.py** - Test script
3. ✅ **API_DISEASE_NAMES_README.md** - Full documentation
4. ✅ **QUICK_REFERENCE.md** - This file

## 🔧 Files Modified

1. ✅ **api_server.py** - Now imports and uses disease database

## 🦠 Supported Disease Names

| # | Disease Name | Severity | Description |
|---|--------------|----------|-------------|
| 1 | Black Rot | High | Very dark brown to black circular lesions |
| 2 | Esca (Black Measles) | High | Irregular dark red to black stripes |
| 3 | Leaf Blight | Medium | Angular brown spots with yellow halos |
| 4 | Anthracnose | High | Circular brown lesions with darker margins |
| 5 | Septoria Leaf Spot | Medium | Circular spots with light centers |
| 6 | Bacterial Leaf Spot | Medium | Small circular brown spots with halos |
| 7 | Bacterial Spot | Medium | Dark brown circular spots |
| 8 | Rust | Medium | Bright orange-rust colored pustules |
| 9 | Downy Mildew | High | Large yellowish-white oily patches |
| 10 | Powdery Mildew | High | White to gray powdery patches |
| 11 | Healthy Tissue | None | Healthy green leaf tissue |

## 🚀 Quick Start

### 1. Test the new format:
```bash
cd ksm
python test_disease_response.py
```

### 2. Start the API server:
```bash
python api_server.py
```

### 3. Test with a real image:
```bash
# Windows
curl "http://localhost:8888/api/process?url=file:///C:/path/to/image.jpg"

# Or use your browser
http://localhost:8888/api/process?url=file:///C:/Users/Tomy/Desktop/recon/test_image.jpg
```

## 💡 Example Response

```json
{
  "leafs": [
    {
      "image": "http://192.168.1.100:8888/static/leaf_1.jpg",
      "diseases": {
        "Powdery Mildew": {
          "confidence": 0.91,
          "percentage": 35.7,
          "description": "Large white to gray powdery patches",
          "severity": "high",
          "treatment": "Apply sulfur, potassium bicarbonate, or myclobutanil"
        }
      },
      "is_diseased": true
    }
  ],
  "summary": {
    "total_leafs": 1,
    "diseased_leafs": 1,
    "healthy_leafs": 0
  }
}
```

## 📊 Accessing Disease Data

### Python:
```python
# Get disease name
for disease_name in leaf['diseases'].keys():
    print(f"Disease: {disease_name}")

# Get disease details
disease_info = leaf['diseases']['Black Rot']
print(f"Confidence: {disease_info['confidence']:.1%}")
print(f"Treatment: {disease_info['treatment']}")
```

### JavaScript:
```javascript
// Get disease names
Object.keys(leaf.diseases).forEach(name => {
    console.log(`Disease: ${name}`);
});

// Get disease details
const disease = leaf.diseases['Black Rot'];
console.log(`Confidence: ${(disease.confidence * 100).toFixed(1)}%`);
console.log(`Treatment: ${disease.treatment}`);
```

## ✅ Verification Checklist

- [x] disease_characteristics.py created with 11 diseases
- [x] api_server.py updated to return disease details
- [x] Test script created (test_disease_response.py)
- [x] Documentation created
- [x] Each disease includes: confidence, percentage, description, severity, treatment
- [x] Response format validated
- [x] Backward compatible (existing code works with new structure)

## 🎯 Key Benefits

1. **Disease Names** - Know exactly what disease was detected
2. **Descriptions** - Understand disease characteristics
3. **Severity** - Prioritize treatment based on severity level
4. **Treatment** - Get actionable treatment recommendations
5. **Coverage** - See percentage of leaf affected
6. **Confidence** - Know detection reliability

## 📞 Support

For issues or questions:
1. Check API_DISEASE_NAMES_README.md for full documentation
2. Run test_disease_response.py to verify installation
3. Check that all model files are in ksm/ folder
