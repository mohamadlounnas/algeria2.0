import 'package:flutter/material.dart' hide ThemeData, ThemeMode, Colors;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/di/dio_client.dart';
import 'core/di/di_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/farms/presentation/providers/farm_provider.dart';
import 'features/requests/presentation/providers/request_provider.dart';
import 'core/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dioClient = DioClient();
  await dioClient.loadBaseUrl();

  runApp(MyApp(dioClient: dioClient));
}

class MyApp extends StatelessWidget {
  final DioClient dioClient;

  const MyApp({super.key, required this.dioClient});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(

      decoration: BoxDecoration(
        // https://i.pinimg.com/736x/82/18/7c/82187cd1e8ea3a9070a546406e7729c4.jpg
        // image: DecorationImage(
          // image: const NetworkImage("https://i.pinimg.com/736x/82/18/7c/82187cd1e8ea3a9070a546406e7729c4.jpg"),
          // fit: BoxFit.cover,
          // colorFilter: ColorFilter.mode(
          //   Colors.black.withOpacity(0.6),
          //   BlendMode.darken,
          // ),
        // ),
        color: Colors.white
      ),
      child: DiProvider(
        dioClient: dioClient,
        child: AuthProviderState(
          child: FarmProviderState(
            child: RequestProviderState(
              child: ShadcnApp(
                title: 'Farm Disease Detection',
                theme: ThemeData(),
                darkTheme: ThemeData.dark(
                  // make sacfold transparent in dark mode
                   
                ),
                themeMode: ThemeMode.light,
                navigatorKey: AppRouter.navigatorKey,
                onGenerateRoute: AppRouter.onGenerateRoute,
                initialRoute: AppRoutes.splash,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
