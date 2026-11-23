import 'roadmap_models.dart';

/// Tính trạng thái mọi node. Hàm thuần: không đọc DB, không phụ thuộc UI.
///
/// Luật:
/// - Node có bestScore >= [kUnlockThreshold] -> completed.
/// - Node được bỏ qua (Placement Test) -> skipped.
/// - Node đầu tiên luôn available.
/// - Node kế tiếp available khi node ngay trước đã completed/skipped.
/// - Các node còn lại -> locked.
Map<String, NodeStatus> computeNodeStatuses(
  List<RoadmapStage> stages,
  Map<String, NodeProgress> progress,
) {
  final orderedStages = [...stages]..sort((a, b) => a.order.compareTo(b.order));
  final flat = <RoadmapNode>[
    for (final s in orderedStages)
      ...([...s.nodes]..sort((a, b) => a.order.compareTo(b.order))),
  ];

  final result = <String, NodeStatus>{};
  var previousDone = true; // node đầu tiên luôn được mở

  for (final node in flat) {
    final p = progress[node.id];
    final NodeStatus status;
    if (p?.skipped ?? false) {
      status = NodeStatus.skipped;
    } else if ((p?.bestScore ?? -1) >= kUnlockThreshold) {
      status = NodeStatus.completed;
    } else if (previousDone) {
      status = NodeStatus.available;
    } else {
      status = NodeStatus.locked;
    }
    result[node.id] = status;
    previousDone =
        status == NodeStatus.completed || status == NodeStatus.skipped;
  }
  return result;
}

/// Node nên hiển thị nút "Tiếp tục học" (node available đầu tiên).
String? nextNodeId(
  List<RoadmapStage> stages,
  Map<String, NodeStatus> statuses,
) {
  final orderedStages = [...stages]..sort((a, b) => a.order.compareTo(b.order));
  for (final s in orderedStages) {
    final nodes = [...s.nodes]..sort((a, b) => a.order.compareTo(b.order));
    for (final n in nodes) {
      if (statuses[n.id] == NodeStatus.available) return n.id;
    }
  }
  return null;
}