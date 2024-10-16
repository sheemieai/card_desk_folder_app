import 'package:flutter/material.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> folders = [
    {'name': 'Hearts', 'image': 'lib/img/10_of_hearts.png', 'cardCount': 3, 'index': 0},
    {'name': 'Spades', 'image': 'lib/img/10_of_spades.png', 'cardCount': 5, 'index': 1},
    {'name': 'Diamonds', 'image': 'lib/img/10_of_diamonds.png', 'cardCount': 6, 'index': 2},
    {'name': 'Clubs', 'image': 'lib/img/10_of_clubs.png', 'cardCount': 4, 'index': 3}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Folders'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.8,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            var folder = folders[index];
            return GestureDetector(
              onTap: () {
                // Navigate to CardsScreen and pass the folder name
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CardsScreen(folderIndex: folder['index']),
                  ),
                );
              },
              child: Card(
                elevation: 4.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        folder['image'],
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Folder name
                    Text(
                      folder['name'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    // Number of cards in the folder
                    Text(
                      '${folder['cardCount']} cards',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
