import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/request.dart';
import '../../../../core/theme/colors.dart';

class DiseaseMapView extends StatelessWidget {
  final List<RequestImage> images;

  const DiseaseMapView({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final diseasedImages = images.where((img) => img.diseaseType != null).toList();
    
    if (diseasedImages.isEmpty) {
      return const Center(child: Text('No diseases detected'));
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          diseasedImages.first.latitude,
          diseasedImages.first.longitude,
        ),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.dowa',
        ),
        MarkerLayer(
          markers: diseasedImages.map((image) {
            return Marker(
              point: LatLng(image.latitude, image.longitude),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, color: Colors.white, size: 20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

