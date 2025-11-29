import 'package:flutter/material.dart';
import 'dio_client.dart';

class DiProvider extends InheritedWidget {
  final DioClient dioClient;

  const DiProvider({
    super.key,
    required this.dioClient,
    required super.child,
  });

  static DiProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DiProvider>();
  }

  static DioClient getDioClient(BuildContext context) {
    final provider = of(context);
    if (provider == null) {
      throw Exception('DiProvider not found in widget tree');
    }
    return provider.dioClient;
  }

  @override
  bool updateShouldNotify(DiProvider oldWidget) {
    return dioClient != oldWidget.dioClient;
  }
}

