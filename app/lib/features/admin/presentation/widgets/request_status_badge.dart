import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../requests/domain/entities/request.dart';

class RequestStatusBadge extends StatelessWidget {
  final RequestStatus status;

  const RequestStatusBadge({super.key, required this.status});

  Color get _statusColor {
    switch (status) {
      case RequestStatus.draft:
        return AppColors.draft;
      case RequestStatus.pending:
        return AppColors.pending;
      case RequestStatus.accepted:
        return AppColors.accepted;
      case RequestStatus.processing:
        return AppColors.processing;
      case RequestStatus.processed:
        return AppColors.processed;
      case RequestStatus.completed:
        return AppColors.completed;
    }
  }
  
  String get _statusText {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _statusColor, width: 1),
      ),
      child: Text(
        _statusText,
        style: TextStyle(
          color: _statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

