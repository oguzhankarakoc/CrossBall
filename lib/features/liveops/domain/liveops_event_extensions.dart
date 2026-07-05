import '../../../core/constants/liveops_constants.dart';
import 'liveops_snapshot.dart';

extension LiveOpsEventX on LiveOpsEvent {
  bool get isLocked => LiveOpsConstants.isEventLocked(slug);
}
