import 'package:flutter/material.dart';
import '../db/database_utils.dart';

class CardsScreen extends StatefulWidget {
  final String folderName;
  final VoidCallback updateFoldersCallback;
  final int folderIndex;

  CardsScreen({required this.folderName, required this.updateFoldersCallback,
    required this.folderIndex});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> cards = [];
  bool isLoading = true;
  String selectedCardButton = '';

  final List<String> suits = ["Hearts", "Spades", "Diamonds", "Clubs"];
  final List<String> ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10",
    "Jack", "Queen", "King"];

  String selectedSuit = '';
  String selectedRank = '2';

  String originalSelectedRank = '';

  Map<String, dynamic>? oldestCard;
  Map<String, dynamic>? middleCard;
  Map<String, dynamic>? latestCard;

  @override
  void initState() {
    super.initState();
    selectedSuit = suits[widget.folderIndex];
    loadCards();
  }

  Future<void> loadCards() async {
    try {
      final fetchedCards = await DatabaseHelper.instance.getCardsForFolder(widget.folderName);
      setState(() {
        cards = fetchedCards;
        isLoading = false;

        if (cards.isNotEmpty) {
          oldestCard = cards.first;

          if (cards.length == 1) {
            middleCard = null;
            latestCard = null;
          } else if (cards.length == 2) {
            middleCard = cards[1];
            latestCard = null;
          } else {
            middleCard = cards[cards.length ~/ 2];
            latestCard = cards.last;
          }
        } else {
          oldestCard = null;
          middleCard = null;
          latestCard = null;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading cards: $e');
    }
  }


  Future<void> addCard() async {
    int suitId = suits.indexOf(selectedSuit);

    await DatabaseHelper.instance.addCardToCardTable(selectedSuit,
        selectedRank.toLowerCase(), suitId);
    await verifyFolderTableContents();
    await loadCards();
    widget.updateFoldersCallback();
  }

  Future<void> verifyFolderTableContents() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query("folder_table");
    print('Contents of folder_table: $result');
  }

  Future<void> deleteCard() async {
    await DatabaseHelper.instance.deleteCardFromDatabase(selectedSuit,
        selectedRank);
    await loadCards();
    widget.updateFoldersCallback();
  }

  Future<void> updateCard() async {
    await DatabaseHelper.instance.updateCardInDatabase(selectedSuit,
        originalSelectedRank, selectedSuit, selectedRank);
    await loadCards();
    widget.updateFoldersCallback();
  }

  String formatRank(final String cardName) {
    return cardName.split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folderName} Cards'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addCard,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: deleteCard,
          ),
          IconButton(
            icon: Icon(Icons.update),
            onPressed: updateCard,
          ),
        ],
      ),
      body: Column(
        children: [
          // Row of buttons for oldest, middle, and latest cards
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: oldestCard != null
                      ? () {
                    setState(() {
                      originalSelectedRank = formatRank(oldestCard!['name']);
                      selectedCardButton = 'oldest';
                      print("Old card name $originalSelectedRank");
                    });
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCardButton == 'oldest' ? Colors.green[200] : Colors.white,
                  ),
                  child: Text('Oldest Card'),
                ),
                ElevatedButton(
                  onPressed: middleCard != null
                      ? () {
                    setState(() {
                      originalSelectedRank = formatRank(middleCard!['name']);
                      selectedCardButton = 'middle';
                      print("Middle card name $originalSelectedRank");
                    });
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCardButton == 'middle' ? Colors.green[200] : Colors.white,
                  ),
                  child: Text('Middle Card'),
                ),
                ElevatedButton(
                  onPressed: latestCard != null
                      ? () {
                    setState(() {
                      originalSelectedRank = formatRank(latestCard!['name']);
                      selectedCardButton = 'latest';
                      print("Latest card name $originalSelectedRank");
                    });
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCardButton == 'latest' ? Colors.green[200] : Colors.white,
                  ),
                  child: Text('Latest Card'),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : cards.isEmpty
                ? Center(child: Text('No cards found.'))
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  var card = cards[index];
                  return Card(
                    elevation: 4.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.asset(
                            card['image'],
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          card['name'],
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedSuit,
                    onChanged: null,
                    items: suits.map<DropdownMenuItem<String>>((String suit) {
                      return DropdownMenuItem<String>(
                        value: suit,
                        child: Text(suit),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedRank,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedRank = newValue!;
                      });
                    },
                    items: ranks.map<DropdownMenuItem<String>>((String rank) {
                      return DropdownMenuItem<String>(
                        value: rank,
                        child: Text(rank),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
