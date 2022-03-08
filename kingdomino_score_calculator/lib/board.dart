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
        averageWidth.toDouble(), averageHeight.toDouble(), 0, 0);
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
              averageWidth.toDouble(), averageHeight.toDouble(), 0, 0);
          board.insert(y * numCols + x, newTile);
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

  /// Will get all legal adjacent tiles to a tile.
  List<Tile> _getAdjacentTiles(Tile tile) {
    List<Tile> adjacentTiles = [];
    if (_containsTile(tile.xMid + averageWidth, tile.yMid)) {
      adjacentTiles.add(_getTile(tile.xMid + averageWidth, tile.yMid));
    }
    if (_containsTile(tile.xMid - averageWidth, tile.yMid)) {
      adjacentTiles.add(_getTile(tile.xMid - averageWidth, tile.yMid));
    }
    if (_containsTile(tile.xMid, tile.yMid + averageHeight)) {
      adjacentTiles.add(_getTile(tile.xMid, tile.yMid + averageHeight));
    }
    if (_containsTile(tile.xMid, tile.yMid - averageHeight)) {
      adjacentTiles.add(_getTile(tile.xMid, tile.yMid - averageHeight));
    }
    return adjacentTiles;
  }
}
