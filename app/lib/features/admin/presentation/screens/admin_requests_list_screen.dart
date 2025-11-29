import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../requests/domain/entities/request.dart';
import '../../../requests/data/models/request_model.dart';
import '../../../../core/di/di_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/bordered_card.dart';
import '../../../../shared/widgets/authenticated_app_bar.dart';
import '../../../../shared/widgets/standard_list_tile.dart';
import '../widgets/request_status_badge.dart';

class AdminRequestsListScreen extends StatefulWidget {
  const AdminRequestsListScreen({super.key});

  @override
  State<AdminRequestsListScreen> createState() => _AdminRequestsListScreenState();
}

class _AdminRequestsListScreenState extends State<AdminRequestsListScreen> {
  List<Request> _requests = [];
  bool _isLoading = false;
  RequestStatus? _statusFilter;
  Dio? _dio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dio == null) {
      final dioClient = DiProvider.getDioClient(context);
      _dio = dioClient.dio;
      _loadRequests();
    }
  }

  String _statusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft:
        return 'DRAFT';
      case RequestStatus.pending:
        return 'PENDING';
      case RequestStatus.accepted:
        return 'ACCEPTED';
      case RequestStatus.processing:
        return 'PROCESSING';
      case RequestStatus.processed:
        return 'PROCESSED';
      case RequestStatus.completed:
        return 'COMPLETED';
    }
  }

  Future<void> _loadRequests() async {
    if (_dio == null) return;
    
    setState(() => _isLoading = true);
    try {
      final endpoint = _statusFilter != null
          ? '${ApiConstants.admin}/requests?status=${_statusToString(_statusFilter!)}'
          : '${ApiConstants.admin}/requests';
      final response = await _dio!.get(endpoint);
      final data = response.data;
      final requestsList = data is List ? data : (data['data'] ?? []);
      setState(() {
        _requests = (requestsList as List)
            .map((r) => RequestModel.fromJson(r as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context);
    if (authProvider?.user?.role != UserRole.admin) {
      return Scaffold(
      backgroundColor: Colors.transparent,
        child: const Center(child: Text('Admin access required')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      headers: [
        const AuthenticatedAppBar(title: 'All Requests'),
      ],
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No requests found'))
              : RefreshTrigger(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      return BorderedCard(
                        child: StandardListTile(
                          title: Text('Request #${request.id.substring(0, 8)}'),
                          subtitle: Text('Farm: ${request.farmId.substring(0, 8)}'),
                          trailing: RequestStatusBadge(status: request.status),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.adminRequestDetail,
                              arguments: RequestArgs(request.id),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
