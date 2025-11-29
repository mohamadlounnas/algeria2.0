class UpdateRequestRequest {
  final String? note;
  final bool? expertIntervention;

  const UpdateRequestRequest({
    this.note,
    this.expertIntervention,
  });

  bool get isEmpty => note == null && expertIntervention == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateRequestRequest &&
        other.note == note &&
        other.expertIntervention == expertIntervention;
  }

  @override
  int get hashCode => note.hashCode ^ expertIntervention.hashCode;
}

