// ignore_for_file: unrelated_type_equality_checks

import 'dart:isolate';
import 'dart:ui';

import 'package:download/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Plugin must be initialized before using
  await FlutterDownloader.initialize(
      // optional: set to false to disable printing logs to console (default: true)
      );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(
        title: 'Flutter Download Files',
        platform: Theme.of(context).platform,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ReceivePort _port = ReceivePort();
  double progress = 0;

  downloadingCallback(
    id,
    status,
    progress,
  ) {
    /// looking up for a send port
    SendPort? senderPort = IsolateNameServer.lookupPortByName("downloading");

    /// sending the data
    senderPort!.send([id, status, progress]);
  }

  @override
  void initState() {
    super.initState();

    // register a send port for the other isolate
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloading');

    // listening for the data is coming other isolates

    _port.listen((message) {
      String id = message[0];
      DownloadTaskStatus status = message[1];
      int progress = message[2];
      setState(() {});
      if (status == DownloadTaskStatus.complete && progress == 100) {
        // Download completed and progress is 100%
        // Add your code here to handle the completion event
        // For example, you can show a success message or navigate to a new screen
        print('Download completed');
      }
    });
    FlutterDownloader.registerCallback(
      downloadingCallback,
    );
  }

  void downloadCallback(String id, int status, int progress) {
    SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$progress',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: download,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  download() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final externalDir = await getExternalStorageDirectory();
      final taskId = await FlutterDownloader.enqueue(
        url: 'https://team11nepal.com/downloads/team11.apk',
        headers: {}, // optional: header send with url (auth token etc)
        savedDir: externalDir!.path,
        fileName: 'Sagar',
        showNotification:
            true, // show download progress in status bar (for Android)
        openFileFromNotification: true,

        // click on notification to open downloaded file (for Android)
      );

      FlutterDownloader.open(taskId: taskId ?? '');
      FlutterDownloader.pause(taskId: taskId ?? '');
    } else {
      print("Permission deined");
    }
  }
}
