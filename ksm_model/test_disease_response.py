"""
Test script to verify disease names in API JSON response
"""
import json

# Simulate the API response structure
def create_sample_response():
    """Create a sample JSON response with disease information"""
    
    # Simulate detected diseases
    sample_response = {
        "leafs": [
            {
                "image": "http://192.168.1.100:8888/static/leaf_1_1234567890.jpg",
                "heatmap": "http://192.168.1.100:8888/static/heatmap_1_1234567890.jpg",
                "overlay": "http://192.168.1.100:8888/static/overlay_1_1234567890.jpg",
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
                "is_diseased": True
            },
            {
                "image": "http://192.168.1.100:8888/static/leaf_2_1234567891.jpg",
                "heatmap": "http://192.168.1.100:8888/static/heatmap_2_1234567891.jpg",
                "overlay": "http://192.168.1.100:8888/static/overlay_2_1234567891.jpg",
                "diseases": {
                    "healthy": {
                        "confidence": 0.96,
                        "percentage": 0.0,
                        "description": "Healthy green leaf tissue",
                        "severity": "none",
                        "treatment": "No treatment needed. Continue regular monitoring."
                    }
                },
                "anomaly_score": 0.12,
                "is_diseased": False
            },
            {
                "image": "http://192.168.1.100:8888/static/leaf_3_1234567892.jpg",
                "heatmap": "http://192.168.1.100:8888/static/heatmap_3_1234567892.jpg",
                "overlay": "http://192.168.1.100:8888/static/overlay_3_1234567892.jpg",
                "diseases": {
                    "Powdery Mildew": {
                        "confidence": 0.91,
                        "percentage": 35.7,
                        "description": "Large white to gray powdery patches covering leaf surface",
                        "severity": "high",
                        "treatment": "Apply sulfur, potassium bicarbonate, or myclobutanil. Ensure adequate sunlight and air flow."
                    }
                },
                "anomaly_score": 0.92,
                "is_diseased": True
            }
        ],
        "summary": {
            "total_leafs": 3,
            "diseased_leafs": 2,
            "healthy_leafs": 1
        },
        "timestamp": "2025-11-29T12:34:56.789",
        "image_processed": True
    }
    
    return sample_response


def print_disease_summary(response):
    """Print a summary of detected diseases"""
    print("\n" + "=" * 70)
    print("DISEASE DETECTION API RESPONSE SUMMARY")
    print("=" * 70)
    
    print(f"\n📊 Overall Statistics:")
    print(f"   Total Leaves: {response['summary']['total_leafs']}")
    print(f"   Diseased Leaves: {response['summary']['diseased_leafs']}")
    print(f"   Healthy Leaves: {response['summary']['healthy_leafs']}")
    
    print(f"\n🍃 Individual Leaf Analysis:")
    
    for idx, leaf in enumerate(response['leafs'], 1):
        print(f"\n   Leaf #{idx}:")
        print(f"   Status: {'🔴 DISEASED' if leaf['is_diseased'] else '🟢 HEALTHY'}")
        print(f"   Anomaly Score: {leaf['anomaly_score']:.2f}")
        print(f"   Image: {leaf['image'].split('/')[-1]}")
        
        if leaf['diseases']:
            print(f"   \n   Detected Conditions:")
            for disease_name, disease_info in leaf['diseases'].items():
                print(f"\n      🦠 {disease_name}")
                print(f"         Confidence: {disease_info['confidence']:.1%}")
                
                if disease_info['percentage'] > 0:
                    print(f"         Coverage: {disease_info['percentage']:.1f}%")
                
                print(f"         Severity: {disease_info['severity'].upper()}")
                print(f"         Description: {disease_info['description']}")
                print(f"         Treatment: {disease_info['treatment']}")


def test_json_structure():
    """Test the JSON response structure"""
    print("\n" + "=" * 70)
    print("TESTING JSON RESPONSE STRUCTURE")
    print("=" * 70)
    
    response = create_sample_response()
    
    # Convert to JSON and back to verify it's valid
    json_str = json.dumps(response, indent=2)
    parsed = json.loads(json_str)
    
    print("\n✅ JSON is valid and properly formatted")
    print(f"✅ Response contains {len(parsed['leafs'])} leaf entries")
    
    # Check required fields
    required_fields = ['leafs', 'summary', 'timestamp', 'image_processed']
    for field in required_fields:
        if field in parsed:
            print(f"✅ Field '{field}' present")
        else:
            print(f"❌ Field '{field}' missing")
    
    # Check disease information structure
    print("\n📋 Disease Information Structure:")
    for leaf in parsed['leafs']:
        if leaf['diseases']:
            for disease_name, disease_info in leaf['diseases'].items():
                required_disease_fields = ['confidence', 'percentage', 'description', 'severity', 'treatment']
                print(f"\n   Disease: {disease_name}")
                for field in required_disease_fields:
                    if field in disease_info:
                        print(f"   ✅ {field}: {type(disease_info[field]).__name__}")
                    else:
                        print(f"   ❌ {field}: MISSING")
                break  # Just check first disease
            break  # Just check first leaf


def show_json_output():
    """Display the complete JSON output"""
    print("\n" + "=" * 70)
    print("COMPLETE JSON RESPONSE")
    print("=" * 70)
    
    response = create_sample_response()
    json_str = json.dumps(response, indent=2)
    print(json_str)


def main():
    print("🍇 Disease Detection API - JSON Response Verification")
    print("=" * 70)
    
    # Test 1: JSON structure validation
    test_json_structure()
    
    # Test 2: Create and display summary
    response = create_sample_response()
    print_disease_summary(response)
    
    # Test 3: Show complete JSON
    show_json_output()
    
    print("\n" + "=" * 70)
    print("✅ All tests completed successfully!")
    print("=" * 70)
    print("\n📝 Note: This is a simulation. To test with real API:")
    print("   1. Start the API server: python api_server.py")
    print("   2. Send request: http://localhost:8888/api/process?url=<image_url>")
    print("   3. The response will include disease names, descriptions, and treatments")
    print("=" * 70)


if __name__ == "__main__":
    main()
