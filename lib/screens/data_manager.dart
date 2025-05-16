import 'package:cs442_mp4/db_helper.dart';

class Decktable {
  int? id;
  final String title;
  final int cardCount;

  Decktable({
    this.id,
    required this.title,
    this.cardCount = 0,
  });

  Future<void> dbSave() async {
    id = await DBHelper().insert(
      'decks',
      {'title': title,}
    );
  }

  Future<void> dbDelete() async {
    if (id != null) {
      await DBHelper().delete('decks', id!);
    }
  }
}

class FlashcardTable {
  int? id;
  final int deckID;
  final String question;
  final String answer;

  FlashcardTable({
    this.id,
    required this.deckID,
    required this.question,
    required this.answer,
  });

  Future<void> dbSave() async {
    id = await DBHelper().insert('flashcards', {
      'question': question,
      'answer': answer,
      'deck_id': deckID,
    });
  }

  Future<void> dbDelete() async {
    if (id != null) {
      await DBHelper().delete('flashcards', id!);
    }
  }
}