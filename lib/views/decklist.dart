import 'package:cs442_mp4/screens/data_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../screens/deck_screen.dart';

class DeckList extends StatefulWidget {
  const DeckList({super.key});
  
  @override 
  _DeckListState createState() => _DeckListState();
}

class _DeckListState extends State<DeckList> {
  bool dataLoaded = false;

  @override 
  void initState() {
    super.initState();

    // check if data has been loaded
    if(!dataLoaded) {
      dataLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DeckListScreen(),
    );
  }
}

Future<void> loadJsonDataToDB() async {
  final String jsonString = await rootBundle.loadString("assets/flashcards.json");
  final List<dynamic> jsonData = json.decode(jsonString);

  for (var deckData in jsonData) {
    final Decktable deck = Decktable(title: deckData["title"]);
    await deck.dbSave();

    final List<dynamic> flashcardData = deckData["flashcards"];

    for (var flashcardData in flashcardData) {
      final FlashcardTable flashcard = FlashcardTable(
        deckID: deck.id!, 
        question: flashcardData["question"], 
        answer: flashcardData["answer"]
      );
      await flashcard.dbSave();
    }
  }
}