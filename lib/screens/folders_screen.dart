import 'package:flutter/material.dart';
import 'cards_screen.dart';
import '../db/database_utils.dart';

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Map<String, dynamic>> folders = [
    {'name': 'Hearts', 'image': 'lib/img/10_of_hearts.png', 'cardCount': 1},
    {'name': 'Spades', 'image': 'lib/img/10_of_spades.png', 'cardCount': 1},
    {'name': 'Diamonds', 'image': 'lib/img/10_of_diamonds.png', 'cardCount': 1},
    {'name': 'Clubs', 'image': 'lib/img/10_of_clubs.png', 'cardCount': 1}
  ];

  @override
  void initState() {
    super.initState();
    fetchFolderCardCounts();
  }

  Future<void> fetchFolderCardCounts() async {
    final folderCounts = await DatabaseHelper.instance.getCardCountsPerFolder();
    final folderUris = await DatabaseHelper.instance.getLatestCardUrisPerFolder();

    setState(() {
      for (var folder in folders) {
        final folderName = folder['name'];
        folder['cardCount'] = folderCounts[folderName] ?? 0;
        folder['image'] = folderUris[folderName] ?? 'lib/img/blank.png';
      }
    });

    print('Updated folder counts and images: $folders');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Folders'),
      ),
      body: Column(
        children: [
          // GridView displaying card folders
          Expanded(
            child: Padding(
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardsScreen(
                            folderName: folder['name'],
                            updateFoldersCallback: fetchFolderCardCounts,
                            folderIndex: index,
                          ),
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
                          Text(
                            folder['name'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
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
          ),
        ],
      ),
    );
  }
}
