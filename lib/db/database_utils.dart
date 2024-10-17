import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("app.db");
    return _database!;
  }

  Future<Database> _initDB(final String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(final Database db, final int version) async {
    // Table for folder table
    await db.execute('''
    CREATE TABLE folder_table (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      folder_name TEXT NOT NULL,
      timestamp TEXT NOT NULL
    )
    ''');

    // Table for card table
    await db.execute('''
    CREATE TABLE card_table (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      card_name TEXT NOT NULL,
      card_suit TEXT NOT NULL,
      card_uri TEXT NOT NULL,
      folder_id INTEGER NOT NULL
    )
    ''');
  }

  Future<int> addAllCardsToCardTable() async {
    final db = await instance.database;
    final List<String> cardTypeList = ["_of_clubs", "_of_diamonds", "_of_hearts",
      "_of_spades"];
    final List<String> cardNameList = [
      "2", "3", "4", "5", "6", "7", "8", "9", "10", "ace", "jack", "king", "queen",
    ];
    const cardUriPrefix = "lib/img/";
    const cardUriPostfix = ".png";
    int insertCount = 0;

    for (int i = 0; i < 13; i++) {
      for (int j = 0; j < 4; j++) {
        String fullCardName = cardNameList[i] + cardTypeList[j];
        await db.insert("card_table", {
          "card_name": fullCardName,
          "card_suit": cardTypeList[j].substring(4),
          "card_uri": cardUriPrefix + fullCardName + cardUriPostfix,
          "folder_id": j,
        });
        insertCount++;
      }
    }

    for (var joker in ["black_joker", "red_joker"]) {
      await db.insert("card_table", {
        "card_name": joker,
        "card_suit": "joker",
        "card_uri": joker + cardUriPostfix,
        "folder_id": 5,
      });
      insertCount++;
    }

    return insertCount;
  }

  Future<List<Map<String, dynamic>>> getCardsForFolder(final String cardSuit) async {
    final db = await instance.database;

    // Query card_table directly by card_suit
    final List<Map<String, dynamic>> cardResults = await db.query(
      'card_table',
      where: 'card_suit = ?',
      whereArgs: [cardSuit],
    );

    if (cardResults.isEmpty) {
      print('No cards found for suit: $cardSuit');
      return [];
    }

    print('Cards found for suit $cardSuit: $cardResults');

    // Map the results to a list of card details
    return cardResults.map((card) {
      return {
        'name': formatCardName(card['card_name']),
        'image': card['card_uri'],
      };
    }).toList();
  }



  String formatCardName(final String cardName) {
    // Convert name format from "ace_of_hearts" to "Ace of Hearts"
    return cardName.replaceAll('_', ' ').replaceFirstMapped(
        RegExp(r'^[a-z]'),
            (match) => match.group(0)!.toUpperCase()
    );
  }

  Future<Map<String, int>> getLastXTimestampsPerFolder(final int x) async {
    final int limit = x > 3 ? 3 : x;
    final db = await instance.database;

    final folderNamesResult = await db.query(
      "folder_table",
      columns: ["folder_name"],
      distinct: true,
    );
    print('Distinct folder names: $folderNamesResult');

    Map<String, int> folderTimestampsCount = {};

    for (var folder in folderNamesResult) {
      final folderName = folder["folder_name"] as String;

      final timestampsResult = await db.query(
        "folder_table",
        columns: ["timestamp"],
        where: "folder_name = ?",
        whereArgs: [folderName],
        orderBy: "timestamp DESC",
        limit: limit,
      );
      print('Folder: $folderName, Timestamps: $timestampsResult');

      folderTimestampsCount[folderName] = timestampsResult.length;
    }

    print('Fetched counts: $folderTimestampsCount');
    return folderTimestampsCount;
  }

  Future<void> addFakeCardsToCardTable() async {
    final db = await instance.database;
    final random = Random();

    // Define possible suits and card name prefixes for testing
    final suits = ["Spades", "Hearts", "Clubs", "Diamonds"];
    final cardNames = ["ace", "king", "queen", "jack", "10", "9"];
    final cardUriPrefix = "lib/img/";
    final cardUriPostfix = ".png";
    final now = DateTime.now().toIso8601String();

    for (int i = 0; i < 6; i++) {
      // Select a random suit and card name for the test card
      String randomSuit = suits[random.nextInt(suits.length)];
      String randomCardName = cardNames[random.nextInt(cardNames.length)];
      String fullCardName = "${randomCardName}_of_${randomSuit.toLowerCase()}";
      String cardUri = "$cardUriPrefix$fullCardName$cardUriPostfix";

      // Insert the card into card_table
      await db.insert("card_table", {
        "card_name": fullCardName,
        "card_suit": randomSuit,
        "card_uri": cardUri,
        "folder_id": random.nextInt(4)
      });

      // Insert the suit and timestamp into folder_table
      await db.insert("folder_table", {
        "folder_name": randomSuit,
        "timestamp": now,
      });

      print('Added $fullCardName to card_table and logged in folder_table.');
    }
  }

  Future<void> clearTables() async {
    final db = await instance.database;

    await db.delete('folder_table');
    await db.delete('card_table');

    print('Both folder_table and card_table have been cleared.');
  }
}