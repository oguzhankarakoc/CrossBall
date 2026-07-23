/// Contextual help topics shown once per screen/mode (re-openable via info button).
enum FeatureInfoTopic {
  home,
  practiceHub,
  daily,
  classicPractice,
  quickGrid,
  matchGrid,
  timeline,
}

extension FeatureInfoTopicX on FeatureInfoTopic {
  String get prefsKey => 'feature_info_seen_v1_$name';

  String get analyticsName => name;
}
