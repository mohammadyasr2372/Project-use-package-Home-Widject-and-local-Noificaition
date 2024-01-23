// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:poject/local_notifications.dart';
import 'package:poject/main.dart';

class WebSocketView extends StatelessWidget {
  const WebSocketView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: channel.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _sendData(snapshot.data!);
            _updateWidget();
            LocalNotifications.showSimpleNotification(
                title: 'this massage is come from the web',
                body: snapshot.data,
                payload: "This is simple data");
            return Text(snapshot.data.toString());
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class StremNumberView extends StatelessWidget {
  const StremNumberView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        semanticLabel: HomeWidget.groupId,
      ),
      body: StreamBuilder(
        stream: getStream(1000),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _sendData(snapshot.data ?? 0);
            _updateWidget();
            return Text(snapshot.data.toString());
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

Stream<num> getStream(int count) async* {
  for (num i = 2; i < count; i++) {
    await Future.delayed(const Duration(milliseconds: 31));
    yield i;
  }
}

Future _sendData(num id) async {
  try {
    return Future.wait([
      HomeWidget.saveWidgetData<String>('title', id.toString()),
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

Stream<num> Number() async* {
  num id = 0;
  await Future.delayed(const Duration(milliseconds: 30));
  id++;
  yield id;
}
