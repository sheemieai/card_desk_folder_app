import 'package:flutter/material.dart';
import '../db/database_utils.dart';

class CardsScreen extends StatefulWidget {
  final String folderName;

  CardsScreen({required this.folderName});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> cards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  Future<void> loadCards() async {
    try {
      final fetchedCards = await DatabaseHelper.instance.getCardsForFolder(
          widget.folderName);
      setState(() {
        cards = fetchedCards;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading cards: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folder ${widget.folderName} Cards'),
      ),
      body: isLoading
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add card functionality (UI placeholder)
        },
        child: Icon(Icons.add),
        tooltip: 'Add Card',
      ),
    );
  }
}
