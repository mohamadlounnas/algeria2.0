import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/di/dio_client.dart';
import 'core/di/di_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/farms/presentation/providers/farm_provider.dart';
import 'features/requests/presentation/providers/request_provider.dart';
import 'core/routing/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create single Dio client instance
    final dioClient = DioClient();

    return DiProvider(
      dioClient: dioClient,
      child: AuthProviderState(
        child: FarmProviderState(
          child: RequestProviderState(
            child: ShadcnApp(
              title: 'Farm Disease Detection',
              // theme: AppTheme.shadcnTheme,
              navigatorKey: AppRouter.navigatorKey,
              onGenerateRoute: AppRouter.onGenerateRoute,
              initialRoute: AppRoutes.splash,
            ),
          ),
        ),
      ),
    );
  }
}
