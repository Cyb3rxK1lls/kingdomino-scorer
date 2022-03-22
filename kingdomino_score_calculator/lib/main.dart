import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kingdomino_score_calculator/board.dart';
import 'package:kingdomino_score_calculator/tile.dart';
import 'package:kingdomino_score_calculator/tile_widget.dart';

enum Status { success, loadFailure, noDetections }
enum Loading { loading, loaded, neither }
enum Mode { view, edit }

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
  Loading _load = Loading.neither;
  Status _status = Status.noDetections;
  Mode _mode = Mode.view;
  String mainText = "";
  List<String> classes = [];
  List<Tile> tiles = [];
  Board board = Board([]);
  List<Widget> tileWidgets = [];
  List<Widget> dragTiles = [];

  _MyHomePageState() {
    _load = Loading.neither;
    _status = Status.noDetections;
    _loadClasses();
    _refreshMainText();
  }

  /// adjusts the main text and size accordingly
  void _refreshMainText() {
    if (_load == Loading.loading) {
      mainText = "loading...";
    } else {
      switch (_status) {
        case Status.success:
          mainText = "Score: " + board.totalScore.toString();
          break;

        case Status.loadFailure:
          mainText = "failed to load image... retry.";
          break;

        case Status.noDetections:
          if (_load == Loading.loaded) {
            mainText = "Found no tiles.";
          } else {
            mainText = "Select or take picture";
          }
          break;
      }
    }
  }

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
            classes.elementAt(int.parse(components.elementAt(0))).trim();
        double xMid = double.parse(components.elementAt(1));
        double yMid = double.parse(components.elementAt(2));
        double width = double.parse(components.elementAt(3));
        double height = double.parse(components.elementAt(4));
        tiles.add(Tile(
            label, xMid, yMid, width, height, imageSize, imageSize, false));
      }
    }

    setState(() {
      _load = Loading.loaded;
      switch (resultStatus) {
        case 200:
          _status = Status.success;
          board = Board(tiles);
          tileWidgets = [];
          for (Tile tile in board.board) {
            tileWidgets.add(TileWidget(tile: tile));
          }
          break;

        case 300:
          _status = Status.noDetections;
          break;

        default:
          _status = Status.loadFailure;
      }
      _refreshMainText();
    });
  }

  void _loadClasses() async {
    String classesText = await rootBundle.loadString('assets/classes.txt');
    classes = classesText.split('\n');
  }

  /// Choose an image from storage
  void chooseImage(ImageSource imgSource) async {
    var image = await _picker.pickImage(source: imgSource);
    if (image == null) {
      // null ==> user canceled their action
      return;
    }
    setState(() {
      _load = Loading.loading;
      _mode = Mode.view;
      _refreshMainText();
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
      _load = Loading.neither;
      _status = Status.noDetections;
      _mode = Mode.view;
      tileWidgets = [];
      _refreshMainText();
    });
  }

  void _updateTiles() {
    setState(() {
      board.recalculateScore();
      _refreshMainText();
    });
  }

  void _changeMode() {
    setState(() {
      if (_mode == Mode.view) {
        _mode = Mode.edit;
      } else {
        _mode = Mode.view;
      }
    });
  }

  List<Widget> _createDraggableTiles(double size) {
    List<String> labels = [
      'cave_0',
      'cave_1',
      'cave_2',
      'cave_3',
      'forest_0',
      'forest_1',
      'water_0',
      'water_1',
      'wheat_0',
      'wheat_1',
      'graveyard_0',
      'graveyard_1',
      'graveyard_2',
      'plains_0',
      'plains_1',
      'plains_2'
    ];
    List<Widget> widgets = [];
    for (String label in labels) {
      label.replaceAll('\n', '');
      if (label == '') {
        continue;
      }

      Draggable<String> drag = Draggable<String>(
        // Data is the value this Draggable stores.
        data: label,
        child: SizedBox(
          height: size,
          width: size,
          child: Center(
            child: Image.asset('assets/images/' + label + '.png'),
          ),
        ),
        feedback: SizedBox(
          height: size,
          width: size,
          child: Center(
            child: Image.asset('assets/images/' + label + '.png'),
          ),
        ),
        childWhenDragging: SizedBox(
          height: size,
          width: size,
          child: Center(
            child: Image.asset('assets/images/empty.png'),
          ),
        ),
        onDragCompleted: () {
          _updateTiles();
        },
      );
      widgets.add(drag);
    }
    return widgets;
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
    if (_status == Status.success) {
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
    }
    if (_mode == Mode.view) {
      int _flex = _status != Status.success ? 0 : 1;
      widgets.add(Expanded(
        child: Text(
          mainText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 42),
        ),
        flex: _flex,
      ));
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

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Kingdomino Scorer - Beta',
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widgets,
          ),
        ),
        bottomNavigationBar: ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.image_search),
              onPressed: galleryPicture,
              tooltip: 'Choose image from gallery',
              color: Colors.green,
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: cameraPicture,
              tooltip: "Choose image from camera",
              color: Colors.green,
            ),
            IconButton(
                icon: Icon(_mode == Mode.view ? Icons.edit : Icons.save_alt),
                onPressed: _changeMode,
                tooltip: _mode == Mode.view ? "view board" : "edit board",
                color: Colors.blue),
            IconButton(
                icon: const Icon(Icons.remove_circle_outline_outlined),
                onPressed: clearBoard,
                tooltip: 'Clear Board',
                color: Colors.red),
          ],
        ));
  }
}
