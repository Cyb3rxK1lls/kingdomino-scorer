import 'package:flutter/material.dart';

class Tile {
  String label = "";
  int crowns = 0;
  int score = 0;
  int xMin = 0;
  int xMax = 0;
  int yMin = 0;
  int yMax = 0;
  double xMid = 0;
  double yMid = 0;
  bool explored = false;

  Tile(this.label, double xCenter, double yCenter, double tileWidth,
      double tileHeight, int imageWidth, int imageHeight) {
    if (label == "empty" || label == "none") {
      xMid = xCenter;
      yMid = yCenter;
    } else {
      crowns = int.parse(label.characters.elementAt(label.length - 1));
      xMid = xCenter * imageWidth;
      yMid = yCenter * imageHeight;
      tileWidth *= imageWidth;
      tileHeight *= imageHeight;
    }

    xMin = (xMid - (tileWidth / 2)).toInt();
    xMax = (xMid + (tileWidth / 2)).toInt();
    yMin = (yMid - (tileHeight / 2)).toInt();
    yMax = (yMid + (tileHeight / 2)).toInt();
  }

  /// Sorted by linearized order
  int compareTo(Tile other) {
    if (equals(other)) {
      return 0;
    } else {
      if (yMin <= other.yMid && other.yMid <= yMax) {
        // in same row => compare x values
        if (xMid > other.xMid) {
          return 1;
        } else {
          return -1;
        }
      } else {
        if (yMid > other.yMid) {
          return 1;
        } else {
          return -1;
        }
      }
    }
  }

  /// Equal should only consider tile position
  @override
  bool operator ==(Object other) =>
      other is Tile && other.runtimeType == runtimeType && inTile(other);

  /// Equality of tiles should only focus on tile location
  bool equals(Tile other) {
    return inTile(other);
  }

  @override
  int get hashCode =>
      xMin.hashCode + xMax.hashCode + yMin.hashCode + yMax.hashCode;

  /// Checks if there is another tile in this one.
  bool inTile(Tile other) {
    return (xMin <= other.xMid && other.xMid <= xMax) &&
        (yMin <= other.yMid && other.yMid <= yMax);
  }

  /// Adds to the number of crowns in the connecting region.
  void addCrowns(int amount) {
    score += amount;
  }

  /// The region of the tile (ignores crowns).
  String get region => label.split('_').elementAt(0);

  /// The width of the tile.
  int get width => xMax - xMin;

  /// The height of the tile.
  int get height => yMax - yMin;
}
