import 'dart:collection';

import 'package:kingdomino_score_calculator/tile.dart';
import 'dart:math';

class Board {
  List<Tile> board = [];
  int totalScore = 0;
  double minX = 0;
  double maxX = 0;
  double minY = 0;
  double maxY = 0;
  int averageWidth = 0;
  int averageHeight = 0;
  int numRows = 0;
  int numCols = 0;

  Board(List<Tile> tiles) {
    if (tiles.isEmpty) {
      return;
    }
    board = _sort(tiles);

    minX = tiles.reduce((min, element) {
      if (min.xMid < element.xMid) {
        return min;
      } else {
        return element;
      }
    }).xMid;

    maxX = tiles.reduce((max, element) {
      if (max.xMid > element.xMid) {
        return max;
      } else {
        return element;
      }
    }).xMid;

    minY = tiles.reduce((min, element) {
      if (min.yMid < element.yMid) {
        return min;
      } else {
        return element;
      }
    }).yMid;

    maxY = tiles.reduce((max, element) {
      if (max.yMid > element.yMid) {
        return max;
      } else {
        return element;
      }
    }).yMid;

    for (Tile tile in board) {
      averageWidth += tile.width;
      averageHeight += tile.height;
    }
    averageHeight = (averageHeight / board.length).round();
    averageWidth = (averageWidth / board.length).round();
    if (averageHeight == 0) {
      averageHeight = 1;
    }
    if (averageWidth == 0) {
      averageWidth = 1;
    }
    numCols = (((maxX - minX) / averageWidth) + 1).round();
    numRows = (((maxY - minY) / averageHeight) + 1).round();

    _handleCollisions();
    _addEmptyTiles();
    _calculateScore();
  }

  void recalculateScore() {
    totalScore = 0;
    for (Tile t in board) {
      t.reset();
    }
    _calculateScore();
  }

  List<String> packageBoard() {
    List<String> tiles = [];
    int imageSize = board.elementAt(0).size;
    for (int y = 0; y < numRows; y++) {
      for (int x = 0; x < numCols; x++) {
        double xMid = minX + (averageWidth * x);
        double yMid = minY + (averageHeight * y);
        String label = _getTile(xMid, yMid).label;
        tiles.add(
            '$label ${xMid / imageSize} ${yMid / imageSize} ${averageWidth / imageSize} ${averageHeight / imageSize}');
      }
    }

    return tiles;
  }

  List<Tile> _sort(List<Tile> tiles) {
    for (int i = 0; i < tiles.length; i++) {
      for (int j = i + 1; j < tiles.length; j++) {
        if (tiles.elementAt(i).compareTo(tiles.elementAt(j)) == 1) {
          Tile temp = tiles.elementAt(i);
          tiles[i] = tiles.elementAt(j);
          tiles[j] = temp;
        }
      }
    }
    return tiles;
  }

  /// Gets a single tile based on its coordinates on the board.
  Tile _getTile(double xMid, double yMid) {
    Tile temp = Tile("none", xMid.toDouble(), yMid.toDouble(),
        averageWidth.toDouble(), averageHeight.toDouble(), 0, true);
    for (Tile tile in board) {
      if (tile.inTile(temp)) {
        return tile;
      }
    }
    return temp;
  }

  /// Checks if (x, y) on a board contains a tile.
  bool _containsTile(double xMid, double yMid) {
    if (_getTile(xMid, yMid).label != "none") {
      return true;
    }
    return false;
  }

  /// Removes extra tiles if there are multiple in the same (x, y) location on
  /// a board. Ideally this never happens, but tests of the mod reveal that
  /// there may be misdetections where a tile is detected as multiple types.
  void _handleCollisions() {
    int x = 0;
    int y = 0;
    int stop = board.length;
    while (x < stop) {
      y = 0;
      while (y < stop) {
        if (x == y) {
          y += 1;
          continue;
        }
        if (board.elementAt(x).inTile(board.elementAt(y))) {
          List<int> options = [x, y];
          int choice = Random().nextInt(options.length);
          board.removeAt(options.elementAt(choice));
          stop -= 1;
        }
        y += 1;
      }
      List<Tile> adjacentTiles = _getAdjacentTiles(board.elementAt(x));
      for (Tile tile in adjacentTiles) {
        if (tile == board.elementAt(x)) {
          board[x] = Tile(
              tile.label,
              (tile.xMax - (averageWidth / 2.0)).toDouble(),
              (tile.yMax - (averageHeight / 2.0)).toDouble(),
              averageWidth.toDouble(),
              averageHeight.toDouble(),
              640,
              true);
        }
      }
      x += 1;
    }
  }

