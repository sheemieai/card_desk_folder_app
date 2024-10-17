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

  Future<Map<String, int>> getCardCountsPerFolder() async {
    final db = await instance.database;

    final folderNamesResult = await db.query(
      "card_table",
      columns: ["card_suit"],
      distinct: true,
    );
    print('Distinct folder suits: $folderNamesResult');

    Map<String, int> folderCardCounts = {};

    for (var folder in folderNamesResult) {
      final folderName = folder["card_suit"] as String;

      final cardCountResult = await db.rawQuery(
        "SELECT COUNT(*) as count FROM card_table WHERE card_suit = ?",
        [folderName],
      );

      final cardCount = cardCountResult.first['count'] as int;
      print('Suit: $folderName, Card count: $cardCount');

      folderCardCounts[folderName] = cardCount;
    }

    print('Fetched card counts: $folderCardCounts');
    return folderCardCounts;
  }

  Future<void> addCardToCardTable(final String selectedSuit, final String selectedRank, final int suitId) async {
    final db = await instance.database;
    final cardUriPrefix = "lib/img/";
    final cardUriPostfix = ".png";
    final now = DateTime.now().toIso8601String();

    String fullCardName = "${selectedRank.toLowerCase()}_of_${selectedSuit.toLowerCase()}";
    String cardUri = "$cardUriPrefix$fullCardName$cardUriPostfix";

    final existingCards = await db.query(
      "card_table",
      where: "card_suit = ?",
      whereArgs: [selectedSuit],
    );

    if (existingCards.length >= 3) {
      print("This folder can only hold 3 cards.");
      return;
    } else if (existingCards.length < 3) {
      print("You need at least 3 cards in this folder.");
    }

    final duplicateCard = await db.query(
      "card_table",
      where: "card_name = ? AND card_suit = ?",
      whereArgs: [fullCardName, selectedSuit],
    );

    if (duplicateCard.isNotEmpty) {
      print('Card $fullCardName already exists in the database. Skipping insertion.');
      return;
    }

    await db.insert("card_table", {
      "card_name": fullCardName,
      "card_suit": selectedSuit,
      "card_uri": cardUri,
      "folder_id": suitId,
    });

    await db.insert("folder_table", {
      "folder_name": selectedSuit,
      "timestamp": now,
    });

    print('Added $fullCardName to card_table and logged in folder_table.');
  }

  Future<void> deleteCardFromDatabase(final String suit, final String rank) async {
    final db = await instance.database;
    final cardName = '${rank.toLowerCase()}_of_${suit.toLowerCase()}';

    await db.delete(
      'card_table',
      where: 'card_name = ? AND card_suit = ?',
      whereArgs: [cardName, suit],
    );

    print('Deleted $cardName from card_table');

    final anyTimestampEntry = await db.query(
      'folder_table',
      columns: ['id', 'timestamp'],
      where: 'folder_name = ?',
      whereArgs: [suit],
      limit: 1,
    );

    if (anyTimestampEntry.isNotEmpty) {
      final timestampId = anyTimestampEntry.first['id'];
      await db.delete(
        'folder_table',
        where: 'id = ?',
        whereArgs: [timestampId],
      );

      print('Deleted a timestamp entry for $suit from folder_table with id $timestampId');
    } else {
      print('No timestamp entries found in folder_table for $suit');
    }
  }

  Future<void> updateCardInDatabase(final String originalSuit, final String originalRank,
      final String newSuit, final String newRank) async {
    final db = await instance.database;
    final originalCardName = '${originalRank.toLowerCase()}_of_${originalSuit.toLowerCase()}';
    final newCardName = '${newRank.toLowerCase()}_of_${newSuit.toLowerCase()}';
    final cardUriPrefix = "lib/img/";
    final cardUriPostfix = ".png";
    final newCardUri = "$cardUriPrefix$newCardName$cardUriPostfix";

    final duplicateCard = await db.query(
      'card_table',
      where: 'card_name = ? AND card_suit = ?',
      whereArgs: [newCardName, newSuit],
    );

    if (duplicateCard.isNotEmpty) {
      print('Card $newCardName already exists in the database. Update skipped.');
      return;
    }

    await db.update(
      'card_table',
      {
        'card_name': newCardName,
        'card_suit': newSuit,
        'card_uri': newCardUri,
      },
      where: 'card_name = ? AND card_suit = ?',
      whereArgs: [originalCardName, originalSuit],
    );

    print('Updated $originalCardName to $newCardName in card_table');
  }

  Future<void> clearTables() async {
    final db = await instance.database;

    await db.delete('folder_table');
    await db.delete('card_table');

    print('Both folder_table and card_table have been cleared.');
  }

  Future<Map<String, String>> getLatestCardUrisPerFolder() async {
    final db = await instance.database;
    final defaultUri = 'lib/img/blank.png';

    final suitsResult = await db.query(
      "card_table",
      columns: ["card_suit"],
      distinct: true,
    );
    print('Distinct card suits: $suitsResult');

    Map<String, String> suitUris = {};

    for (var suitEntry in suitsResult) {
      final suit = suitEntry["card_suit"] as String;

      final latestCardResult = await db.query(
        "card_table",
        columns: ["card_uri"],
        where: "card_suit = ?",
        whereArgs: [suit],
        orderBy: "id DESC",
        limit: 1,
      );

      final cardUri = latestCardResult.isNotEmpty
          ? latestCardResult.first['card_uri'] as String
          : defaultUri;

      print('Suit: $suit, Latest Card URI: $cardUri');
      suitUris[suit] = cardUri;
    }

    final allSuits = ["Hearts", "Spades", "Diamonds", "Clubs"];
    for (var suit in allSuits) {
      suitUris.putIfAbsent(suit, () => defaultUri);
    }

    print('Final suit URIs: $suitUris');
    return suitUris;
  }
}