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
    // إذا لم توجد صور، ضع نقاط عشوائية داخل حدود الجزائر مؤقتاً
    final List<LatLng> randomPoints = images.isEmpty
        ? List.generate(5, (i) => LatLng(36.7 + i * 0.01, 3.1 + i * 0.01))
        : images.map((img) => LatLng(img.latitude, img.longitude)).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: randomPoints.isNotEmpty ? randomPoints.first : LatLng(36.7, 3.1),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.dowa',
        ),
        MarkerLayer(
          markers: randomPoints.map((point) {
            return Marker(
              point: point,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

