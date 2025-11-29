class CreateRequestRequest {
  final String farmId;

  const CreateRequestRequest({
    required this.farmId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateRequestRequest && other.farmId == farmId;
  }

  @override
  int get hashCode => farmId.hashCode;
}

