import "package:cs442_mp4/screens/flashcard_screen.dart";
import 'package:flutter/material.dart';
import "package:cs442_mp4/screens/data_manager.dart";
import "package:cs442_mp4/screens/deck_update.dart";
import "package:cs442_mp4/db_helper.dart";
import "package:cs442_mp4/views/decklist.dart";
import "package:sqflite/sqflite.dart";

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  _DeckListScreenState createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  bool _dataLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 102, 178, 255),
        title: const Text("Deck List"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              _downloadData();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Decktable>>(
        future: fetchDecksFromDB(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No decks available"));
          }
          else {
            final decks = snapshot.data;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _calculateCrossAxisCount(context),
              ),
              itemCount: decks?.length,
              itemBuilder: (context, index) {
                final deck = decks?[index];
                return InkWell(
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FLashcardListScreen(deck: deck),
                      ),
                    );
                  },
                  child: DeckCard(deck!, _onDeckAdded),
                );
              },
            );
          } 
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                DeckCreationScreen(onDeckAdded: _onDeckAdded)),
          );
        },
        backgroundColor: const Color.fromARGB(255, 153, 204, 255),
        child: const Icon(Icons.add)),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = 200.0;
    final crossAxisCount = (width / cardWidth).round();
    return crossAxisCount;
  }

  Future<void> fetchDataIfNeeded() async {
    if(!_dataLoaded) {
      await fetchDecksFromDB();
      setState(() {
        _dataLoaded = true;
      });
    }
  }

  void _onDeckAdded(bool added) {
    if (added) {
      setState(() {
        _dataLoaded = false;
      });
    }
  }

  void _downloadData() async {
    try {
      await loadJsonDataToDB();

      setState(() {
        _dataLoaded = false;
      });
    } catch (e) {
      print("Error loading data: $e");
    }
  }  
}

class DeckCard extends StatefulWidget {
  final Decktable deck;
  final Function(bool) onDeckUpdated;

  DeckCard(this.deck, this.onDeckUpdated, {super.key});

  @override
  _DeckCardState createState() => _DeckCardState();
}

class _DeckCardState extends State<DeckCard> {
  final TextEditingController _titleController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.deck.title;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.yellow[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: () {
          if (!_isEditing) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FLashcardListScreen(deck: widget.deck),
              ),
            );
          }
        },
        child: Stack(
          children: <Widget>[
            Center(
              child: Column(
                mainAxisSize:MainAxisSize.min,
                children: <Widget>[
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: "Edit title",
                        ),
                      ),
                    )
                  else 
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.deck.title,
                          style: const TextStyle(
                            fontSize: 16, 
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${widget.deck.cardCount} cards",
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (!_isEditing)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DeckUpdateScreen(
                          deck: widget.deck,
                          onDeckUpdated: widget.onDeckUpdated,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<List<Decktable>> fetchDecksFromDB() async {
  final dbHelper = DBHelper();
  final Database db = await dbHelper.db;

  // final List<Map<String, dynamic>> deckMaps = await db.query("decks");
  final List<Map<String, dynamic>> deckMaps = await db.rawQuery(
    '''
    SELECT decks.id, decks.title, COUNT(flashcards.id) as cardCount 
    FROM decks LEFT JOIN flashcards ON flashcards.deck_id = decks.id
    GROUP BY decks.id, decks.title 
    '''
  );

  return List.generate(deckMaps.length, (i) {
    return Decktable(
      id: deckMaps[i]["id"],
      title: deckMaps[i]["title"],
      cardCount: deckMaps[i]["cardCount"],
    );
  });
}

class DeckCreationScreen extends StatelessWidget {
  final TextEditingController _titleController = TextEditingController();
  final Function(bool) onDeckAdded;

  DeckCreationScreen({super.key, required this.onDeckAdded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create new deck"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Deck Title"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    final dbHelper = DBHelper();
                    await dbHelper.insert("decks", {"title": _titleController.text});
                    onDeckAdded(true);
                    Navigator.pop(context);
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.blue)),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    onDeckAdded(false);
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}