import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/dto/update_report_request.dart';
import '../../../../core/di/di_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/bordered_card.dart';
import '../../../../shared/widgets/standard_button.dart';
import '../../../../shared/widgets/standard_text_field.dart';
import '../../../../shared/widgets/authenticated_app_bar.dart';
import '../../../../core/theme/spacing.dart';

class ReportEditorScreen extends StatefulWidget {
  final String requestId;

  const ReportEditorScreen({super.key, required this.requestId});

  @override
  State<ReportEditorScreen> createState() => _ReportEditorScreenState();
}

class _ReportEditorScreenState extends State<ReportEditorScreen> {
  final _reportController = TextEditingController();
  bool _isLoading = false;
  Dio? _dio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dio == null) {
      final dioClient = DiProvider.getDioClient(context);
      _dio = dioClient.dio;
      _loadReport();
    }
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    if (_dio == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await _dio!.get('${ApiConstants.requests}/${widget.requestId}/report');
      final report = response.data['report'] as String?;
      if (report != null) {
        _reportController.text = report;
      }
    } catch (e) {
      debugPrint('Error loading report: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveReport() async {
    if (_dio == null) return;

    final authProvider = AuthProvider.of(context);
    if (authProvider?.user?.role != UserRole.admin) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = UpdateReportRequest(report: _reportController.text);
      await _dio!.put(
        '${ApiConstants.admin}/requests/${widget.requestId}/report',
        data: {
          'report': request.report,
        },
      );
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => const Alert(
            title: Text('Success'),
            content: Text('Report saved'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => Alert.destructive(
            title: const Text('Error'),
            content: Text('Error: $e'),
            trailing: IconButton.ghost(
              icon: const Icon(LucideIcons.x),
              onPressed: overlay.close,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context);
    if (authProvider?.user?.role != UserRole.admin) {
      return const Scaffold(
      backgroundColor: Colors.transparent,
        headers: [AuthenticatedAppBar(title: 'Edit Report')],
        child: Center(child: Text('Admin access required')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      headers: const [AuthenticatedAppBar(title: 'Edit Report')],
          child: _isLoading && _reportController.text.isEmpty
            ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BorderedCard(
                    child: StandardTextField(
                      label: 'Report (Markdown)',
                      controller: _reportController,
                      maxLines: 20,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: StandardButton(
                      text: _isLoading ? 'Saving...' : 'Save Report',
                      onPressed: _isLoading ? null : _saveReport,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
 
