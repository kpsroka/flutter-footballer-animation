import 'package:flutter/material.dart';
import './stickman.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  bool _isPaused = true;
  AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
  }

  @override
  dispose() {
    animationController.dispose();
    super.dispose();
  }

  void _pause() {
    setState(() {
      _isPaused = true;
      animationController.stop();
    });
  }

  void _run() {
    setState(() {
      _isPaused = false;
      animationController.repeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 100,
              height: 150,
              child: Stickman(animationController: animationController),
            ),
            Icon(_isPaused ? Icons.directions_walk : Icons.directions_run,
                color: Colors.purple.withAlpha(127)),
            Text(_isPaused ? "paused" : "running"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isPaused ? _run : _pause,
        tooltip: 'Pause',
        child: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
