import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kingdomino_score_calculator/board.dart';
import 'package:kingdomino_score_calculator/disk_manager.dart';
import 'package:kingdomino_score_calculator/history.dart';
import 'package:kingdomino_score_calculator/text_manager.dart';
import 'package:kingdomino_score_calculator/tile.dart';
import 'package:kingdomino_score_calculator/tile_widget.dart';

enum Mode { view, edit, history, regular, nul }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kingdomino Score Calculator - Beta',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //10.0.2.2 while using emulator, 10.129.16.113 if using device
  final String _url = "http://10.0.2.2:5000/file";
  // "http://10.129.16.113:8000/file";
  final ImagePicker _picker = ImagePicker();
  final int imageSize = 640;
  int _selectedHistoryItem = 0;
  bool pastGame = false;
  TextManager texter = TextManager(Status.noDetections, Loading.neither);
  DiskManager disker = DiskManager();
  Mode _mode = Mode.view;
  List<Tile> tiles = [];
  Board board = Board([]);
  List<Widget> tileWidgets = [];
  List<Widget> dragTiles = [];

  /// send image to flask server, receive list of detections
  void postRequest(XFile image) async {
    tiles = [];
    var request = http.MultipartRequest('POST', Uri.parse(_url));
    request.files.add(http.MultipartFile.fromBytes(
        'picture', await image.readAsBytes(),
        filename: image.name));

    var result = await request.send();
    String str = await result.stream.bytesToString();
    int resultStatus = int.parse(str.substring(str.length - 6, str.length - 3));
    if (resultStatus == 200) {
      // 200 ==> success, so process all new tiles
      String detectionsText = str.substring(15, str.length - 22);
      List<String> detections = detectionsText.split(',');
      for (String detection in detections) {
        List<String> components = detection.split(' ');
        String label =
            disker.labels.elementAt(int.parse(components.elementAt(0)));
        double xMid = double.parse(components.elementAt(1));
        double yMid = double.parse(components.elementAt(2));
        double width = double.parse(components.elementAt(3));
        double height = double.parse(components.elementAt(4));
        tiles.add(Tile(label, xMid, yMid, width, height, imageSize, false));
      }
    }

    setState(() {
      pastGame = false;
      switch (resultStatus) {
        case 200:
          board = Board(tiles);
          tileWidgets = [];
          for (Tile tile in board.board) {
            tileWidgets.add(TileWidget(tile: tile));
          }
          texter.update(
              status: Status.success,
              load: Loading.loaded,
              score: board.totalScore.toString());
          break;

        case 300:
          texter.update(status: Status.noDetections, load: Loading.loaded);
          break;

        default:
          texter.update(status: Status.loadFailure, load: Loading.loaded);
      }
    });
  }

  void loadGame(String filename) async {
    Board newBoard = await disker.loadGame(filename, imageSize);
    setState(() {
      _mode = Mode.view;
      board = newBoard;
      pastGame = true;
      tileWidgets = [];
      for (Tile tile in board.board) {
        tileWidgets.add(TileWidget(tile: tile));
      }
      texter.update(
          status: Status.success,
          load: Loading.loaded,
          score: board.totalScore.toString());
    });
  }

  void saveGame() async {
    disker.saveGame(board);
    setState(() {
      board = Board([]);
      texter.update(
          status: Status.noDetections,
          load: Loading.neither,
          recentlySaved: true);
    });
  }

  /// Choose an image from storage
  void chooseImage(ImageSource imgSource) async {
    var image = await _picker.pickImage(source: imgSource);
    if (image == null) {
      // null ==> user canceled their action
      return;
    }
    setState(() {
      _mode = Mode.view;
      texter.update(load: Loading.loading);
    });
    postRequest(XFile(image.path));
  }

  void galleryPicture() async {
    chooseImage(ImageSource.gallery);
  }

  void cameraPicture() async {
    chooseImage(ImageSource.camera);
  }

  /// Clear a board
  void clearBoard() {
    setState(() {
      _mode = Mode.view;
      tileWidgets = [];
      texter.update(status: Status.noDetections, load: Loading.neither);
    });
  }

  void _updateTiles() {
    setState(() {
      board.recalculateScore();
      texter.update(score: board.totalScore.toString());
    });
  }

  void _changeMode({Mode newMode = Mode.regular}) {
    setState(() {
      if (newMode == Mode.regular) {
        if (_mode == Mode.view) {
          _mode = Mode.edit;
        } else {
          _mode = Mode.view;
        }
      } else if (newMode == Mode.history) {
        _mode = newMode;
      }
    });
  }

  void _historyLoadMode() {
    _changeMode(newMode: Mode.history);
  }

  List<Widget> _createDraggableTiles(double size) {
    List<Widget> widgets = [];
    List<String> labels = disker.labels.toList();
    labels.sort();
    labels.remove('empty');
    for (String label in labels) {
      Draggable<String> drag = Draggable<String>(
        // Data is the value this Draggable stores.
        data: label,
        child: getDraggableBox(label, size),
        feedback: getDraggableBox(label, size),
        childWhenDragging: getDraggableBox('empty', size),
        onDragCompleted: () {
          _updateTiles();
        },
      );
      widgets.add(drag);
    }
    return widgets;
  }

  Widget getDraggableBox(String label, double size) {
    return SizedBox(
        height: size,
        width: size,
        child: Center(
          child: Image.asset('assets/images/' + label + '.png'),
        ));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double imageSize =
        min(screenWidth / board.numCols, screenHeight / board.numRows);
    double dragSize = min(screenWidth, screenHeight) / 8.0;
    if (dragTiles.isEmpty && tiles.isNotEmpty) {
      dragTiles = _createDraggableTiles(dragSize);
    }

    List<Widget> widgets = [];
    List<Widget> buttons = [];
    if (_mode != Mode.history) {
      buttons.add(IconButton(
        icon: const Icon(Icons.image_search),
        onPressed: galleryPicture,
        tooltip: 'Choose image from gallery',
        color: Colors.green,
      ));
      buttons.add(IconButton(
        icon: const Icon(Icons.camera_alt),
        onPressed: cameraPicture,
        tooltip: "Choose image from camera",
        color: Colors.green,
      ));
      buttons.add(IconButton(
          icon: const Icon(Icons.read_more),
          onPressed: _historyLoadMode,
          tooltip: 'Load past game',
          color: Colors.green));
      if (texter.getStatus == Status.success) {
        // success ==> display board
        widgets.add(Expanded(
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: imageSize,
              mainAxisExtent: imageSize,
              crossAxisSpacing: 1.0,
              mainAxisSpacing: 1.0,
            ),
            children: tileWidgets,
            shrinkWrap: true,
          ),
          flex: 7,
        ));
        buttons.add(IconButton(
            icon: const Icon(Icons.remove_circle_outline_outlined),
            onPressed: clearBoard,
            tooltip: 'Clear Board',
            color: Colors.red));
        if (!pastGame) {
          buttons.add(IconButton(
              icon: Icon(_mode == Mode.view ? Icons.edit : Icons.save_alt),
              onPressed: _changeMode,
              tooltip: _mode == Mode.view ? "View board" : "Edit board",
              color: Colors.blue));
        }
      }
      if (_mode == Mode.view) {
        int _flex = texter.getStatus != Status.success ? 0 : 1;
        widgets.add(Expanded(
          child: Text(
            texter.getText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 42),
          ),
          flex: _flex,
        ));
        if (texter.getStatus == Status.success && !pastGame) {
          buttons.add(IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: saveGame,
              tooltip: 'Save game',
              color: Colors.blue));
        }
      } else if (_mode == Mode.edit) {
        widgets.add(Expanded(
            child: GridView(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: dragSize,
                mainAxisExtent: dragSize,
                crossAxisSpacing: 1.0,
                mainAxisSpacing: 1.0,
              ),
              children: dragTiles,
              shrinkWrap: true,
            ),
            flex: 0));
      }
    } else {
      List<Map> data = [];
      for (History game in disker.history) {
        data.add({'name': game.name, 'score': game.score});
      }
      widgets.add(ListView.builder(
        itemBuilder: (builder, index) {
          Map game = data[index];
          return ListTile(
            title: Text('${game['name']}'),
            leading: CircleAvatar(child: Text('${game['score']}')),
            tileColor:
                index == _selectedHistoryItem ? Colors.green : Colors.white,
            onTap: () {
              setState(() {
                _selectedHistoryItem = index;
              });
            },
          );
        },
        itemCount: data.length,
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
      ));
      buttons.add(IconButton(
          icon: const Icon(Icons.remove_circle_outline_outlined),
          onPressed: _changeMode,
          tooltip: 'Exit Loading',
          color: Colors.red));
      if (disker.history.isNotEmpty) {
        buttons.add(IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: () =>
                loadGame(disker.history[_selectedHistoryItem].name),
            tooltip: 'Use this game',
            color: Colors.green));
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Kingdomino Scorer - Beta',
          ),
        ),
        body: Center(
          child: _mode == Mode.history
              ? Expanded(child: widgets[0])
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widgets,
                ),
        ),
        bottomNavigationBar:
            ButtonBar(alignment: MainAxisAlignment.center, children: buttons));
  }
}
