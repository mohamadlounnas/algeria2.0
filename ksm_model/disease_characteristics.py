"""
Disease Characteristics Database
Contains detailed information about grape leaf diseases for detection and classification
"""

# ============================================================================
# DISEASE CHARACTERISTICS DATABASE - HYBRID METHOD
# ============================================================================
# Enhanced database with 10 diseases, HSV + RGB dual validation
# Scoring: Shape (30) + Circularity (15) + Area (15) + HSV (40) + RGB (10) = 110 points

DISEASE_CHARACTERISTICS = {
    'Black Rot': {
        'color_range': {
            'h_range': (0, 15),         # Very dark brown/black (narrow range)
            's_range': (50, 255),       # High saturation
            'v_range': (10, 80),        # Very dark (LOW value is key!)
        },
        'rgb_range': {
            'r': (20, 100),
            'g': (10, 70),
            'b': (5, 50)
        },
        'shape': 'circular',
        'circularity_range': (0.65, 1.0),
        'area_range': (200, 8000),
        'texture': 'uniform_dark',
        'description': 'Very dark brown to black circular lesions with concentric rings',
        'severity': 'high',
        'treatment': 'Apply fungicides containing mancozeb or captan. Remove infected leaves and improve air circulation.'
    },
    'Esca (Black Measles)': {
        'color_range': {
            'h_range': (160, 180),      # Red-purple hue
            's_range': (80, 255),
            'v_range': (30, 120),
        },
        'rgb_range': {
            'r': (80, 150),
            'g': (10, 60),
            'b': (10, 60)
        },
        'shape': 'irregular',
        'circularity_range': (0.15, 0.5),
        'area_range': (500, 15000),
        'texture': 'striped',
        'description': 'Irregular dark red to black stripes (tiger-stripe pattern)',
        'severity': 'high',
        'treatment': 'No cure available. Prune infected wood during dormancy. Apply trunk protectants.'
    },
    'Leaf Blight (Isariopsis Leaf Spot)': {
        'color_range': {
            'h_range': (10, 20),        # Brown-orange
            's_range': (100, 220),
            'v_range': (80, 150),       # Medium brightness
        },
        'rgb_range': {
            'r': (100, 170),
            'g': (60, 110),
            'b': (30, 80)
        },
        'shape': 'angular',
        'circularity_range': (0.35, 0.7),
        'area_range': (100, 5000),
        'texture': 'angular_spots',
        'description': 'Angular brown spots with yellow halos',
        'severity': 'medium',
        'treatment': 'Apply copper-based fungicides. Improve canopy ventilation and reduce humidity.'
    },
    'Anthracnose': {
        'color_range': {
            'h_range': (8, 18),         # Dark brown
            's_range': (120, 255),
            'v_range': (60, 130),
        },
        'rgb_range': {
            'r': (90, 150),
            'g': (50, 100),
            'b': (20, 70)
        },
        'shape': 'circular',
        'circularity_range': (0.5, 0.85),
        'area_range': (150, 6000),
        'texture': 'dark_margins',
        'description': 'Circular brown lesions with darker margins',
        'severity': 'high',
        'treatment': 'Apply chlorothalonil or mancozeb. Remove infected plant debris and ensure good drainage.'
    },
    'Septoria Leaf Spot': {
        'color_range': {
            'h_range': (20, 35),        # Tan/gray
            's_range': (20, 100),       # LOW saturation (key!)
            'v_range': (130, 200),      # Bright center
        },
        'rgb_range': {
            'r': (140, 210),
            'g': (120, 180),
            'b': (100, 160)
        },
        'shape': 'circular',
        'circularity_range': (0.6, 0.9),
        'area_range': (80, 3000),
        'texture': 'light_center',
        'description': 'Circular spots with light tan/gray centers and dark borders',
        'severity': 'medium',
        'treatment': 'Use copper fungicides or chlorothalonil. Remove and destroy infected leaves.'
    },
    'Bacterial Leaf Spot': {
        'color_range': {
            'h_range': (15, 30),
            's_range': (140, 255),
            'v_range': (50, 130),
        },
        'rgb_range': {
            'r': (100, 150),
            'g': (50, 90),
            'b': (15, 50)
        },
        'shape': 'circular',
        'circularity_range': (0.65, 0.95),
        'area_range': (30, 1500),      # SMALL spots
        'texture': 'small_spots',
        'description': 'Small circular brown spots with yellow halos',
        'severity': 'medium',
        'treatment': 'Apply copper-based bactericides. Reduce overhead irrigation and improve air circulation.'
    },
    'Bacterial Spot': {
        'color_range': {
            'h_range': (10, 25),
            's_range': (100, 200),
            'v_range': (40, 110),
        },
        'rgb_range': {
            'r': (80, 140),
            'g': (40, 80),
            'b': (10, 40)
        },
        'shape': 'circular',
        'circularity_range': (0.6, 0.95),
        'area_range': (50, 2000),
        'texture': 'dark_spots',
        'description': 'Dark brown circular spots with water-soaked appearance',
        'severity': 'medium',
        'treatment': 'Apply copper compounds. Avoid overhead watering and ensure proper plant spacing.'
    },
    'Rust': {
        'color_range': {
            'h_range': (8, 22),         # Orange-rust
            's_range': (180, 255),      # VERY high saturation
            'v_range': (100, 200),      # Bright orange
        },
        'rgb_range': {
            'r': (150, 220),
            'g': (70, 130),
            'b': (15, 60)
        },
        'shape': 'circular',
        'circularity_range': (0.7, 1.0),
        'area_range': (10, 800),       # VERY small pustules
        'texture': 'pustules',
        'description': 'Bright orange-rust colored small circular pustules',
        'severity': 'medium',
        'treatment': 'Apply sulfur or myclobutanil-based fungicides. Remove infected leaves promptly.'
    },
    'Downy Mildew': {
        'color_range': {
            'h_range': (25, 45),        # Yellow
            's_range': (30, 120),       # Medium saturation
            'v_range': (160, 255),      # BRIGHT (key!)
        },
        'rgb_range': {
            'r': (180, 255),
            'g': (180, 255),
            'b': (140, 220)
        },
        'shape': 'irregular',
        'circularity_range': (0.25, 0.65),
        'area_range': (500, 20000),    # Large patches
        'texture': 'oily_patches',
        'description': 'Large yellowish-white irregular oily patches',
        'severity': 'high',
        'treatment': 'Apply phosphorous acid or metalaxyl fungicides. Improve air circulation and reduce leaf wetness.'
    },
    'Powdery Mildew': {
        'color_range': {
            'h_range': (0, 180),        # Any hue (achromatic)
            's_range': (0, 40),         # VERY LOW saturation (key!)
            'v_range': (200, 255),      # VERY bright (key!)
        },
        'rgb_range': {
            'r': (210, 255),
            'g': (210, 255),
            'b': (210, 255)
        },
        'shape': 'irregular',
        'circularity_range': (0.2, 0.6),
        'area_range': (800, 25000),    # Very large patches
        'texture': 'powdery',
        'description': 'Large white to gray powdery patches covering leaf surface',
        'severity': 'high',
        'treatment': 'Apply sulfur, potassium bicarbonate, or myclobutanil. Ensure adequate sunlight and air flow.'
    },
    'Healthy Tissue': {
        'color_range': {
            'h_range': (35, 85),        # Green hue range
            's_range': (40, 255),       # Medium to high saturation
            'v_range': (40, 220),       # Medium brightness
        },
        'rgb_range': {
            'r': (20, 150),
            'g': (50, 200),
            'b': (20, 150)
        },
        'shape': 'irregular',
        'circularity_range': (0.0, 1.0),  # Any shape (not disease-specific)
        'area_range': (100, 50000),       # Variable size
        'texture': 'uniform_green',
        'description': 'Healthy green leaf tissue - likely false positive or bad image input',
        'severity': 'none',
        'treatment': 'No treatment needed. Continue regular monitoring and maintenance.'
    }
}


def get_disease_info(disease_name):
    """
    Get detailed information about a specific disease
    
    Args:
        disease_name: Name of the disease
        
    Returns:
        Dictionary with disease information or None if not found
    """
    return DISEASE_CHARACTERISTICS.get(disease_name, None)


def get_all_diseases():
    """Get list of all known diseases"""
    return list(DISEASE_CHARACTERISTICS.keys())


def get_disease_description(disease_name):
    """Get description of a disease"""
    disease = DISEASE_CHARACTERISTICS.get(disease_name, {})
    return disease.get('description', 'Unknown disease')


def get_disease_treatment(disease_name):
    """Get treatment recommendation for a disease"""
    disease = DISEASE_CHARACTERISTICS.get(disease_name, {})
    return disease.get('treatment', 'Consult with agricultural specialist')


def get_disease_severity(disease_name):
    """Get severity level of a disease"""
    disease = DISEASE_CHARACTERISTICS.get(disease_name, {})
    return disease.get('severity', 'unknown')
