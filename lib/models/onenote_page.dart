class OneNotePage {
  final String id;
  final String title;
  final String content;
  final DateTime createdTime;
  final DateTime lastModifiedTime;
  final String parentSection;

  OneNotePage({
    required this.id,
    required this.title,
    required this.content,
    required this.createdTime,
    required this.lastModifiedTime,
    required this.parentSection,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdTime': createdTime.toIso8601String(),
        'lastModifiedTime': lastModifiedTime.toIso8601String(),
        'parentSection': parentSection,
      };
}
