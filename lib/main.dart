import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "./firstpage.dart";

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Color(0xffb65a2c)),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: TitleCard()
      ),
      body: Center(
        child: MainColumn(),
      ),
    );
  }
}




// 안써요 이거. 나중에 바꿈.
class TitleCard extends StatelessWidget {
  const TitleCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
            children: [
              Icon(
                Icons.local_dining,
              ),
              Text("쿠킹 다이어리"),
            ]
        ),
        Text("나만의 요리 레시피와 기록"),
      ],
    );
  }
}
