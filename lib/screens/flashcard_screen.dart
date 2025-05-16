import "package:flutter/material.dart";
import "package:cs442_mp4/db_helper.dart";
import "package:cs442_mp4/screens/data_manager.dart";
import "package:cs442_mp4/screens/quiz_screen.dart";

class FLashcardListScreen extends StatefulWidget {
  final Decktable deck;
  
  const FLashcardListScreen({Key? key, required this.deck}) : super (key: key);

  @override 
  _FlashcardListScreenState createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FLashcardListScreen> {
  List<FlashcardTable> flashcards = [];
  String currentSortType = "created";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAndSetCards();
  }

  Future<void> fetchAndSetCards() async {
    final cards = await fetchCardsForDeck(widget.deck.id!);
    setState(() {
      flashcards = cards;
      _isLoading = false;
    });
  }

  @override 
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.title),
        actions: [
          // PopupMenuButton to choose sorting type.
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (String sortType) {
              setState(() {
                currentSortType = sortType;
              });
              fetchSortedCards(widget.deck.id!, sortType);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: "alphabetical",
                child: Text("Alphabetical"),
              ),
              const PopupMenuItem(
                value: "created",
                child: Text("Time Created (Oldest)"),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              if (flashcards.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(flashcard: flashcards.first)
                  )
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (flashcards.isEmpty 
             ? Center(child: Text("No flashcards available for ${widget.deck.title}"))
             : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200.0,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                  ),
                  itemCount: flashcards.length,
                  itemBuilder: (context, index) {
                    final flashcard = flashcards[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QuizScreen(flashcard: flashcard),
                          ),
                        );
                      },
                      child: FlashcardItem(flashcard),
                    );
                  },
                )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => AddCardScreen(deck: widget.deck),
                ),
              )
              .then((_) => fetchAndSetCards());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<FlashcardTable>> fetchCardsForDeck(int deckID) async {
    final dbHelper = DBHelper();
    final db = await dbHelper.db;

    final List<Map<String, dynamic>> flashCardMaps = 
      await db.query("flashcards", where: "deck_id = ?", whereArgs: [deckID]);

    return List.generate(flashCardMaps.length, (i) {
      return FlashcardTable(
        id: flashCardMaps[i]['id'],
        deckID: flashCardMaps[i]['deck_id'],
        question: flashCardMaps[i]['question'],
        answer: flashCardMaps[i]['answer'],
      );
    });
  }

  void fetchSortedCards(int deckID, String sortType) async {
    final dbHelper = DBHelper();
    final db = await dbHelper.db;

    List<Map<String, dynamic>> flashcardMaps = await db.query(
      "flashcards",
      where: "deck_id = ?",
      whereArgs: [deckID],
    );

    List<Map<String, dynamic>> sortedCardMaps;

    if (sortType == "alphabetical") {
      sortedCardMaps = List<Map<String, dynamic>>.from(flashcardMaps)
      ..sort((a, b) => a["question"].compareTo(b["question"]));
    }
    else if (sortType == "created"){
      sortedCardMaps = List<Map<String, dynamic>>.from(flashcardMaps)
      ..sort((a,b) {
        int aTime = a["created_at"] ?? 0;
        int bTime = b["created_at"] ?? 0;
        return aTime.compareTo(bTime);
      });
    }
    else {
      sortedCardMaps = flashcardMaps;
    }

    final sortedCards = List.generate(sortedCardMaps.length, (i) {
      return FlashcardTable(
        id: sortedCardMaps[i]["id"],
        deckID: sortedCardMaps[i]["deck_id"],
        question: sortedCardMaps[i]["question"],
        answer: sortedCardMaps[i]["answer"],
      );
    });
    setState(() {
      flashcards = sortedCards;
    });
  } 
}

class FlashcardItem extends StatelessWidget {
  final FlashcardTable flashcard;

  const FlashcardItem(this.flashcard, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 130, 215, 255),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  flashcard.question,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => 
                      CardDetailScreen(flashcard: flashcard),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddCardScreen extends StatefulWidget {
  final Decktable deck;

  const AddCardScreen({Key? key, required this.deck}) : super(key: key);

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController answerController = TextEditingController();

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add flashcard"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Add a new flashcard for ${widget.deck.title}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                ),
              ),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: "Question",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: "Answer",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      final dbHelper = DBHelper();
                      await dbHelper.insert("flashcards", {
                        "deck_id": widget.deck.id,
                        "question": questionController.text,
                        "answer": answerController.text,
                      });

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          FLashcardListScreen(deck: widget.deck),    
                        ),
                      );
                    },
                    child: const Text("Save",
                      style: TextStyle(color: Colors.blue)),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel",
                      style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardDetailScreen extends StatefulWidget {
  final FlashcardTable flashcard;

  const CardDetailScreen({Key? key, required this.flashcard}) : super(key: key);

  @override
  _CardDetailScreenState createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    questionController.text = widget.flashcard.question;
    answerController.text = widget.flashcard.answer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flashcard detail"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Question",
                style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Answer",
                style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      final dbHelper = DBHelper();
                      await dbHelper.update("flashcards", {
                        "id": widget.flashcard.id,
                        "question": questionController.text,
                        "answer": answerController.text,
                      });

                      Navigator.pop(context, "updated");
                    },
                    child: const Text("Save",
                      style: TextStyle(color: Colors.blue)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final dbHelper = DBHelper();
                      await dbHelper.delete("flashcards", widget.flashcard.id!);

                      Navigator.pop(context);
                    },
                    child: const Text("Delete",
                      style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}