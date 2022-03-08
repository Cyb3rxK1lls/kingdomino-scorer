import 'package:flutter/material.dart';
import 'package:kingdomino_score_calculator/tile.dart';

class TileWidget extends StatefulWidget {
  final Tile tile;
  const TileWidget({Key? key, required this.tile}) : super(key: key);
  @override
  _TileWidgetState createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget> {
  _TileWidgetState();
  @override
  Widget build(BuildContext context) {
    return Image.asset("assets/images/" + widget.tile.label + ".png");
  }
}
