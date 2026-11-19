class Quote {
  final int id;
  final String category;
  final String text;
  final String author;
  final List<int> moods;

  Quote({
    required this.id,
    required this.category,
    required this.text,
    required this.author,
    required this.moods,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      // Parse the moods array safely
      moods: json['moods'] != null 
          ? List<int>.from(json['moods']) 
          : [],
    );
  }
}