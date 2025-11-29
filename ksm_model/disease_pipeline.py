"""
Complete Grape Leaf Disease Detection Pipeline
Integrates: YOLO Detection -> SAM Segmentation -> PatchCore Anomaly Detection -> Disease Segmentation

Requirements:
    pip install torch torchvision ultralytics opencv-python pillow matplotlib scikit-learn numpy

Usage:
    python complete_pipeline.py --image path/to/grape_image.jpg
    python complete_pipeline.py --folder path/to/images/ --workers 4
"""

import os
import argparse
import cv2
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
from PIL import Image
import torch
import torch.nn.functional as F
import torchvision.transforms as transforms
import torchvision.models as models
from sklearn.neighbors import NearestNeighbors
from ultralytics import YOLO, SAM
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm

# ============================================================================
# CONFIGURATION
# ============================================================================
DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'
YOLO_LEAF_MODEL = 'best.pt'  # Leaf detection model
SAM_MODEL = 'sam2.1_l.pt'  # Segmentation model
PATCHCORE_MODEL = 'best_model.pth'  # Anomaly detection model
YOLO_DISEASE_MODEL = 'ds.pt'  # Disease detection model
OUTPUT_DIR = 'results'

# ============================================================================
# LEAF EXTRACTION MODULE (YOLO + SAM)
# ============================================================================
class LeafExtractor:
    """Extract individual leaves using YOLO detection and SAM segmentation"""
    
    def __init__(self, yolo_path, sam_path):
        print("🔍 Loading Leaf Detection Models...")
        self.yolo_model = YOLO(yolo_path)
        self.sam_model = SAM(sam_path)
        print(f"✅ Models loaded on {DEVICE}")
    
    def extract_leaves(self, img_path):
        """Extract all leaves from image"""
        img_bgr = cv2.imread(img_path)
        if img_bgr is None:
            print(f"❌ Failed to load image: {img_path}")
            return []
        
        # YOLO detection
        try:
            results = self.yolo_model.predict(
                source=img_path,
                imgsz=640,
                conf=0.25,
                iou=0.4,
                verbose=False
            )
            
            boxes = results[0].boxes
            if len(boxes) == 0:
                print("⚠️ YOLO detected no leaves in the image")
                return []
        except Exception as e:
            print(f"❌ YOLO detection error: {e}")
            return []
        
        # Extract each leaf
        leaves = []
        for idx, box in enumerate(boxes):
            try:
                x1, y1, x2, y2 = map(int, box.xyxy[0].cpu().numpy())
                center_x = (x1 + x2) // 2
                center_y = (y1 + y2) // 2
                
                # SAM segmentation
                masks = self.sam_model.predict(
                    img_bgr, 
                    points=[[center_x, center_y]], 
                    labels=[1], 
                    device=DEVICE,
                    verbose=False
                )
                
                if len(masks) > 0 and masks[0].masks is not None:
                    mask = masks[0].masks.data[0].cpu().numpy().squeeze()
                    mask_uint8 = (mask * 255).astype(np.uint8)
                    
                    # Extract with black background
                    leaf_img = img_bgr.copy()
                    leaf_img[mask_uint8 == 0] = [0, 0, 0]
                    
                    # Crop to boundaries
                    leaf_img = self._crop_to_leaf(leaf_img, mask_uint8)
                    
                    leaves.append({
                        'image': leaf_img,
                        'bbox': (x1, y1, x2, y2),
                        'center': (center_x, center_y),
                        'index': idx
                    })
            except Exception as e:
                print(f"⚠️ Failed to extract leaf {idx}: {e}")
                continue
        
        return leaves
    
    def _crop_to_leaf(self, img, mask):
        """Crop image to leaf boundaries"""
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if len(contours) == 0:
            return img
        
        largest = max(contours, key=cv2.contourArea)
        x, y, w, h = cv2.boundingRect(largest)
        
        padding = 10
        x = max(0, x - padding)
        y = max(0, y - padding)
        w = min(img.shape[1] - x, w + 2*padding)
        h = min(img.shape[0] - y, h + 2*padding)
        
        return img[y:y+h, x:x+w]

