import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'diary_page.dart';
import 'cart_page/maincolumn.dart';
import "recipe_page/maincolumn.dart";
import "public_db/public_search.dart";
final publicRecipeSimilarity = PublicRecipeSimilarity.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await publicRecipeSimilarity.warmUp();
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB65A2C)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB65A2C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: GoogleFonts.nanumGothicTextTheme(),
      ),
      home: const MyHomePage(),
    );
  }
}


class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  int _selectedIndex = 0; // pages[0]이 탭1이라서 기본화면이 탭1


  // 탭 눌렀을 때 바꾸는 함수
  void _onItemTapped(int index) {
    if (index == 0) {
      ref.read(tab0TapTokenProvider.notifier).state++;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {


    final pages = <Widget>[
      // 임시용
      //const Center(child: Text('레시피 탭 화면')),
      //const Center(child: Text('요리 기록 탭 화면')),
      //const Center(child: Text('장바구니 탭 화면')),
      const RecipePageMainColumn(),
      const DiaryPage(),
      const CartPageMainColumn(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 86,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(8),
          ),
        ),
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
                  '국자와 연필',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '오늘은 어떤 요리를 만들었나요?',
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
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

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
            icon: Icon(Icons.edit),
            label: '로그',
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
