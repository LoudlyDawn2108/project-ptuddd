import 'package:flutter_test/flutter_test.dart';
import 'package:chailish/features/roadmap/domain/roadmap_models.dart';
import 'package:chailish/features/roadmap/domain/unlock_rules.dart';

void main() {
  const stages = [
    RoadmapStage(id: 's1', title: 'Chào hỏi', order: 1, nodes: [
      RoadmapNode(id: 'n1', title: 'Nǐ hǎo', order: 1),
      RoadmapNode(id: 'n2', title: 'Tự giới thiệu', order: 2),
    ]),
    RoadmapStage(id: 's2', title: 'Số đếm', order: 2, nodes: [
      RoadmapNode(id: 'n3', title: 'Số 1-10', order: 1),
    ]),
  ];

  test('chưa học gì: chỉ node đầu available', () {
    final s = computeNodeStatuses(stages, {});
    expect(s['n1'], NodeStatus.available);
    expect(s['n2'], NodeStatus.locked);
    expect(s['n3'], NodeStatus.locked);
  });

  test('điểm 69 chưa mở khóa, 70 thì mở', () {
    var s = computeNodeStatuses(stages, {'n1': const NodeProgress(bestScore: 69)});
    expect(s['n1'], NodeStatus.available);
    expect(s['n2'], NodeStatus.locked);

    s = computeNodeStatuses(stages, {'n1': const NodeProgress(bestScore: 70)});
    expect(s['n1'], NodeStatus.completed);
    expect(s['n2'], NodeStatus.available);
  });

  test('mở khóa xuyên chặng', () {
    final s = computeNodeStatuses(stages, {
      'n1': const NodeProgress(bestScore: 90),
      'n2': const NodeProgress(bestScore: 80),
    });
    expect(s['n3'], NodeStatus.available);
  });

  test('Placement Test bỏ qua node -> mở node sau', () {
    final s = computeNodeStatuses(stages, {
      'n1': const NodeProgress(skipped: true),
    });
    expect(s['n1'], NodeStatus.skipped);
    expect(s['n2'], NodeStatus.available);
  });

  test('nextNodeId trả về node available đầu tiên', () {
    final s = computeNodeStatuses(stages, {'n1': const NodeProgress(bestScore: 95)});
    expect(nextNodeId(stages, s), 'n2');
  });
}