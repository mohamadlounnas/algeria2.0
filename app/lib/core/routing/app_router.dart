import 'package:flutter/material.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/farms/presentation/screens/farms_list_screen.dart';
import '../../features/farms/presentation/screens/create_farm_screen.dart';
import '../../features/farms/presentation/widgets/farm_scaffold.dart';
import '../../features/requests/presentation/screens/draft_request_screen.dart';
import '../../features/requests/presentation/screens/request_summary_screen.dart';
import '../../features/requests/presentation/screens/request_results_screen.dart';
import '../../features/requests/presentation/screens/request_image_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_requests_list_screen.dart';
import '../../features/admin/presentation/screens/admin_request_detail_screen.dart';
import '../../features/admin/presentation/screens/report_editor_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/requests/domain/entities/request.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const farms = '/farms';
  static const createFarm = '/farms/create';
  static const farmDetail = '/farms/detail';
  static const requestDraft = '/requests/draft';
  static const requestSummary = '/requests/summary';
  static const requestResults = '/requests/results';
  static const requestImageDetail = '/requests/image-detail';
  static const adminRequests = '/admin/requests';
  static const adminRequestDetail = '/admin/requests/detail';
  static const reportEditor = '/admin/requests/report';
  static const profile = '/profile';
}

class FarmDetailArgs {
  final String farmId;
  final int initialTab;

  const FarmDetailArgs({required this.farmId, this.initialTab = 0});
}

class RequestArgs {
  final String requestId;

  const RequestArgs(this.requestId);
}

class RequestImageDetailArgs {
  final String requestId;
  final RequestImage image;
  final RequestStatus requestStatus;

  const RequestImageDetailArgs({
    required this.requestId,
    required this.image,
    required this.requestStatus,
  });
}

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGateScreen(),
        );
      case AppRoutes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case AppRoutes.register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );
      case AppRoutes.farms:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const FarmsListScreen(),
        );
      case AppRoutes.profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileScreen(),
        );
      case AppRoutes.createFarm:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateFarmScreen(),
        );
      case AppRoutes.farmDetail:
        final args = settings.arguments as FarmDetailArgs?;
        if (args == null) {
          return _errorRoute('Missing farm details', settings);
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FarmScaffold(
            farmId: args.farmId,
            initialTab: args.initialTab,
          ),
        );
      case AppRoutes.requestDraft:
        final args = settings.arguments as RequestArgs?;
        if (args == null) return _errorRoute('Missing request id', settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DraftRequestScreen(requestId: args.requestId),
        );
      case AppRoutes.requestSummary:
        final args = settings.arguments as RequestArgs?;
        if (args == null) return _errorRoute('Missing request id', settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RequestSummaryScreen(requestId: args.requestId),
        );
      case AppRoutes.requestResults:
        final args = settings.arguments as RequestArgs?;
        if (args == null) return _errorRoute('Missing request id', settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RequestResultsScreen(requestId: args.requestId),
        );
      case AppRoutes.requestImageDetail:
        final args = settings.arguments as RequestImageDetailArgs?;
        if (args == null) return _errorRoute('Missing request image data', settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RequestImageDetailScreen(
            requestId: args.requestId,
            image: args.image,
            requestStatus: args.requestStatus,
          ),
        );
      case AppRoutes.adminRequests:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRequestsListScreen(),
        );
      case AppRoutes.adminRequestDetail:
        final args = settings.arguments as RequestArgs?;
        if (args == null) return _errorRoute('Missing admin request id', settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AdminRequestDetailScreen(requestId: args.requestId),
        );
      case AppRoutes.reportEditor:
        final args = settings.arguments as RequestArgs?;
        if (args == null) return _errorRoute('Missing request id', settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ReportEditorScreen(requestId: args.requestId),
        );
      default:
        return _errorRoute('Route ${settings.name} not found', settings);
    }
  }

  static MaterialPageRoute _errorRoute(String message, RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
      backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => navigatorKey.currentState?.pushNamedAndRemoveUntil(
                    AppRoutes.farms,
                    (route) => false,
                  ),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool _handled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handled) return;
    final authProvider = AuthProvider.of(context);
    final isInitialized = authProvider?.isInitialized ?? false;
    if (!isInitialized) return;
    _handled = true;
    final isLoggedIn = authProvider?.user != null;
    final target = isLoggedIn ? AppRoutes.farms : AppRoutes.login;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
