import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dio/dio.dart';
import '../providers/request_provider.dart';
import '../../domain/entities/request.dart';
import '../../data/repositories/request_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/di/di_provider.dart';
import '../widgets/disease_map_view.dart';
import '../widgets/disease_list_view.dart';
import '../../../../core/routing/app_router.dart';

class RequestResultsScreen extends StatefulWidget {
  final String requestId;

  const RequestResultsScreen({super.key, required this.requestId});

  @override
  State<RequestResultsScreen> createState() => _RequestResultsScreenState();
}

class _RequestResultsScreenState extends State<RequestResultsScreen> {
  bool _isLoading = false;
  RequestRepositoryImpl? _requestRepository;
  Dio? _dio;
  Request? _request;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dio == null) {
      final dioClient = DiProvider.getDioClient(context);
      _dio = dioClient.dio;
      _requestRepository = RequestRepositoryImpl(dio: _dio!);
      _loadRequestIfNeeded();
    }
  }

  Future<void> _loadRequestIfNeeded() async {
    final provider = RequestProvider.of(context);
    Request? existing;
    if (provider != null) {
      try {
        existing = provider.requests.firstWhere(
          (r) => r.id == widget.requestId,
        );
      } catch (_) {
        existing = null;
      }
    }

    if (existing != null && existing.images.isNotEmpty) {
      if (mounted) {
        setState(() => _request = existing);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      Request? fetched;
      if (provider?.fetchRequest != null) {
        fetched = await provider!.fetchRequest!(widget.requestId);
      } else if (_requestRepository != null) {
        fetched = await _requestRepository!.getRequestById(widget.requestId);
      }
      if (mounted) {
        setState(() => _request = fetched ?? existing);
      }
    } catch (e) {
      debugPrint('Error loading request: $e');
      if (mounted && existing != null) {
        setState(() => _request = existing);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = RequestProvider.of(context);
    Request? request = _request;
    if (request == null && provider != null) {
      try {
        request = provider.requests.firstWhere((r) => r.id == widget.requestId);
      } catch (_) {
        request = null;
      }
    }

    if (_isLoading) {
      return const Scaffold(
      backgroundColor: Colors.transparent,child: Center(child: CircularProgressIndicator()));
    }

    if (request == null) {
      return Scaffold(
      backgroundColor: Colors.transparent,
        headers: [
          AppBar(
            title: const Text('Request Results'),
            trailing: [
              IconButton.ghost(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final authProvider = AuthProvider.of(context);
                  await authProvider?.signOut?.call();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
        child: const Center(child: Text('Request not found')),
      );
    }

    return m.DefaultTabController(
      length: 3,
      child: Scaffold(
      backgroundColor: Colors.transparent,
        headers: [
          AppBar(
            title: const Text('Request Results'),
            trailing: [
              IconButton.ghost(
                icon: const Icon(m.Icons.logout),
                onPressed: () async {
                  final authProvider = AuthProvider.of(context);
                  await authProvider?.signOut?.call();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
        child: Column(
          children: [
            m.TabBar(
              tabs: const [
                m.Tab(text: 'Map'),
                m.Tab(text: 'Diseases'),
                m.Tab(text: 'Report'),
              ],
            ),
            Expanded(
              child: m.TabBarView(
                children: [
                  DiseaseMapView(images: request.images),
                  DiseaseListView(images: request.images),
                  request.finalReport != null && request.finalReport!.isNotEmpty
                      ? Markdown(data: request.finalReport!)
                      : const Center(child: Text('No report available')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
