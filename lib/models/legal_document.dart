class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    required this.introduction,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<String> introduction;
  final List<LegalSection> sections;
}

class LegalSection {
  const LegalSection({
    required this.heading,
    this.paragraphs = const [],
    this.bulletGroups = const [],
    this.closingParagraphs = const [],
  });

  final String heading;
  final List<String> paragraphs;
  final List<LegalBulletGroup> bulletGroups;
  final List<String> closingParagraphs;
}

class LegalBulletGroup {
  const LegalBulletGroup({this.label, required this.items});

  final String? label;
  final List<String> items;
}
