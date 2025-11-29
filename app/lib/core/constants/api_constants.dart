import 'dart:io';

class ApiConstants {
  // Use 10.0.2.2 for Android emulator (maps to host machine's localhost)
  // Use localhost for iOS simulator and desktop
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3333';
    } else {
      return 'http://localhost:3333';
    }
  }
  
  static const String apiPrefix = '/api';
  
  // Auth
  static String get auth => '$apiPrefix/auth';
  
  // Farms
  static String get farms => '$apiPrefix/farms';
  
  // Requests
  static String get requests => '$apiPrefix/requests';
  
  // Admin
  static String get admin => '$apiPrefix/admin';
}

