import 'package:flutter/material.dart';
import '../db/database_utils.dart';

class CardsScreen extends StatelessWidget {
  final int folderIndex;

  CardsScreen({required this.folderIndex});
  
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> cards = [];

    Future<List<Map<String, dynamic>>> fetchCards() async {
      return await DatabaseHelper.instance.getAllCardsAsMap();
    }

    print(fetchCards());

    return Scaffold(
      appBar: AppBar(
        title: Text('$fetchCards Cards'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two cards per row
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio:
                0.8, // Adjust ratio to fit images and text properly
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            var card = cards[index];
            return Card(
              elevation: 4.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Card image
                  Expanded(
                    child: Image.asset(
                      card['image'],
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  // Card name
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
      // Floating Action Button to add a new card (UI placeholder)
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
