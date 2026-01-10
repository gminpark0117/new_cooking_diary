import 'package:flutter/material.dart';
import 'package:new_cooking_diary/diary_page.dart';
import 'package:new_cooking_diary/recipe_page.dart';
import 'recipe_page.dart';
import 'diary_page.dart';
import 'cart_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB65A2C)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB65A2C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  // final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // pages[0]이 탭1이라서 기본화면이 탭1
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  // 탭 눌렀을 때 바꾸는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    final pages = <Widget>[
      // 임시용
      //const Center(child: Text('레시피 탭 화면')),
      //const Center(child: Text('요리 기록 탭 화면')),
      //const Center(child: Text('장바구니 탭 화면')),
      const RecipePage(),
      const DiaryPage(),
      const CartPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 86,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 왼쪽 로고 아이콘
            Image.asset(
              'assets/icon/app_icon.png',
              width: 58,
              height: 58, // 이 2개로 크기 조절 가능
              color: Colors.white,
            ),

            const SizedBox(width: 12),

            // 앱바 앱 이름
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '쿠킹 다이어리',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '나만의 요리 레시피 기록',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFB65A2C),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: '레시피',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: '요리 기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: '장바구니',
          ),
        ],
      ),
    );
  }
}