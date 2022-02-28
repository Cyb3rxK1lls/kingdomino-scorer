import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kingdomino Score Calculator',
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
  String _tiles = "";
  bool _loaded = false;
  final ImagePicker _picker = ImagePicker();

  /// send image to flask server, receive list of detections
  void postRequest(XFile image) async {
    _loaded = true;
    var request = http.MultipartRequest('POST', Uri.parse(_url));
    request.files.add(http.MultipartFile.fromBytes(
        'picture', await image.readAsBytes(),
        filename: image.name));

    var result = await request.send();
    _tiles = await result.stream.bytesToString();
    setState(() {
      _loaded = true;
    });
  }

  /// Choose an image from storage
  void chooseImage() async {
    setState(() {
      _loaded = false;
    });
    var image = await _picker.pickImage(source: ImageSource.gallery);
    postRequest(XFile(image!.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kingdomino Score Calculator'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Select image from gallery',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            Text(_loaded ? _tiles : ""),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: chooseImage,
        tooltip: 'Choose Image',
        child: const Icon(Icons.image_search),
      ),
    );
  }
}
