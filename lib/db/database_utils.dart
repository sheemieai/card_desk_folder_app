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

  Future<List<Map<String, dynamic>>> getAllCardsAsMap() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query("card_table");

    // Map each card to desired format
    final List<Map<String, dynamic>> cards = result.map((card) {
      return {
        'name': '${_formatCardName(card['card_name'])}',
        'image': card['card_uri'],
      };
    }).toList();

    return cards;
  }

  String _formatCardName(final String cardName) {
    // Convert name format from "ace_of_hearts" to "Ace of Hearts"
    return cardName.replaceAll('_', ' ').replaceFirstMapped(
        RegExp(r'^[a-z]'),
            (match) => match.group(0)!.toUpperCase()
    );
  }
}