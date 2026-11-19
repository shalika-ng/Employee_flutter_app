import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quote.dart';

class QuoteService {
  // Load all quotes from the JSON file
  Future<List<Quote>> loadQuotes() async {
    try {
      final String response = await rootBundle.loadString('assets/data/quote.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Quote.fromJson(json)).toList();
    } catch (e) {
      print('Error loading quotes: $e');
      return [];
    }
  }

  // Get a random quote based on the selected mood ID
  Quote? getQuoteForMood(int moodId, List<Quote> allQuotes) {
    final matchingQuotes = allQuotes
        .where((quote) => quote.moods.contains(moodId))
        .toList();

    if (matchingQuotes.isEmpty) return null;

    // Shuffle to get a random quote from the matches
    matchingQuotes.shuffle();
    return matchingQuotes.first;
  }
}