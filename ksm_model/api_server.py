#!/usr/bin/env python3
"""
Grape Leaf Disease Detection API Server
Provides REST API endpoint for disease detection via image URL
Accessible over local network for other devices
"""

import os
import sys
import json
import time
import socket
import threading
import requests
import tempfile
import cv2
from datetime import datetime
from urllib.parse import urlparse, parse_qs
from pathlib import Path

# Add current directory to Python path for imports
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(current_dir)

# Import disease detection modules
try:
    from disease_pipeline import GrapeLeafPipeline
    print("✅ Disease detection pipeline loaded")
except ImportError as e:
    print(f"❌ Failed to import disease pipeline: {e}")
    print("   Make sure disease_pipeline.py is in the same directory")
    sys.exit(1)

class DiseaseDetectionAPI:
    """API server for grape leaf disease detection"""
    
    def __init__(self, host='0.0.0.0', port=8888):
        self.host = host
        self.port = port
        self.server_socket = None
        self.running = False
        
        # Static files directory
        self.static_dir = os.path.join(current_dir, 'static')
        os.makedirs(self.static_dir, exist_ok=True)
        
        # Counter for unique filenames
        self.image_counter = 0
        self.counter_lock = threading.Lock()
        
        # Initialize disease detection pipeline
        try:
            # Model file paths (all in current directory)
            models = {
                'yolo_leaf': os.path.join(current_dir, 'yolo_leaf_detection.pt'),
                # 'sam': os.path.join(current_dir, 'sam2.1_l.pt'),
                'sam': os.path.join(current_dir, 'mobile_sam.pt'),
                'patchcore': os.path.join(current_dir, 'patchcore_anomaly.pth'),
                'yolo_disease': os.path.join(current_dir, 'yolo_disease_detection.pt')
            }
            
            print(f"📂 Model directory: {current_dir}")
            print("📦 Initializing AI models...")
            
            self.detector = GrapeLeafPipeline(
                models['yolo_leaf'],
                models['sam'],
                models['patchcore'],
                models['yolo_disease']
            )
            print("✅ All models loaded successfully")
        except FileNotFoundError as e:
            print(f"❌ Model file not found: {e}")
            print("   Please ensure all .pt and .pth files are in the directory")
            sys.exit(1)
        except Exception as e:
            print(f"❌ Failed to initialize detection pipeline: {e}")
            sys.exit(1)
    
    def start_server(self):
        """Start the API server"""
        try:
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.bind((self.host, self.port))
            self.server_socket.listen(10)
            self.running = True
            
            print(f"🌐 Disease Detection API Server started")
            print(f"📡 Listening on {self.host}:{self.port}")
            print(f"🔗 API Endpoint: http://{self.get_local_ip()}:{self.port}/api/process?url=<url>")
            print(f"🔗 Bulk Endpoint: http://{self.get_local_ip()}:{self.port}/api/process?urls=<url1,url2,url3>")
            print(f"📱 Accessible from other devices on local network")
            print("-" * 60)
            
            while self.running:
                try:
                    client_socket, addr = self.server_socket.accept()
                    print(f"📱 Request from {addr[0]}")
                    
                    # Handle client in separate thread
                    client_thread = threading.Thread(
                        target=self.handle_request,
                        args=(client_socket, addr)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                except Exception as e:
                    if self.running:
                        print(f"❌ Server error: {e}")
                        
        except Exception as e:
            print(f"❌ Failed to start server: {e}")
        finally:
            self.cleanup()
    
    def handle_request(self, client_socket, addr):
        """Handle HTTP requests"""
        try:
            # Receive HTTP request
            request = client_socket.recv(4096).decode('utf-8')
            
            if not request:
                return
            
            # Parse HTTP request
            lines = request.split('\n')
            if not lines:
                return
                
            request_line = lines[0].strip()
            method, path, _ = request_line.split(' ', 2)
            
            print(f"📝 {method} {path}")
            
            # Handle different endpoints
            if method == 'GET' and path == '/':
                self.handle_home_page(client_socket)
            elif method == 'GET' and path.startswith('/api/process'):
                self.handle_disease_detection(client_socket, path)
            elif method == 'GET' and path.startswith('/static/'):
                self.handle_static_file(client_socket, path)
            elif method == 'OPTIONS':
                self.send_cors_response(client_socket)
            else:
                self.send_error_response(client_socket, 404, "Endpoint not found")
                
        except Exception as e:
            print(f"❌ Request handling error: {e}")
            self.send_error_response(client_socket, 500, str(e))
        finally:
            client_socket.close()
    
    def handle_disease_detection(self, client_socket, path):
        """Handle disease detection API request"""
        try:
            # Parse query parameters
            if '?' not in path:
                self.send_error_response(client_socket, 400, "Missing url or urls parameter")
                return
            
            query_string = path.split('?', 1)[1]
            params = parse_qs(query_string)
            
            # Check for bulk processing (urls parameter)
            if 'urls' in params:
                urls_param = params['urls'][0]
                image_urls = [url.strip() for url in urls_param.split(',') if url.strip()]
                
                if not image_urls:
                    self.send_error_response(client_socket, 400, "No valid URLs provided in urls parameter")
                    return
                
                print(f"🖼️ Processing {len(image_urls)} images in bulk")
                results = self.process_bulk_images(image_urls)
                
            # Check for single processing (url parameter)
            elif 'url' in params:
                image_url = params['url'][0]
                print(f"🖼️ Processing single image: {image_url}")
                
                # Download image
                temp_image_path = self.download_image(image_url)
                if not temp_image_path:
                    self.send_error_response(client_socket, 400, "Failed to download image")
                    return
                
                # Detect diseases
                results = self.detect_diseases(temp_image_path)
                
                # Clean up temp file (only if it's a downloaded temp file, not a local file)
                try:
                    parsed = urlparse(image_url)
                    if parsed.scheme != 'file' and temp_image_path.startswith(tempfile.gettempdir()):
                        os.remove(temp_image_path)
                except:
                    pass
                    
            else:
                self.send_error_response(client_socket, 400, "Missing url or urls parameter")
                return
            
            # Send JSON response
            self.send_json_response(client_socket, results)
            
            if isinstance(results, list):
                print(f"✅ Bulk processed {len(results)} images successfully")
            else:
                leaf_count = len(results.get('leafs', []))
                print(f"✅ Processed successfully - Found {leaf_count} leaf/leaves")
            
        except ValueError as e:
            # No leaves detected - return 404
            print(f"⚠️ No leaves detected: {e}")
            self.send_error_response(client_socket, 404, str(e))
        except Exception as e:
            print(f"❌ Disease detection error: {e}")
            self.send_error_response(client_socket, 500, str(e))
    
    def handle_home_page(self, client_socket):
        """Serve the HTML home page"""
        try:
            index_path = os.path.join(self.static_dir, 'index.html')
            
            if not os.path.exists(index_path):
                self.send_error_response(client_socket, 404, "Home page not found")
                return
            
            with open(index_path, 'r', encoding='utf-8') as f:
                html_content = f.read()
            
            response = f"""HTTP/1.1 200 OK\r
Content-Type: text/html; charset=utf-8\r
Content-Length: {len(html_content.encode('utf-8'))}\r
Access-Control-Allow-Origin: *\r
\r
"""
            client_socket.send(response.encode('utf-8'))
            client_socket.send(html_content.encode('utf-8'))
            
        except Exception as e:
            print(f"❌ Home page error: {e}")
            self.send_error_response(client_socket, 500, str(e))
    
    def handle_static_file(self, client_socket, path):
        """Serve static files (images)"""
        try:
            # Extract filename from path
            filename = path.split('/static/', 1)[1]
            file_path = os.path.join(self.static_dir, filename)
            
            # Check if file exists
            if not os.path.exists(file_path):
                self.send_error_response(client_socket, 404, "File not found")
                return
            
            # Read file
            with open(file_path, 'rb') as f:
                file_data = f.read()
            
            # Determine content type
            content_type = 'image/jpeg'
            if filename.endswith('.png'):
                content_type = 'image/png'
            elif filename.endswith('.gif'):
                content_type = 'image/gif'
            elif filename.endswith('.bmp'):
                content_type = 'image/bmp'
            
            # Send response
            response = f"""HTTP/1.1 200 OK\r
Content-Type: {content_type}\r
Content-Length: {len(file_data)}\r
Access-Control-Allow-Origin: *\r
Cache-Control: public, max-age=3600\r
\r
"""
            client_socket.send(response.encode())
            client_socket.send(file_data)
            
        except Exception as e:
            print(f"❌ Static file error: {e}")
            self.send_error_response(client_socket, 500, str(e))
    
    def download_image(self, image_url):
        """Download image from URL or load from local file:// path"""
        try:
            # Validate URL
            parsed = urlparse(image_url)
            
            # Handle file:// URLs (local files)
            if parsed.scheme == 'file':
                # Convert file URL to local path
                local_path = parsed.path
                
                # On Windows, file URLs look like: file:///C:/path/to/file.jpg
                # We need to remove the leading slash and handle the drive letter
                if local_path.startswith('/') and len(local_path) > 2 and local_path[2] == ':':
                    local_path = local_path[1:]  # Remove leading slash: /C:/... -> C:/...
                
                # Convert forward slashes to backslashes on Windows
                local_path = local_path.replace('/', os.sep)
                
                # Check if file exists
                if not os.path.exists(local_path):
                    print(f"❌ Local file not found: {local_path}")
                    return None
                
                # Verify it's an image file
                valid_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp']
                if not any(local_path.lower().endswith(ext) for ext in valid_extensions):
                    print(f"❌ Not a valid image file: {local_path}")
                    return None
                
                print(f"📂 Using local file: {local_path}")
                return local_path
            
            # Handle HTTP/HTTPS URLs
            if not parsed.scheme or not parsed.netloc:
                print(f"❌ Invalid URL: {image_url}")
                return None
            
            # Download image
            response = requests.get(image_url, timeout=30, stream=True)
            response.raise_for_status()
            
            # Check content type
            content_type = response.headers.get('content-type', '').lower()
            if not content_type.startswith('image/'):
                print(f"❌ Not an image: {content_type}")
                return None
            
            # Save to temporary file
            suffix = '.jpg'
            if 'png' in content_type:
                suffix = '.png'
            elif 'gif' in content_type:
                suffix = '.gif'
            elif 'bmp' in content_type:
                suffix = '.bmp'
            
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
            for chunk in response.iter_content(chunk_size=8192):
                temp_file.write(chunk)
            temp_file.close()
            
            print(f"📥 Downloaded image to: {temp_file.name}")
            return temp_file.name
            
        except Exception as e:
            print(f"❌ Download error: {e}")
            return None
    
    def detect_diseases(self, image_path):
        """Detect diseases in image and return results"""
        try:
            # Use the grape leaf pipeline
            detection_results = self.detector.process_image(image_path, visualize=False)
            
            # Check if detection returned valid results
            if detection_results is None or len(detection_results) == 0:
                print("⚠️ No leaves detected in image")
                raise ValueError("No grape leaves detected in the image")
            
            # Format results leaf by leaf
            leafs = []
            total_diseased = 0
            total_healthy = 0
            
            for leaf_result in detection_results:
                anomaly_result = leaf_result.get('anomaly_result', {})
                disease_result = leaf_result.get('disease_result', None)
                
                # Build diseases dictionary for this leaf
                diseases = {}
                
                # Check if leaf is diseased
                is_diseased = anomaly_result.get('is_diseased', False)
                
                if is_diseased:
                    total_diseased += 1
                    
                    # Add specific disease information if available
                    if disease_result and 'disease_info' in disease_result:
                        for disease_info in disease_result['disease_info']:
                            disease_name = disease_info.get('name', 'unknown_disease')
                            confidence = disease_info.get('confidence', 0.0)
                            diseases[disease_name] = float(confidence)
                    else:
                        # Generic diseased classification
                        anomaly_confidence = anomaly_result.get('confidence', 80.0) / 100.0
                        diseases['diseased'] = float(anomaly_confidence)
                else:
                    total_healthy += 1
                    diseases['healthy'] = float(anomaly_result.get('confidence', 95.0) / 100.0)
                
                # Save leaf image to static directory
                with self.counter_lock:
                    self.image_counter += 1
                    leaf_filename = f"leaf_{self.image_counter}_{int(time.time() * 1000)}.jpg"
                    heatmap_filename = f"heatmap_{self.image_counter}_{int(time.time() * 1000)}.jpg"
                    overlay_filename = f"overlay_{self.image_counter}_{int(time.time() * 1000)}.jpg"
                
                leaf_image = leaf_result.get('leaf_image')
                leaf_path = os.path.join(self.static_dir, leaf_filename)
                cv2.imwrite(leaf_path, leaf_image)
                
                # Generate static URL
                base_url = f"http://{self.get_local_ip()}:{self.port}"
                leaf_url = f"{base_url}/static/{leaf_filename}"
                
                # Save heatmap and overlay if available
                heatmap_url = None
                overlay_url = None
                if anomaly_result.get('heatmap') is not None:
                    heatmap = anomaly_result['heatmap']
                    heatmap_path = os.path.join(self.static_dir, heatmap_filename)
                    cv2.imwrite(heatmap_path, heatmap)
                    heatmap_url = f"{base_url}/static/{heatmap_filename}"
                    
                    # Create overlay (blend leaf image with heatmap)
                    overlay = cv2.addWeighted(leaf_image, 0.6, heatmap, 0.4, 0)
                    overlay_path = os.path.join(self.static_dir, overlay_filename)
                    cv2.imwrite(overlay_path, overlay)
                    overlay_url = f"{base_url}/static/{overlay_filename}"
                
                leafs.append({
                    "image": leaf_url,
                    "heatmap": heatmap_url,
                    "overlay": overlay_url,
                    "diseases": diseases,
                    "anomaly_score": float(anomaly_result.get('anomaly_score', 0.0)),
                    "is_diseased": bool(is_diseased)
                })
            
            # Build final response
            result = {
                "leafs": leafs,
                "summary": {
                    "total_leafs": int(len(leafs)),
                    "diseased_leafs": int(total_diseased),
                    "healthy_leafs": int(total_healthy)
                },
                "timestamp": datetime.now().isoformat(),
                "image_processed": True
            }
            
            return result
            
        except ValueError as e:
            # Re-raise ValueError for no leaves detected
            raise
        except Exception as e:
            print(f"❌ Detection error: {e}")
            raise Exception(f"Detection error: {str(e)}")

    
    def process_bulk_images(self, image_urls):
        """Process multiple images and return array of results"""
        results = []
        
        for i, image_url in enumerate(image_urls, 1):
            print(f"📸 Processing image {i}/{len(image_urls)}: {image_url}")
            
            try:
                # Download image
                temp_image_path = self.download_image(image_url)
                
                if temp_image_path:
                    try:
                        # Detect diseases
                        result = self.detect_diseases(temp_image_path)
                        result['image_url'] = image_url
                        result['processing_index'] = i
                        
                        # Clean up temp file (only if it's a downloaded temp file, not a local file)
                        try:
                            parsed = urlparse(image_url)
                            if parsed.scheme != 'file' and temp_image_path.startswith(tempfile.gettempdir()):
                                os.remove(temp_image_path)
                        except:
                            pass
                            
                        results.append(result)
                        leaf_count = len(result.get('leafs', []))
                        print(f"   ✅ Completed {i}/{len(image_urls)} - {leaf_count} leaf/leaves")
                    except ValueError as e:
                        # No leaves detected
                        error_result = {
                            "error": str(e),
                            "timestamp": datetime.now().isoformat(),
                            "image_processed": False,
                            "image_url": image_url,
                            "processing_index": i
                        }
                        results.append(error_result)
                        print(f"   ⚠️ No leaves {i}/{len(image_urls)}: {e}")
                else:
                    # Failed to download
                    error_result = {
                        "error": "Failed to download image",
                        "timestamp": datetime.now().isoformat(),
                        "image_processed": False,
                        "image_url": image_url,
                        "processing_index": i
                    }
                    results.append(error_result)
                    print(f"   ❌ Failed to download {i}/{len(image_urls)}")
                    
            except Exception as e:
                # Processing error
                error_result = {
                    "error": str(e),
                    "timestamp": datetime.now().isoformat(),
                    "image_processed": False,
                    "image_url": image_url,
                    "processing_index": i
                }
                results.append(error_result)
                print(f"   ❌ Error processing {i}/{len(image_urls)}: {e}")
        
        return results
    
    def send_json_response(self, client_socket, data):
        """Send JSON HTTP response"""
        json_data = json.dumps(data, indent=2)
        response = f"""HTTP/1.1 200 OK\r
Content-Type: application/json\r
Content-Length: {len(json_data)}\r
Access-Control-Allow-Origin: *\r
Access-Control-Allow-Methods: GET, OPTIONS\r
Access-Control-Allow-Headers: Content-Type\r
\r
{json_data}"""
        client_socket.send(response.encode())
    
    def send_error_response(self, client_socket, status_code, message):
        """Send error HTTP response"""
        error_data = {
            "error": message,
            "status": status_code,
            "timestamp": datetime.now().isoformat()
        }
        json_data = json.dumps(error_data, indent=2)
        
        response = f"""HTTP/1.1 {status_code} Error\r
Content-Type: application/json\r
Content-Length: {len(json_data)}\r
Access-Control-Allow-Origin: *\r
Access-Control-Allow-Methods: GET, OPTIONS\r
Access-Control-Allow-Headers: Content-Type\r
\r
{json_data}"""
        client_socket.send(response.encode())
    
    def send_cors_response(self, client_socket):
        """Send CORS preflight response"""
        response = """HTTP/1.1 200 OK\r
Access-Control-Allow-Origin: *\r
Access-Control-Allow-Methods: GET, OPTIONS\r
Access-Control-Allow-Headers: Content-Type\r
Content-Length: 0\r
\r
"""
        client_socket.send(response.encode())
    
    def get_local_ip(self):
        """Get local IP address"""
        try:
            # Connect to a remote server to determine local IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "localhost"
    
    def cleanup(self):
        """Clean up server resources"""
        self.running = False
        if self.server_socket:
            try:
                self.server_socket.close()
            except:
                pass
        print("\n🛑 Server stopped")

def main():
    """Main function"""
    print("🍇 Grape Leaf Disease Detection API Server")
    print("=" * 50)
    
    # Default configuration
    host = '0.0.0.0'  # Listen on all interfaces for network access
    port = 8888
    
    # Allow custom port via command line
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("❌ Invalid port number")
            sys.exit(1)
    
    # Create and start server
    api_server = DiseaseDetectionAPI(host, port)
    
    try:
        api_server.start_server()
    except KeyboardInterrupt:
        print("\n⏹️ Shutting down server...")
        api_server.cleanup()

if __name__ == "__main__":
    main()