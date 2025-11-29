# 🍇 Grape Leaf Disease Detection API

**AI-powered REST API for automated grape leaf disease detection and classification**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.8+-blue.svg)
![Status](https://img.shields.io/badge/status-production-green.svg)

---

## 📋 Overview

A production-ready HTTP API server that detects and classifies diseases in grape leaves using state-of-the-art computer vision and deep learning models. The system processes images from URLs and returns detailed disease analysis with confidence scores.

### Key Features

- 🌐 **RESTful API** - Simple HTTP GET endpoints
- 📊 **Multi-Model Pipeline** - Combines YOLO, SAM, and PatchCore
- 🔄 **Batch Processing** - Handle single or multiple images
- 🌍 **Network Accessible** - Works across local network
- ⚡ **GPU Accelerated** - CUDA support for fast inference
- 🔐 **CORS Enabled** - Cross-origin resource sharing

---

## 🚀 Quick Start

### Prerequisites

- Python 3.8 or higher
- CUDA-capable GPU (recommended for performance)
- 8GB+ RAM
- ~2GB disk space for models

### Installation

1. **Navigate to directory:**
```bash
cd ksm
```

2. **Install dependencies:**
```bash
pip install -r requirements.txt
```

3. **Start the server:**
```bash
python api_server.py
```

The server will start on `http://0.0.0.0:8888` and display your local IP address.

---

## 📡 API Reference

### Base URL
```
http://YOUR_IP:8888
```

### Endpoints

#### 1. Process Single Image
```http
GET /api/process?url=<image_url>
```

**Parameters:**
- `url` (required) - Direct URL to grape leaf image

**Example:**
```bash
curl "http://localhost:8888/api/process?url=https://example.com/grape-leaf.jpg"
```

**Response:**
```json
{
  "leafs": [
    {
      "image": "http://10.173.125.97:8888/static/leaf_1_1732825045123.jpg",
      "heatmap": "http://10.173.125.97:8888/static/heatmap_1_1732825045123.jpg",
      "overlay": "http://10.173.125.97:8888/static/overlay_1_1732825045123.jpg",
      "diseases": {
        "downy_mildew": 0.87,
        "powdery_mildew": 0.65
      },
      "anomaly_score": 45.2,
      "is_diseased": true
    }
  ],
  "summary": {
    "total_leafs": 1,
    "diseased_leafs": 1,
    "healthy_leafs": 0
  },
  "timestamp": "2025-11-28T10:30:45.123456",
  "image_processed": true
}
```

**Error Response (No Leaves):**
```json
{
  "error": "No grape leaves detected in the image",
  "status": 404,
  "timestamp": "2025-11-28T10:30:45.123456"
}
```

#### 2. Batch Process Multiple Images
```http
GET /api/process?urls=<url1,url2,url3>
```

**Parameters:**
- `urls` (required) - Comma-separated list of image URLs

**Example:**
```bash
curl "http://localhost:8888/api/process?urls=https://ex1.com/leaf1.jpg,https://ex2.com/leaf2.jpg"
```

**Response:**
```json
[
  {
    "leafs": [
      {
        "image": "http://10.173.125.97:8888/static/leaf_1_1732825045123.jpg",
        "heatmap": "http://10.173.125.97:8888/static/heatmap_1_1732825045123.jpg",
        "diseases": {
          "healthy": 0.95
        },
        "anomaly_score": 12.3,
        "is_diseased": false
      }
    ],
    "summary": {
      "total_leafs": 1,
      "diseased_leafs": 0,
      "healthy_leafs": 1
    },
    "image_url": "https://ex1.com/leaf1.jpg",
    "processing_index": 1,
    "timestamp": "2025-11-28T10:30:45.123456",
    "image_processed": true
  },
  {
    "leafs": [
      {
        "image": "http://10.173.125.97:8888/static/leaf_2_1732825046234.jpg",
        "heatmap": "http://10.173.125.97:8888/static/heatmap_2_1732825046234.jpg",
        "diseases": {
          "powdery_mildew": 0.88
        },
        "anomaly_score": 52.7,
        "is_diseased": true
      }
    ],
    "summary": {
      "total_leafs": 1,
      "diseased_leafs": 1,
      "healthy_leafs": 0
    },
    "image_url": "https://ex2.com/leaf2.jpg", 
    "processing_index": 2,
    "timestamp": "2025-11-28T10:30:46.234567",
    "image_processed": true
  }
]
```

---

## 🏗️ Architecture

### System Components

```
┌─────────────────────────────────────────┐
│         HTTP API Server                  │
│         (api_server.py)                  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│     Disease Detection Pipeline           │
│     (disease_pipeline.py)                │
└────────────────┬────────────────────────┘
                 │
    ┌────────────┼────────────┐
    ▼            ▼             ▼
┌────────┐  ┌────────┐   ┌──────────┐
│ YOLO   │  │  SAM   │   │PatchCore │
│ Detect │  │Segment │   │ Anomaly  │
└────────┘  └────────┘   └──────────┘
```

### AI Models

| Model | Purpose | File | Size |
|-------|---------|------|------|
| **YOLO Leaf Detection** | Detects and locates grape leaves | `yolo_leaf_detection.pt` | 10 MB |
| **SAM Segmentation** | Precise leaf boundary segmentation | `sam2.1_l.pt` | 428 MB |
| **PatchCore Anomaly** | Healthy vs diseased classification | `patchcore_anomaly.pth` | 1 MB |
| **YOLO Disease Detection** | Identifies specific disease types | `yolo_disease_detection.pt` | 49 MB |

### Processing Pipeline

1. **Image Download** - Fetch image from provided URL
2. **Leaf Detection** - YOLO identifies leaf regions
3. **Segmentation** - SAM creates precise masks
4. **Anomaly Detection** - PatchCore checks for abnormalities
5. **Disease Classification** - YOLO identifies disease types
6. **Result Aggregation** - Combine results with confidence scores

---

## 📁 Project Structure

```
ksm/
├── api_server.py                  # Main HTTP API server
├── disease_pipeline.py            # Detection pipeline logic
├── yolo_leaf_detection.pt         # Leaf detection model
├── sam2.1_l.pt                    # Segmentation model
├── patchcore_anomaly.pth          # Anomaly detection model
├── yolo_disease_detection.pt      # Disease classification model
├── requirements.txt               # Python dependencies
└── README.md                      # This file
```

---

## ⚙️ Configuration

### Change Port
```bash
python api_server.py 9000
```

### Environment Variables
```bash
# Use CPU only (no GPU)
export CUDA_VISIBLE_DEVICES=""

# Limit GPU memory
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

---

## 🧪 Testing

### Using cURL
```bash
# Single image
curl "http://localhost:8888/api/process?url=https://example.com/leaf.jpg"

# Multiple images
curl "http://localhost:8888/api/process?urls=url1.jpg,url2.jpg,url3.jpg"
```

### Using Python
```python
import requests

# Single image
response = requests.get(
    'http://localhost:8888/api/process',
    params={'url': 'https://example.com/leaf.jpg'}
)

if response.status_code == 200:
    result = response.json()
    print(f"Found {result['summary']['total_leafs']} leaves")
    for leaf in result['leafs']:
        print(f"Diseases: {leaf['diseases']}")
elif response.status_code == 404:
    print("No leaves detected in image")
else:
    print(f"Error: {response.json()['error']}")

# Bulk processing
response = requests.get(
    'http://localhost:8888/api/process',
    params={'urls': 'url1.jpg,url2.jpg,url3.jpg'}
)
results = response.json()
for img in results:
    if 'leafs' in img:
        print(f"{img['image_url']}: {img['summary']['total_leafs']} leaves")
    else:
        print(f"{img['image_url']}: Error - {img['error']}")
```

### Using JavaScript
```javascript
// Single image
fetch('http://localhost:8888/api/process?url=https://example.com/leaf.jpg')
  .then(response => {
    if (response.ok) {
      return response.json();
    } else if (response.status === 404) {
      throw new Error('No leaves detected');
    } else {
      throw new Error('Processing error');
    }
  })
  .then(data => {
    console.log(`Found ${data.summary.total_leafs} leaves`);
    data.leafs.forEach(leaf => {
      console.log('Diseases:', leaf.diseases);
      // Display leaf image
      const img = document.createElement('img');
      img.src = leaf.image;
      document.body.appendChild(img);
      
      // Display heatmap
      if (leaf.heatmap) {
        const heatmapImg = document.createElement('img');
        heatmapImg.src = leaf.heatmap;
        document.body.appendChild(heatmapImg);
      }
      
      // Display overlay (leaf + heatmap blended)
      if (leaf.overlay) {
        const overlayImg = document.createElement('img');
        overlayImg.src = leaf.overlay;
        document.body.appendChild(overlayImg);
      }
    });
  })
  .catch(error => console.error(error));

// Bulk processing
fetch('http://localhost:8888/api/process?urls=url1.jpg,url2.jpg')
  .then(response => response.json())
  .then(data => data.forEach(img => {
    if (img.leafs) {
      console.log(`${img.image_url}: ${img.summary.total_leafs} leaves`);
    } else {
      console.log(`${img.image_url}: Error - ${img.error}`);
    }
  }));
```

---

## 🌍 Network Access

### Find Your IP Address

**Windows:**
```powershell
ipconfig | findstr IPv4
```

**Linux/Mac:**
```bash
ifconfig | grep "inet "
```

### Access from Other Devices

Once the server is running, it's accessible from any device on your network:

```
http://YOUR_IP:8888/api/process?url=<image_url>
```

Example:
```
http://192.168.1.100:8888/api/process?url=https://example.com/leaf.jpg
```

### Firewall Configuration

If you can't connect from other devices, ensure port 8888 is allowed:

**Windows:**
```powershell
netsh advfirewall firewall add rule name="Grape Detection API" dir=in action=allow protocol=TCP localport=8888
```

**Linux:**
```bash
sudo ufw allow 8888/tcp
```

---

## 🐛 Troubleshooting

### Server Won't Start

**Error: "Address already in use"**
```bash
# Use a different port
python api_server.py 8889
```

**Error: "Failed to import disease pipeline"**
```bash
# Ensure disease_pipeline.py is in the same directory
ls disease_pipeline.py
```

### Model Loading Issues

**Error: "Model file not found"**
```bash
# Verify all model files exist
ls *.pt *.pth
```

**Error: "Out of memory"**
```bash
# Reduce batch size or use CPU
export CUDA_VISIBLE_DEVICES=""
```

### Network Issues

**Can't access from other devices:**
1. Check firewall settings
2. Verify IP address is correct
3. Ensure devices are on same network
4. Try using `0.0.0.0` instead of specific IP

---

## 📊 Performance

### Typical Processing Times

| Operation | GPU (CUDA) | CPU |
|-----------|------------|-----|
| Single image | 2-4 seconds | 10-15 seconds |
| Batch (10 images) | 15-25 seconds | 90-120 seconds |

### Optimization Tips

1. **Use GPU** - Significant speed improvement
2. **Batch Processing** - More efficient than multiple single requests
3. **Image Size** - Smaller images process faster
4. **Network Speed** - Fast internet for image downloads

---

## 🔒 Security Considerations

⚠️ **Important for Production Deployment:**

1. **Authentication** - Add API key validation
2. **Rate Limiting** - Prevent abuse
3. **HTTPS** - Use SSL/TLS encryption
4. **Input Validation** - Sanitize URLs
5. **Access Control** - Restrict IP addresses if needed

---

## 📦 Deployment

### Docker (Recommended)

```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY . .

RUN pip install -r requirements.txt

EXPOSE 8888
CMD ["python", "api_server.py"]
```

```bash
docker build -t grape-detection-api .
docker run -p 8888:8888 --gpus all grape-detection-api
```

### Cloud Deployment

The entire `ksm` folder is self-contained and can be deployed to:
- AWS EC2
- Google Cloud Compute
- Azure VMs
- Heroku
- DigitalOcean

Simply:
1. Upload folder
2. Install Python dependencies
3. Run `python api_server.py`

---

## 📝 License

MIT License - See LICENSE file for details

---

## 🤝 Support

For issues, questions, or contributions:
- Check the [Troubleshooting](#-troubleshooting) section
- Review API documentation above
- Ensure all dependencies are installed

---

## 🔄 Version History

**v1.0.0** (2025-11-28)
- Initial release
- Single and batch processing
- Network accessible API
- GPU acceleration support

---

**Made with 🍇 for precision agriculture**