  /// Adds an "empty" tile to any grid location in board that is empty.
  void _addEmptyTiles() {
    for (int y = 0; y < numRows; y++) {
      for (int x = 0; x < numCols; x++) {
        double nextX = minX + (averageWidth * x);
        double nextY = minY + (averageHeight * y);
        if (!_containsTile(nextX, nextY)) {
          Tile newTile = Tile("empty", nextX.toDouble(), nextY.toDouble(),
              averageWidth.toDouble(), averageHeight.toDouble(), 0, true);
          board.insert(y * numCols + x, newTile);
          y = 0;
          x = 0;
        }
      }
    }
  }

  /// Calculates the score for each tile then sums it up.
  void _calculateScore() {
    for (int y = 0; y < numRows; y++) {
      for (int x = 0; x < numCols; x++) {
        Tile tile = board.elementAt(y * numCols + x);
        _countAdjacent(tile);
        totalScore += tile.score;
      }
    }
  }

  /// Given a tile, finds all tiles of that region and populates the score
  /// for each of them.
  void _countAdjacent(Tile startingTile) {
    if (!startingTile.explored && startingTile.label != "empty") {
      // if either of these are false, score has already been populated
      List<Tile> newTiles = [startingTile];
      Set<Tile> explored = {};
      List<Tile> sameRegions = [];
      int numCrowns = 0;

      while (newTiles.isNotEmpty) {
        // continue until no new tiles explored
        Tile currentTile = newTiles.removeLast();
        if (!explored.contains(currentTile)) {
          explored.add(currentTile);
          if (currentTile.region == startingTile.region) {
            // add score to population
            sameRegions.add(currentTile);
            numCrowns += currentTile.crowns;
            List<Tile> adjacentTiles = _getAdjacentTiles(currentTile);
            for (Tile tile in adjacentTiles) {
              if (tile.region == startingTile.region) {
                newTiles.add(tile);
              }
            }
          }
        }
      }

      for (Tile tile in sameRegions) {
        tile.addCrowns(numCrowns);
        tile.explored = true;
      }
    }
  }

  void rotateClockwise() {
    List<Tile> newBoard = [];
    for (int x = 0; x < numCols; x++) {
      for (int y = numRows - 1; y >= 0; y--) {
        newBoard.add(board.elementAt(y * numCols + x));
      }
    }
    board = newBoard;
  }

  HashMap<String, int> getStatistics() {
    HashMap<String, int> stats = HashMap();
    for (Tile tile in board) {
      if (tile.region == 'empty') {
        continue;
      } else if (stats.containsKey(tile.region + 'Score')) {
        stats[tile.region + 'Score'] =
            stats[tile.region + 'Score']! + tile.score;
        stats[tile.region + 'Tiles'] = stats[tile.region + 'Tiles']! + 1;
      } else {
        stats[tile.region + 'Score'] = tile.score;
        stats[tile.region + 'Tiles'] = 1;
      }
    }
    stats.putIfAbsent('wheatScore', () => 0);
    stats.putIfAbsent('forestScore', () => 0);
    stats.putIfAbsent('caveScore', () => 0);
    stats.putIfAbsent('graveyardScore', () => 0);
    stats.putIfAbsent('plainsScore', () => 0);
    stats.putIfAbsent('waterScore', () => 0);
    stats.putIfAbsent('wheatTiles', () => 0);
    stats.putIfAbsent('forestTiles', () => 0);
    stats.putIfAbsent('caveTiles', () => 0);
    stats.putIfAbsent('graveyardTiles', () => 0);
    stats.putIfAbsent('plainsTiles', () => 0);
    stats.putIfAbsent('waterTiles', () => 0);

    return stats;
  }

  /// Will get all legal adjacent tiles to a tile.
  List<Tile> _getAdjacentTiles(Tile tile) {
    double xMid = tile.xMin + (averageWidth / 2.0);
    double yMid = tile.yMin + (averageHeight / 2.0);
    List<Tile> adjacentTiles = [];
    if (_containsTile(xMid + averageWidth, yMid)) {
      adjacentTiles.add(_getTile(xMid + averageWidth, yMid));
    }
    if (_containsTile(xMid - averageWidth, yMid)) {
      adjacentTiles.add(_getTile(xMid - averageWidth, yMid));
    }
    if (_containsTile(xMid, yMid + averageHeight)) {
      adjacentTiles.add(_getTile(xMid, yMid + averageHeight));
    }
    if (_containsTile(xMid, yMid - averageHeight)) {
      adjacentTiles.add(_getTile(xMid, yMid - averageHeight));
    }
    return adjacentTiles;
  }
}