# ============================================================================
# ANOMALY DETECTION MODULE (PatchCore)
# ============================================================================
class PatchCoreInference:
    """PatchCore anomaly detection for healthy/diseased classification"""
    
    def __init__(self, model_path):
        print("🔍 Loading PatchCore Model...")
        self.device = torch.device(DEVICE)
        
        # Load model
        try:
            model_data = torch.load(model_path, map_location=self.device, weights_only=False)
        except TypeError:
            model_data = torch.load(model_path, map_location=self.device)
        
        self.memory_bank = model_data['memory_bank']
        self.feature_mean = torch.tensor(model_data['feature_mean']).to(self.device)
        self.feature_std = torch.tensor(model_data['feature_std']).to(self.device)
        self.threshold = model_data['performance']['threshold']
        self.backbone_name = model_data['backbone_name']
        self.layers = model_data['layers']
        self.num_neighbors = model_data['num_neighbors']
        self.image_size = model_data['config']['IMAGE_SIZE']
        
        # Load backbone
        if self.backbone_name == 'wide_resnet50_2':
            self.backbone = models.wide_resnet50_2(pretrained=True)
        else:
            self.backbone = models.resnet50(pretrained=True)
        
        self.backbone.eval()
        self.backbone.to(self.device)
        self._setup_hooks()
        
        # k-NN index
        self.nn_model = NearestNeighbors(
            n_neighbors=min(self.num_neighbors, len(self.memory_bank)),
            metric='euclidean',
            algorithm='auto',
            n_jobs=-1
        )
        self.nn_model.fit(self.memory_bank)
        
        # Transforms
        self.transform = transforms.Compose([
            transforms.Resize((self.image_size, self.image_size)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        
        print(f"✅ PatchCore loaded (Threshold: {self.threshold:.4f})")
    
    def _setup_hooks(self):
        """Setup feature extraction hooks"""
        self.features = {}
        self.hooks = []
        
        def get_hook(name):
            def hook(module, input, output):
                self.features[name] = output.detach()
            return hook
        
        for name, module in self.backbone.named_modules():
            if name in self.layers:
                self.hooks.append(module.register_forward_hook(get_hook(name)))
    
    def predict(self, leaf_img_bgr):
        """Predict if leaf is healthy or diseased with heatmap generation"""
        # Convert BGR to RGB
        img_rgb = cv2.cvtColor(leaf_img_bgr, cv2.COLOR_BGR2RGB)
        img_pil = Image.fromarray(img_rgb)
        
        # Transform
        img_tensor = self.transform(img_pil).unsqueeze(0).to(self.device)
        
        # Extract features
        with torch.no_grad():
            self.features.clear()
            _ = self.backbone(img_tensor)
            
            # Process features for score
            processed = []
            feature_maps_for_heatmap = []
            
            for layer_name, feature_map in self.features.items():
                if len(feature_map.shape) == 4:
                    # Store for heatmap
                    feature_maps_for_heatmap.append(feature_map)
                    
                    # Pool for anomaly score
                    pooled = F.adaptive_avg_pool2d(feature_map, (1, 1))
                    pooled = pooled.view(pooled.size(0), -1)
                    processed.append(pooled)
            
            features = torch.cat(processed, dim=1)
            features = torch.nan_to_num(features, nan=0.0)
            
            # Normalize
            norm = torch.norm(features, p=2, dim=1, keepdim=True)
            features = features / torch.clamp(norm, min=1e-8)
            
            # Apply statistics
            normalized = (features - self.feature_mean) / self.feature_std
            normalized = torch.nan_to_num(normalized, nan=0.0)
            
            # Calculate score
            features_np = normalized.cpu().numpy()
            distances, _ = self.nn_model.kneighbors(features_np)
            score = float(np.mean(distances))
            
            # Generate heatmap
            heatmap = self._generate_heatmap(feature_maps_for_heatmap, leaf_img_bgr.shape[:2])
        
        is_anomaly = score > self.threshold
        
        if is_anomaly:
            confidence = min(100, ((score - self.threshold) / self.threshold) * 100)
        else:
            confidence = min(100, ((self.threshold - score) / self.threshold) * 100)
        
        return {
            'anomaly_score': float(score),
            'is_diseased': bool(is_anomaly),
            'confidence': float(confidence),
            'prediction': 'DISEASED' if is_anomaly else 'HEALTHY',
            'heatmap': heatmap
        }
    
    def _generate_heatmap(self, feature_maps, target_size):
        """Generate anomaly heatmap from feature maps"""
        try:
            # Combine all feature maps
            combined_map = None
            
            for fmap in feature_maps:
                # Resize to common size
                resized = F.interpolate(fmap, size=(28, 28), mode='bilinear', align_corners=False)
                
                # Calculate per-pixel anomaly scores
                B, C, H, W = resized.shape
                resized_flat = resized.view(B, C, -1).permute(0, 2, 1)  # B, H*W, C
                
                # Normalize features
                norm = torch.norm(resized_flat, p=2, dim=2, keepdim=True)
                resized_flat = resized_flat / torch.clamp(norm, min=1e-8)
                
                # Apply stats normalization
                resized_flat = (resized_flat - self.feature_mean.mean()) / (self.feature_std.mean() + 1e-8)
                
                # Calculate distances to memory bank
                features_np = resized_flat.cpu().numpy().reshape(-1, C)
                distances, _ = self.nn_model.kneighbors(features_np)
                distance_map = distances.mean(axis=1).reshape(H, W)
                
                if combined_map is None:
                    combined_map = distance_map
                else:
                    combined_map += distance_map
            
            # Average across all feature maps
            if len(feature_maps) > 0:
                combined_map /= len(feature_maps)
            
            # Normalize to 0-255
            combined_map = (combined_map - combined_map.min()) / (combined_map.max() - combined_map.min() + 1e-8)
            combined_map = (combined_map * 255).astype(np.uint8)
            
            # Resize to target size
            heatmap = cv2.resize(combined_map, (target_size[1], target_size[0]))
            
            # Apply colormap
            heatmap_colored = cv2.applyColorMap(heatmap, cv2.COLORMAP_JET)
            
            return heatmap_colored
            
        except Exception as e:
            print(f"⚠️ Heatmap generation warning: {e}")
            # Return blank heatmap on error
            return np.zeros((target_size[0], target_size[1], 3), dtype=np.uint8)

# ============================================================================
# DISEASE SEGMENTATION MODULE (YOLO + Color Analysis)
# ============================================================================
class DiseaseSegmenter:
    """Detect and segment disease regions on leaves"""
    
    def __init__(self, yolo_path):
        print("🔍 Loading Disease Detection Model...")
        self.model = YOLO(yolo_path)
        self.class_names = self.model.names
        print(f"✅ Disease model loaded")
    
    def segment_diseases(self, leaf_img_bgr):
        """Detect and segment disease regions"""
        # YOLO detection
        results = self.model.predict(source=leaf_img_bgr, verbose=False)
        
        img_rgb = cv2.cvtColor(leaf_img_bgr, cv2.COLOR_BGR2RGB)
        img_hsv = cv2.cvtColor(leaf_img_bgr, cv2.COLOR_BGR2HSV)
        img_lab = cv2.cvtColor(leaf_img_bgr, cv2.COLOR_BGR2LAB)
        
        boxes = results[0].boxes
        
        if len(boxes) == 0:
            return None
        
        # Extract healthy reference color
        all_boxes_mask = np.zeros(img_rgb.shape[:2], dtype=np.uint8)
        for box in boxes.xyxy.cpu().numpy():
            x1, y1, x2, y2 = map(int, box)
            all_boxes_mask[y1:y2, x1:x2] = 255
        
        # Black background mask
        lower_black = np.array([0, 0, 0])
        upper_black = np.array([1, 1, 1])
        black_mask = cv2.inRange(img_hsv, lower_black, upper_black)
        
        # Green mask
        lower_green = np.array([35, 40, 40])
        upper_green = np.array([85, 255, 255])
        green_mask = cv2.inRange(img_hsv, lower_green, upper_green)
        
        # Healthy region
        healthy_mask = cv2.bitwise_and(
            cv2.bitwise_and(cv2.bitwise_not(all_boxes_mask), cv2.bitwise_not(black_mask)),
            green_mask
        )
        
        healthy_pixels_lab = img_lab[healthy_mask > 0]
        healthy_pixels_hsv = img_hsv[healthy_mask > 0]
        
        # Calculate total leaf area
        total_leaf_mask = cv2.bitwise_not(black_mask)
        total_leaf_pixels = np.count_nonzero(total_leaf_mask)
        
        result_img = img_rgb.copy()
        all_masks = np.zeros(img_rgb.shape[:2], dtype=np.uint8)
        all_distances = np.zeros(img_rgb.shape[:2], dtype=np.float32)
        disease_info = []
        
        if len(healthy_pixels_lab) > 50:
            # Advanced method with color distance
            healthy_mean_lab = np.mean(healthy_pixels_lab, axis=0)
            healthy_std_lab = np.std(healthy_pixels_lab, axis=0)
            healthy_mean_hsv = np.mean(healthy_pixels_hsv, axis=0)
            
            for i, box in enumerate(boxes.xyxy.cpu().numpy()):
                x1, y1, x2, y2 = map(int, box)
                
                class_id = int(boxes.cls[i].item())
                confidence = boxes.conf[i].item()
                disease_name = self.class_names[class_id]
                
                roi_lab = img_lab[y1:y2, x1:x2]
                roi_hsv = img_hsv[y1:y2, x1:x2]
                
                black_mask_roi = cv2.inRange(roi_hsv, lower_black, upper_black)
                
                # Distance calculation
                roi_lab_reshaped = roi_lab.reshape(-1, 3)
                distances_lab = np.sqrt(np.sum((roi_lab_reshaped - healthy_mean_lab) ** 2, axis=1))
                distances_lab = distances_lab.reshape(roi_lab.shape[:2])
                
                green_mask_roi = cv2.inRange(roi_hsv, lower_green, upper_green)
                
                lab_threshold = 1.5 * np.mean(healthy_std_lab) + 10
                moderate_disease = (distances_lab > lab_threshold) & (green_mask_roi == 0)
                
                roi_hue = roi_hsv[:, :, 0]
                hue_diff = np.abs(roi_hue.astype(float) - healthy_mean_hsv[0])
                hue_diff = np.minimum(hue_diff, 180 - hue_diff)
                different_hue = (hue_diff > 15) & (green_mask_roi == 0)
                
                disease_mask = (moderate_disease | different_hue).astype(np.uint8) * 255
                disease_mask[black_mask_roi > 0] = 0
                
                # Morphological operations
                kernel = np.ones((3, 3), np.uint8)
                disease_mask = cv2.morphologyEx(disease_mask, cv2.MORPH_CLOSE, kernel, iterations=2)
                disease_mask = cv2.morphologyEx(disease_mask, cv2.MORPH_OPEN, kernel, iterations=1)
                disease_mask = cv2.medianBlur(disease_mask, 5)
                
                # Remove small regions
                contours, _ = cv2.findContours(disease_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                for contour in contours:
                    if cv2.contourArea(contour) < 30:
                        cv2.drawContours(disease_mask, [contour], -1, 0, -1)
                
                full_mask = np.zeros(img_rgb.shape[:2], dtype=np.uint8)
                full_mask[y1:y2, x1:x2] = disease_mask
                all_masks = cv2.bitwise_or(all_masks, full_mask)
                all_distances[y1:y2, x1:x2] = np.maximum(all_distances[y1:y2, x1:x2], distances_lab)
                
                cv2.rectangle(result_img, (x1, y1), (x2, y2), (0, 255, 0), 2)
                
                disease_pixels = np.count_nonzero(disease_mask)
                disease_percentage = (disease_pixels / total_leaf_pixels) * 100
                
                disease_info.append({
                    'name': disease_name,
                    'confidence': float(confidence),
                    'pixels': int(disease_pixels),
                    'percentage': float(disease_percentage)
                })
                
                label = f"{disease_name}: {disease_percentage:.1f}%"
                cv2.putText(result_img, label, (x1, y1-10), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
        else:
            # Fallback: simple green exclusion
            for i, box in enumerate(boxes.xyxy.cpu().numpy()):
                x1, y1, x2, y2 = map(int, box)
                
                class_id = int(boxes.cls[i].item())
                confidence = boxes.conf[i].item()
                disease_name = self.class_names[class_id]
                
                roi_hsv = img_hsv[y1:y2, x1:x2]
                black_mask_roi = cv2.inRange(roi_hsv, lower_black, upper_black)
                
                mask_green = cv2.inRange(roi_hsv, lower_green, upper_green)
                disease_mask = cv2.bitwise_not(mask_green)
                disease_mask[black_mask_roi > 0] = 0
                
                kernel = np.ones((3, 3), np.uint8)
                disease_mask = cv2.morphologyEx(disease_mask, cv2.MORPH_CLOSE, kernel, iterations=2)
                disease_mask = cv2.medianBlur(disease_mask, 5)
                
                full_mask = np.zeros(img_rgb.shape[:2], dtype=np.uint8)
                full_mask[y1:y2, x1:x2] = disease_mask
                all_masks = cv2.bitwise_or(all_masks, full_mask)
                
                cv2.rectangle(result_img, (x1, y1), (x2, y2), (0, 255, 0), 2)
                
                disease_pixels = np.count_nonzero(disease_mask)
                disease_percentage = (disease_pixels / total_leaf_pixels) * 100
                
                disease_info.append({
                    'name': disease_name,
                    'confidence': float(confidence),
                    'pixels': int(disease_pixels),
                    'percentage': float(disease_percentage)
                })
                
                label = f"{disease_name}: {disease_percentage:.1f}%"
                cv2.putText(result_img, label, (x1, y1-10), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
        
        total_disease_pixels = np.count_nonzero(all_masks)
        total_disease_percentage = (total_disease_pixels / total_leaf_pixels) * 100
        
        return {
            'result_img': result_img,
            'disease_mask': all_masks,
            'distance_heatmap': all_distances,
            'total_leaf_pixels': int(total_leaf_pixels),
            'total_disease_pixels': int(total_disease_pixels),
            'total_disease_percentage': float(total_disease_percentage),
            'disease_info': disease_info,
            'black_mask': black_mask
        }

# ============================================================================
# COMPLETE PIPELINE
# ============================================================================
class GrapeLeafPipeline:
    """Complete grape leaf disease detection pipeline"""
    
    def __init__(self, yolo_leaf_path, sam_path, patchcore_path, yolo_disease_path):
        self.leaf_extractor = LeafExtractor(yolo_leaf_path, sam_path)
        self.anomaly_detector = PatchCoreInference(patchcore_path)
        self.disease_segmenter = DiseaseSegmenter(yolo_disease_path)
        
        os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    def process_image(self, img_path, visualize=True):
        """Process single image through complete pipeline"""
        print(f"\n{'='*70}")
        print(f"Processing: {os.path.basename(img_path)}")
        print(f"{'='*70}")
        
        # Step 1: Extract leaves
        print("\n📍 Step 1: Extracting leaves...")
        leaves = self.leaf_extractor.extract_leaves(img_path)
        print(f"   Found {len(leaves)} leaves")
        
        if len(leaves) == 0:
            print("❌ No leaves detected!")
            return None
        
        results = []
        
        # Process each leaf
        for i, leaf_data in enumerate(leaves):
            print(f"\n🍃 Processing Leaf {i+1}/{len(leaves)}...")
            
            # Step 2: Anomaly detection
            print("   📊 Running anomaly detection...")
            anomaly_result = self.anomaly_detector.predict(leaf_data['image'])
            print(f"      {anomaly_result['prediction']} (Score: {anomaly_result['anomaly_score']:.4f}, Confidence: {anomaly_result['confidence']:.1f}%)")
            
            # Step 3: Disease segmentation (only if diseased)
            disease_result = None
            if anomaly_result['is_diseased']:
                print("   🔬 Analyzing disease regions...")
                disease_result = self.disease_segmenter.segment_diseases(leaf_data['image'])
                
                if disease_result:
                    print(f"      Total disease coverage: {disease_result['total_disease_percentage']:.2f}%")
                    for disease in disease_result['disease_info']:
                        print(f"      - {disease['name']}: {disease['percentage']:.2f}% (conf: {disease['confidence']:.1%})")
            
            results.append({
                'leaf_index': i,
                'leaf_image': leaf_data['image'],
                'anomaly_result': anomaly_result,
                'disease_result': disease_result
            })
        
        # Visualization
        if visualize:
            self._visualize_results(img_path, results)
        
        return results
    
    def _visualize_results(self, img_path, results):
        """Create comprehensive visualization"""
        n_leaves = len(results)
        
        for i, result in enumerate(results):
            anomaly = result['anomaly_result']
            disease = result['disease_result']
            
            if disease is None:
                # Simple visualization for healthy leaves
                fig, ax = plt.subplots(1, 1, figsize=(8, 8))
                leaf_rgb = cv2.cvtColor(result['leaf_image'], cv2.COLOR_BGR2RGB)
                ax.imshow(leaf_rgb)
                ax.axis('off')
                
                color = 'red' if anomaly['is_diseased'] else 'green'
                title = f"Leaf {i+1} - {anomaly['prediction']}\n"
                title += f"Anomaly Score: {anomaly['anomaly_score']:.4f}\n"
                title += f"Confidence: {anomaly['confidence']:.1f}%"
                ax.set_title(title, fontsize=12, fontweight='bold', color=color)
                
                plt.tight_layout()
                plt.show()
            else:
                # Detailed visualization for diseased leaves
                fig = plt.figure(figsize=(18, 12))
                gs = fig.add_gridspec(2, 3, hspace=0.3, wspace=0.3)
                
                leaf_rgb = cv2.cvtColor(result['leaf_image'], cv2.COLOR_BGR2RGB)
                
                # Detection result
                ax1 = fig.add_subplot(gs[0, 0])
                ax1.imshow(disease['result_img'])
                ax1.set_title(f"Leaf {i+1} - Disease Detection", fontweight='bold')
                ax1.axis('off')
                
                # Disease mask
                ax2 = fig.add_subplot(gs[0, 1])
                ax2.imshow(disease['disease_mask'], cmap='hot')
                ax2.set_title("Disease Segmentation Mask", fontweight='bold')
                ax2.axis('off')
                
                # Overlay
                ax3 = fig.add_subplot(gs[0, 2])
                overlay = leaf_rgb.copy()
                colored_mask = np.zeros_like(leaf_rgb)
                colored_mask[disease['disease_mask'] > 0] = [255, 0, 0]
                overlay = cv2.addWeighted(overlay, 0.7, colored_mask, 0.3, 0)
                ax3.imshow(overlay)
                ax3.set_title("Disease Overlay (Red)", fontweight='bold')
                ax3.axis('off')
                
                # Diseased only
                ax4 = fig.add_subplot(gs[1, 0])
                diseased_only = leaf_rgb.copy()
                diseased_only[disease['disease_mask'] == 0] = [255, 255, 255]
                ax4.imshow(diseased_only)
                ax4.set_title("Diseased Regions Only", fontweight='bold')
                ax4.axis('off')
                
                # Heatmap
                ax5 = fig.add_subplot(gs[1, 1])
                heatmap = disease['distance_heatmap'].copy()
                heatmap[disease['black_mask'] > 0] = 0
                im = ax5.imshow(heatmap, cmap='jet')
                ax5.set_title("Color Distance Heatmap", fontweight='bold')
                ax5.axis('off')
                plt.colorbar(im, ax=ax5, fraction=0.046)
                
                # Report
                ax6 = fig.add_subplot(gs[1, 2])
                ax6.axis('off')
                
                report = f"LEAF {i+1} ANALYSIS\n{'='*30}\n\n"
                report += f"Anomaly Score: {anomaly['anomaly_score']:.4f}\n"
                report += f"Confidence: {anomaly['confidence']:.1f}%\n\n"
                report += f"Leaf Area: {disease['total_leaf_pixels']:,} px\n"
                report += f"Disease Area: {disease['total_disease_pixels']:,} px\n"
                report += f"Coverage: {disease['total_disease_percentage']:.2f}%\n\n"
                report += f"{'-'*30}\n\nDetected Diseases:\n\n"
                
                for j, d in enumerate(disease['disease_info'], 1):
                    report += f"{j}. {d['name']}\n"
                    report += f"   Conf: {d['confidence']:.1%}\n"
                    report += f"   Area: {d['percentage']:.2f}%\n\n"
                
                ax6.text(0.05, 0.95, report, transform=ax6.transAxes,
                        fontsize=9, verticalalignment='top',
                        fontfamily='monospace',
                        bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.8))
                
                plt.suptitle(f'Leaf {i+1} - Complete Disease Analysis', 
                            fontsize=14, fontweight='bold')
                plt.show()

# ============================================================================
# MAIN FUNCTION
# ============================================================================
def main():
    parser = argparse.ArgumentParser(description='Complete Grape Leaf Disease Detection Pipeline')
    parser.add_argument('--image', type=str, help='Path to single image')
    parser.add_argument('--folder', type=str, help='Path to folder with images')
    parser.add_argument('--yolo-leaf', type=str, default=YOLO_LEAF_MODEL, help='Leaf detection model')
    parser.add_argument('--sam', type=str, default=SAM_MODEL, help='SAM model')
    parser.add_argument('--patchcore', type=str, default=PATCHCORE_MODEL, help='PatchCore model')
    parser.add_argument('--yolo-disease', type=str, default=YOLO_DISEASE_MODEL, help='Disease detection model')
    parser.add_argument('--no-viz', action='store_true', help='Disable visualization')
    parser.add_argument('--workers', type=int, default=4, help='Number of workers')
    
    args = parser.parse_args()
    
    # Initialize pipeline
    print("\n" + "="*70)
    print("GRAPE LEAF DISEASE DETECTION PIPELINE")
    print("="*70)
    
    pipeline = GrapeLeafPipeline(
        args.yolo_leaf,
        args.sam,
        args.patchcore,
        args.yolo_disease
    )
    
    print("\n✅ Pipeline initialized successfully!\n")
    
    # Process single image
    if args.image:
        if not os.path.exists(args.image):
            print(f"❌ Image not found: {args.image}")
            return
        
        results = pipeline.process_image(args.image, visualize=not args.no_viz)
        
        if results:
            print(f"\n{'='*70}")
            print("SUMMARY")
            print(f"{'='*70}")
            for r in results:
                print(f"\nLeaf {r['leaf_index']+1}:")
                print(f"  Status: {r['anomaly_result']['prediction']}")
                print(f"  Confidence: {r['anomaly_result']['confidence']:.1f}%")
                if r['disease_result']:
                    print(f"  Disease Coverage: {r['disease_result']['total_disease_percentage']:.2f}%")
    
    # Process folder
    elif args.folder:
        if not os.path.exists(args.folder):
            print(f"❌ Folder not found: {args.folder}")
            return
        
        image_paths = []
        for ext in ['.jpg', '.jpeg', '.png', '.JPG', '.JPEG', '.PNG']:
            image_paths.extend(Path(args.folder).glob(f'*{ext}'))
        
        if not image_paths:
            print(f"❌ No images found in {args.folder}")
            return
        
        print(f"Found {len(image_paths)} images\n")
        
        for img_path in image_paths:
            pipeline.process_image(str(img_path), visualize=not args.no_viz)
    
    else:
        print("Please specify --image or --folder")
        print("\nExamples:")
        print("  python complete_pipeline.py --image test.jpg")
        print("  python complete_pipeline.py --folder test_images/")

if __name__ == "__main__":
    main()