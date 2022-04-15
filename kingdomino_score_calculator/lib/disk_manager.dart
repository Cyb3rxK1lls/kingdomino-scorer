import 'dart:io';
import 'package:kingdomino_score_calculator/tile.dart';
import 'package:path_provider/path_provider.dart';
import 'board.dart';
import 'history.dart';

class DiskManager {
  List<History> history = [];
  List<String> labels = [
    'plains_0',
    'graveyard_2',
    'cave_2',
    'graveyard_0',
    'wheat_0',
    'water_0',
    'plains_1',
    'water_1',
    'wheat_1',
    'plains_2',
    'forest_1',
    'forest_0',
    'cave_0',
    'cave_3',
    'cave_1',
    'graveyard_1',
    'empty'
  ];

  DiskManager() {
    _loadHistory();
  }

  void _loadHistory() async {
    File gamelist = await getFile('', 'historyList.txt');
    List<String> games = await gamelist.readAsLines();
    for (String s in games) {
      String name = s.split(' ')[0];
      int score = int.parse(s.split(' ')[1]);
      history.add(History(name, score));
    }
  }

  Future<String> _getPath(String folder) async {
    final directory = await getApplicationDocumentsDirectory();
    final Directory desiredFolder = Directory('${directory.path}/$folder/');
    if (!await desiredFolder.exists()) {
      desiredFolder.create();
    }
    return desiredFolder.path;
  }

  Future<File> getFile(String folder, String filename) async {
    final path = await _getPath(folder);
    final File desiredFile = File('$path/$filename');
    if (!await desiredFile.exists()) {
      return desiredFile.create();
    }
    return desiredFile;
  }

  void _writeGame(String filename, List<String> boardState) async {
    File historyFile = await getFile('history', '$filename.txt');
    String contents = "";
    for (String tile in boardState) {
      contents += tile + '\n';
    }
    historyFile.writeAsString(contents);
  }

  void writeStats(String contents) async {
    File statsFile = await getFile('', 'stats.txt');
    statsFile.writeAsString(contents);
  }

  Future<String> loadStats() async {
    File statsFile = await getFile('', 'stats.txt');
    return await statsFile.readAsString();
  }

  Future<Board> loadGame(String filename, int imageSize) async {
    List<Tile> tiles = [];
    File gameFile = await getFile('history', '$filename.txt');
    String content = await gameFile.readAsString();
    List<String> packedTiles = content.split('\n');
    for (String tile in packedTiles) {
      if (tile.isEmpty) {
        continue;
      }
      List<String> components = tile.split(' ');
      String label = components.elementAt(0);
      double xMid = double.parse(components.elementAt(1));
      double yMid = double.parse(components.elementAt(2));
      double width = double.parse(components.elementAt(3));
      double height = double.parse(components.elementAt(4));
      tiles.add(Tile(label, xMid, yMid, width, height, imageSize, false));
    }

    return Board(tiles);
  }

  void saveGame(Board board) async {
    DateTime time = DateTime.now();
    String filename = '${time.year.toString()}_${time.month.toString()}_';
    filename += '${time.day.toString()}_${time.hour.toString()}_';
    filename += '${time.minute.toString()}_${time.second.toString()}';
    _writeGame(filename, board.packageBoard());
    History newHistory = History(filename, board.totalScore);
    File gameFile = await getFile('', 'historyList.txt');
    final contents = await gameFile.readAsString();
    String newContents = contents + newHistory.toString() + '\n';
    gameFile.writeAsString(newContents);
    history.add(newHistory);
  }
}
