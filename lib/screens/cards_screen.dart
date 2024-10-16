import 'package:flutter/material.dart';

class CardsScreen extends StatelessWidget {
  final int folderName;

  CardsScreen({required this.folderName});
  
  @override
  Widget build(BuildContext context) {
    // Get the list of cards for the selected folder
    final cards = cardsByFolder[folderName] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('$folderName Cards'),
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
