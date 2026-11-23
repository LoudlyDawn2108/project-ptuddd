/// Mô hình dữ liệu Lộ trình học: Stage (chặng) -> Node (bài học).

enum NodeStatus { locked, available, completed, skipped }

/// Điểm tối thiểu ở bài trước để mở khóa bài kế tiếp.
const int kUnlockThreshold = 70;

class RoadmapNode {
  const RoadmapNode({
    required this.id,
    required this.title,
    required this.order,
  });

  final String id;
  final String title;
  final int order;
}

class RoadmapStage {
  const RoadmapStage({
    required this.id,
    required this.title,
    required this.order,
    required this.nodes,
  });

  final String id;
  final String title;
  final int order;
  final List<RoadmapNode> nodes;
}

/// Tiến độ của một node, đọc từ SQLite cục bộ.
class NodeProgress {
  const NodeProgress({this.bestScore, this.skipped = false});

  /// Điểm cao nhất đã đạt (null nếu chưa làm).
  final int? bestScore;

  /// true nếu được bỏ qua nhờ Placement Test.
  final bool skipped;
}