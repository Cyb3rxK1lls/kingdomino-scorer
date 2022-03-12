import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kingdomino_score_calculator/board.dart';
import 'package:kingdomino_score_calculator/tile.dart';
import 'package:kingdomino_score_calculator/tile_widget.dart';

enum Status { success, loadFailure, noDetections }

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
  final String _url =
      "http://10.0.2.2:5000/file"; //10.0.2.2 while using emulator
  final ImagePicker _picker = ImagePicker();
  final int imageSize = 640;
  bool _loaded = false;
  bool _loading = false;
  Status status = Status.noDetections;
  String mainText = "";
  List<String> classes = [];
  List<Tile> tiles = [];
  Board board = Board([]);
  List<Widget> wtiles = [];

  _MyHomePageState() {
    _loadClasses();
    _refreshMainText();
    // board = Board([Tile('empty', .5, .5, .5, .5, 2, 2)]);
  }

  /// adjusts the main text and size accordingly
  void _refreshMainText() {
    switch (status) {
      case Status.success:
        if (_loading) {
          mainText = "loading...";
        } else {
          mainText = "Score: " + board.totalScore.toString();
        }
        break;

      case Status.loadFailure:
        mainText = "failed to load image... retry.";
        break;

      case Status.noDetections:
        if (_loading) {
          mainText = "loading...";
        } else if (_loaded) {
          mainText = "Found no tiles.";
        } else {
          mainText = "Select image from gallery";
        }
        break;
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
        tiles.add(Tile(label, xMid, yMid, width, height, imageSize, imageSize));
      }
    }

    setState(() {
      _loading = false;
      _loaded = true;
      switch (resultStatus) {
        case 200:
          status = Status.success;
          board = Board(tiles);
          wtiles = [];
          for (Tile tile in board.board) {
            wtiles.add(TileWidget(tile: tile));
          }
          break;

        case 300:
          status = Status.noDetections;
          break;

        default:
          status = Status.loadFailure;
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
      return;
    }
    setState(() {
      _loaded = false;
      _loading = true;
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
      _loading = false;
      _loaded = false;
      _refreshMainText();
      wtiles = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double imageSize =
        min(screenWidth / board.numCols, screenHeight / board.numRows);
    List<Widget> widgets = [];
    widgets.add(Text(
      mainText,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 42),
    ));
    if (status == Status.success) {
      widgets.insert(
          0,
          Expanded(
              child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: imageSize,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                mainAxisExtent: imageSize),
            children: wtiles,
            shrinkWrap: true,
          )));
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
                icon: const Icon(Icons.remove_circle_outline_outlined),
                onPressed: clearBoard,
                tooltip: 'Clear Board',
                color: Colors.red),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: cameraPicture,
              tooltip: "Choose image from camera",
              color: Colors.green,
            )
          ],
        ));
  }
}
