import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:camera_camera/camera_camera.dart';
import 'package:kingdomino_score_calculator/board.dart';
import 'package:kingdomino_score_calculator/disk_manager.dart';
import 'package:kingdomino_score_calculator/history.dart';
import 'package:kingdomino_score_calculator/stat_manager.dart';
import 'package:kingdomino_score_calculator/text_manager.dart';
import 'package:kingdomino_score_calculator/tile.dart';
import 'package:kingdomino_score_calculator/tile_widget.dart';

enum Mode { view, edit, history, stats, regular, camera }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      title: 'Kingdomino Score Calculator - Beta',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(
        camera: firstCamera,
      ),
    ),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.camera}) : super(key: key);
  final CameraDescription camera;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //10.0.2.2 while using emulator, 10.129.16.113 if using device
  final String _url = // "http://10.0.2.2:5000/file";
      "http://192.168.1.4:8000/file";

  final ImagePicker _picker = ImagePicker();
  final int imageSize = 640;
  int _selectedHistoryItem = 0;
  bool pastGame = false;
  TextManager texter = TextManager(Status.noDetections, Loading.neither);
  DiskManager disker = DiskManager();
  late StatManager statser = StatManager(disker);
  Mode _mode = Mode.view;
  List<Tile> tiles = [];
  Board board = Board([]);
  List<Widget> tileWidgets = [];
  List<Widget> dragTiles = [];
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  PreferredSizeWidget topBar = AppBar(
      title: const Text(
    'Kingdomino Scorer - Beta',
  ));

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// send image to flask server, receive list of detections
  void postRequest(XFile image) async {
    clearBoard(updateText: false);
    tiles = [];
    var request = http.MultipartRequest('POST', Uri.parse(_url));
    request.files.add(http.MultipartFile.fromBytes(
        'picture', await image.readAsBytes(),
        filename: image.name));

    print("sending request to " + _url);
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
      _changeMode(newMode: Mode.view);
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
    statser.saveGame(board);
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
    processImage(image);
  }

  void processImage(XFile image) {
    setState(() {
      _changeMode(newMode: Mode.view);
      texter.update(load: Loading.loading);
    });
    postRequest(XFile(image.path));
  }

  void galleryPicture() async {
    chooseImage(ImageSource.gallery);
  }

  void cameraPicture() {
    setState(() {
      _changeMode(newMode: Mode.camera);
    });
    // chooseImage(ImageSource.camera);
  }

  /// Clear a board
  void clearBoard({bool updateText = true}) {
    setState(() {
      _changeMode(newMode: Mode.view);
      tileWidgets = [];
      if (updateText) {
        texter.update(status: Status.noDetections, load: Loading.neither);
      }
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
      } else {
        _mode = newMode;
      }
    });
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

    if (_mode == Mode.camera) {
      // return just the camera, nothing else
      final scale = 1 /
          (_controller.value.aspectRatio *
              MediaQuery.of(context).size.aspectRatio);
      return Scaffold(
        appBar: topBar,
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // return CameraPreview(_controller);
              return Transform.scale(
                  scale: _controller.value.aspectRatio,
                  alignment: Alignment.center,
                  child: Stack(fit: StackFit.expand, children: [
                    CameraPreview(_controller),
                    cameraOverlay(padding: 80, color: const Color(0x55000000))
                  ]));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            try {
              await _initializeControllerFuture;
              final image = await _controller.takePicture();
              if (!mounted) return;

              // if the picture was taken, process it.
              processImage(image);
            } catch (e) {
              print(e);
            }
          },
          child: const Icon(Icons.camera_alt),
        ),
      );
    }

    List<Widget> widgets = [];
    List<Widget> buttons = [];
    if (_mode == Mode.history) {
      widgets.addAll(getHistoryWidgets());
      buttons.addAll(getHistoryButtons());
    } else if (_mode == Mode.stats) {
      widgets.addAll(getStatsWidgets());
      buttons.addAll(getStatsButtons());
    } else {
      if (texter.getStatus == Status.success) {
        // success ==> display board
        widgets.addAll(getSuccessWidgets(imageSize));
        buttons.addAll(getSuccessButtons());
      } else {
        buttons.addAll(getGeneralButtons());
      }
      if (_mode == Mode.view) {
        widgets.addAll(getViewWidgets());
        buttons.addAll(getViewButtons());
      } else if (_mode == Mode.edit) {
        widgets.addAll(getEditWidgets(dragSize));
      }
    }

    return Scaffold(
        appBar: topBar,
        body: Center(
          child: _mode == Mode.history
              ? Expanded(child: widgets[0])
              : Column(
                  mainAxisAlignment: _mode == Mode.stats
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
                  crossAxisAlignment: _mode == Mode.stats
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: widgets,
                ),
        ),
        bottomNavigationBar:
            ButtonBar(alignment: MainAxisAlignment.center, children: buttons));
  }

  // grabbed from https://stackoverflow.com/questions/56276522/square-camera-overlay-using-flutter
  Widget cameraOverlay({double? padding, Color? color}) {
    return LayoutBuilder(builder: (context, constraints) {
      double aspectRatio = constraints.maxWidth / constraints.maxHeight;
      double horizontalPadding;
      double verticalPadding;

      if (aspectRatio < 1) {
        horizontalPadding = padding!;
        verticalPadding =
            (constraints.maxHeight - (constraints.maxWidth - 2 * padding)) / 2;
      } else {
        verticalPadding = padding!;
        horizontalPadding =
            (constraints.maxWidth - (constraints.maxHeight - 2 * padding)) / 2;
      }

      return Stack(fit: StackFit.expand, children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Container(width: horizontalPadding, color: color)),
        Align(
            alignment: Alignment.centerRight,
            child: Container(width: horizontalPadding, color: color)),
        Align(
            alignment: Alignment.topCenter,
            child: Container(
                margin: EdgeInsets.only(
                    left: horizontalPadding, right: horizontalPadding),
                height: verticalPadding,
                color: color)),
        Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                margin: EdgeInsets.only(
                    left: horizontalPadding, right: horizontalPadding),
                height: verticalPadding,
                color: color)),
        Container(
          margin: EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: verticalPadding),
          decoration: BoxDecoration(border: Border.all(color: Colors.cyan)),
        )
      ]);
    });
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
        child: _getDraggableBox(label, size),
        feedback: _getDraggableBox(label, size),
        childWhenDragging: _getDraggableBox('empty', size),
        onDragCompleted: () {
          _updateTiles();
        },
      );
      widgets.add(drag);
    }
    return widgets;
  }

  Widget _getDraggableBox(String label, double size) {
    return SizedBox(
        height: size,
        width: size,
        child: Center(
          child: Image.asset('assets/images/' + label + '.png'),
        ));
  }

  List<Widget> getGeneralButtons() {
    List<Widget> buttons = [];
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
        icon: const Icon(Icons.history),
        onPressed: () => _changeMode(newMode: Mode.history),
        tooltip: 'Load past game',
        color: Colors.green));
    buttons.add(IconButton(
        icon: const Icon(Icons.read_more_outlined),
        onPressed: () => _changeMode(newMode: Mode.stats),
        tooltip: 'Load past game',
        color: Colors.green));
    return buttons;
  }

  List<Widget> getSuccessWidgets(double imageSize) {
    List<Widget> widgets = [];
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
    return widgets;
  }

  List<Widget> getSuccessButtons() {
    List<Widget> buttons = [];
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
    return buttons;
  }

  List<Widget> getViewWidgets() {
    List<Widget> widgets = [];
    int _flex = texter.getStatus != Status.success ? 0 : 1;
    widgets.add(Expanded(
      child: Text(
        texter.getText,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 42),
      ),
      flex: _flex,
    ));
    return widgets;
  }

  List<Widget> getViewButtons() {
    List<Widget> buttons = [];
    if (texter.getStatus == Status.success && !pastGame) {
      buttons.add(IconButton(
          icon: const Icon(Icons.save_rounded),
          onPressed: saveGame,
          tooltip: 'Save game',
          color: Colors.blue));
    }
    return buttons;
  }

  List<Widget> getEditWidgets(double dragSize) {
    List<Widget> widgets = [];
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
    return widgets;
  }

  List<Widget> getHistoryButtons() {
    List<Widget> buttons = [];
    buttons.add(IconButton(
        icon: const Icon(Icons.remove_circle_outline_outlined),
        onPressed: _changeMode,
        tooltip: 'Exit history view',
        color: Colors.red));
    if (disker.history.isNotEmpty) {
      buttons.add(IconButton(
          icon: const Icon(Icons.check_circle),
          onPressed: () => loadGame(disker.history[_selectedHistoryItem].name),
          tooltip: 'Use this game',
          color: Colors.green));
    }
    return buttons;
  }

  List<Widget> getHistoryWidgets() {
    List<Widget> widgets = [];
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
    return widgets;
  }

  List<Widget> getStatsButtons() {
    List<Widget> buttons = [];
    buttons.add(IconButton(
        icon: const Icon(Icons.remove_circle_outline_outlined),
        onPressed: _changeMode,
        tooltip: 'Exit stats view',
        color: Colors.red));
    return buttons;
  }

  List<Widget> getStatsWidgets() {
    List<Widget> widgets = [];
    for (String value in statser.getDisplayedStats()) {
      widgets.add(Text(
        value,
        textAlign: TextAlign.right,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
      ));
    }
    return widgets;
  }
}
