import "package:flutter/material.dart";
import "package:cs442_mp4/screens/data_manager.dart";
import "package:cs442_mp4/db_helper.dart";

class QuizScreen extends StatefulWidget {
  final FlashcardTable flashcard;
  const QuizScreen({Key? key, required this.flashcard}) : super(key: key);

  @override 
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  bool showAnswer = false;
  List<FlashcardTable> flashcards = [];
  int answerCount = 0;
  int maxIndexViewed = 0;

  @override
  void initState() {
    super.initState();
    fetchCardsForDeck(widget.flashcard.deckID);

  }

  void fetchCardsForDeck(int deckID) async {
    final dbHelper = DBHelper();
    final db = await dbHelper.db;

    final flashcardMaps = await db.query(
      "flashcards",
      where: "deck_id = ?",
      whereArgs: [deckID]
    );

    setState(() {
      flashcards = flashcardMaps.map((map) {
        return FlashcardTable(
          id: map["id"] as int,
          deckID: map["deck_id"] as int,
          question: map["question"] as String,
          answer:  map["answer"] as String,
        );
      }).toList();
      maxIndexViewed = flashcards.isNotEmpty ? 1: 0;
    });
  }

  @override 
  Widget build(BuildContext context) {
    if(flashcards.isEmpty || currentIndex < 0 || currentIndex >= flashcards.length) {
      return const Center(
        child: Text("No flashcards available for this deck"),
      );
    }

    final flashcard = flashcards[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            height: 200,
            child: Card(
              color: showAnswer ? Colors.green : Color.fromARGB(255, 153, 204, 255),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      showAnswer ? flashcard.answer : flashcard.question,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if(currentIndex == 0)
                GestureDetector(
                  onTap:() {
                    setState(() {
                      currentIndex = flashcards.length -1;
                      showAnswer = false;
                    });
                  },
                  child: const Icon(Icons.arrow_back, size:40),
                ),
              if (currentIndex > 0) 
                GestureDetector(
                  onTap: () {
                    setState(() {
                      currentIndex--;
                      showAnswer = false;
                    });
                  },
                  child: const Icon(Icons.arrow_back, size: 40),
                ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showAnswer = !showAnswer;
                    if (showAnswer) {
                      answerCount++;
                    }
                  });
                },
                child: Icon(
                  showAnswer ? Icons.visibility_off : Icons.visibility,
                  size: 40,
                ),
              ),
              if (currentIndex < flashcards.length - 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      currentIndex++;
                      showAnswer = false;
                      if(currentIndex + 1 > maxIndexViewed) {
                        maxIndexViewed =currentIndex + 1;
                      }
                    });
                  },
                  child: const Icon(Icons.arrow_forward, size: 40),
                )
              else 
                GestureDetector(
                  onTap: () {
                    setState(() {
                      currentIndex = 0;
                      showAnswer = false;
                      answerCount = 0;
                      maxIndexViewed = flashcards.isEmpty ? 1 : 0;
                    });
                  },
                  child: const Icon(Icons.refresh, size: 40),
                )  
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Cards Viewed: ${maxIndexViewed} / ${flashcards.length}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Answers Revealed: ${answerCount} / ${maxIndexViewed}",
            style: const TextStyle(fontSize: 16),
          )
        ],
      ),
    );
  }
}