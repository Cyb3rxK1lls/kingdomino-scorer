import 'package:flutter/material.dart';
import 'package:kingdomino_score_calculator/tile.dart';

// ignore: must_be_immutable
class TileWidget extends StatefulWidget {
  Tile tile;
  TileWidget({Key? key, required this.tile}) : super(key: key);
  @override
  _TileWidgetState createState() => _TileWidgetState();

  String getLabel() {
    return tile.label;
  }
}

class _TileWidgetState extends State<TileWidget> {
  bool _new = true;
  Image _image = Image.asset("assets/images/empty.png");
  _TileWidgetState();

  @override
  Widget build(BuildContext context) {
    if (_new) {
      _image = Image.asset("assets/images/" + widget.tile.label + ".png");
      _new = false;
    }
    var ret = DragTarget<String>(
      builder: (
        BuildContext context,
        List<dynamic> accepted,
        List<dynamic> rejected,
      ) {
        return _image;
      },
      onWillAccept: (data) {
        return true;
      },
      onAccept: (data) {
        setState(() {
          widget.tile.label = data;
          _image = Image.asset("assets/images/" + data + ".png");
        });
      },
    );
    return ret;
  }
}
