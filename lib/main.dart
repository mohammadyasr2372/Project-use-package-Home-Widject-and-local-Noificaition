import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:poject/home.dart';
import 'package:poject/local_notifications.dart';
import 'package:poject/web_socket.dart';
import 'package:workmanager/workmanager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

late WebSocketChannel channel;

/// Used for Background Updates using Workmanager Plugin
@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) {
    final now = DateTime.now();
    return Future.wait<bool?>([
      HomeWidget.saveWidgetData(
        'title',
        'Updated from Background',
      ),
      HomeWidget.saveWidgetData(
        'message',
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      ),
      HomeWidget.updateWidget(
        name: 'HomeWidgetExampleProvider',
        iOSName: 'HomeWidgetExample',
      ),
    ]).then((value) {
      return !value.contains(false);
    });
  });
}

/// Called when Doing Background Work initiated from Widget
@pragma("vm:entry-point")
Future<void> interactiveCallback(Uri? data) async {
  if (data?.host == 'titleclicked') {
    final greetings = [
      'Hello',
      'Hallo',
      'Bonjour',
      'Hola',
      'Ciao',
      '哈洛',
      '안녕하세요',
      'xin chào',
    ];
    final selectedGreeting = greetings[Random().nextInt(greetings.length)];
    await HomeWidget.setAppGroupId('YOUR_GROUP_ID');
    await HomeWidget.saveWidgetData<String>('title', selectedGreeting);
    await HomeWidget.updateWidget(
      name: 'HomeWidgetExampleProvider',
      iOSName: 'HomeWidgetExample',
    );
  }
}

void main() async {
  final wsUrl = Uri.parse('wss://socketsbay.com/wss/v2/1/demo/');
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotifications.init();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  channel = WebSocketChannel.connect(wsUrl);
  await channel.ready;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId('YOUR_GROUP_ID');
    HomeWidget.registerInteractivityCallback(interactiveCallback);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForWidgetLaunch();
    HomeWidget.widgetClicked.listen(_launchedFromWidget);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future _sendData() async {
    try {
      return Future.wait([
        HomeWidget.saveWidgetData<String>('title', _titleController.text),
        HomeWidget.saveWidgetData<String>('message', _messageController.text),
        HomeWidget.renderFlutterWidget(
          const Icon(
            Icons.flutter_dash,
            size: 400,
          ),
          logicalSize: const Size(400, 400),
          key: 'dashIcon',
        ),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Sending Data. $exception');
    }
  }

  Future _updateWidget() async {
    try {
      return HomeWidget.updateWidget(
        name: 'HomeWidgetExampleProvider',
        iOSName: 'HomeWidgetExample',
      );
    } on PlatformException catch (exception) {
      debugPrint('Error Updating Widget. $exception');
    }
  }

  Future _loadData() async {
    try {
      return Future.wait([
        HomeWidget.getWidgetData<String>('title', defaultValue: 'Default Title')
            .then((value) => _titleController.text = value ?? ''),
        HomeWidget.getWidgetData<String>(
          'message',
          defaultValue: 'Default Message',
        ).then((value) => _messageController.text = value ?? ''),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Getting Data. $exception');
    }
  }

  Future<void> _sendAndUpdate() async {
    await _sendData();
    await _updateWidget();
  }

  void _checkForWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget);
  }

  void _launchedFromWidget(Uri? uri) {
    if (uri != null) {
      showDialog(
        context: context,
        builder: (buildContext) => AlertDialog(
          title: const Text('App started from HomeScreenWidget'),
          content: Text('Here is the URI: $uri'),
        ),
      );
    }
  }

  void _startBackgroundUpdate() {
    Workmanager().registerPeriodicTask(
      '1',
      'widgetBackgroundUpdate',
      frequency: const Duration(minutes: 15),
    );
  }

  void _stopBackgroundUpdate() {
    Workmanager().cancelByUniqueName('1');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeWidget Example'),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Title',
              ),
              controller: _titleController,
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Body',
              ),
              controller: _messageController,
            ),
            ElevatedButton(
              onPressed: _sendAndUpdate,
              child: const Text('Send Data to Widget'),
            ),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Load Data'),
            ),
            ElevatedButton(
              onPressed: _checkForWidgetLaunch,
              child: const Text('Check For Widget Launch'),
            ),
            if (Platform.isAndroid)
              ElevatedButton(
                onPressed: _startBackgroundUpdate,
                child: const Text('Update in background'),
              ),
            if (Platform.isAndroid)
              ElevatedButton(
                onPressed: _stopBackgroundUpdate,
                child: const Text('Stop updating in background'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Homepage()));
              },
              child: const Text('Check For noification'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WebSocketView()));
              },
              child: const Text('Check For WebSocketView'),
            ),
          ],
        ),
      ),
    );
  }
}
