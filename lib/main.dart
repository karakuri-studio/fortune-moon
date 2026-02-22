import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MoonPhaseOracleApp());
}

/* =========================================
   Karakuri Studio / Design System Setup
   ========================================= */
class AppColors {
  static const spaceBg = Color(0xFF070A13);
  static const winBg = Color(0xD90A0F19); // rgba(10, 15, 25, 0.85)
  static const gold = Color(0xFFD4AF37);
  static const silver = Color(0xFFA0AAB5);
  static const textMain = Color(0xFFF0F4F8);
  static const textDim = Color(0xFF7A8A9E);
  static const accent = Color(0xFFB33939);
  static const cardBg = Color(0xCC0F141E); // rgba(15, 20, 30, 0.8)
}

class AppTextStyles {
  static const title = TextStyle(
    fontFamily: 'serif',
    color: AppColors.gold,
    letterSpacing: 4.0,
  );
  static const main = TextStyle(fontFamily: 'serif', color: AppColors.textMain);
  static const ui = TextStyle(
    fontFamily: 'sans-serif',
    color: AppColors.silver,
    letterSpacing: 1.5,
  );
}

/* =========================================
   KarakuriCore Module (Mock Implementation)
   ========================================= */
class KarakuriCore {
  bool haptics = true;
  String lang = 'ja';
  int usageCount = 0;

  void init() {
    // 実際の運用では shared_preferences 等を使用してローカルデータを復元します
  }

  void vibrate({String type = 'light'}) {
    if (!haptics) return;
    switch (type) {
      case 'light':
        HapticFeedback.lightImpact();
        break;
      case 'medium':
        HapticFeedback.mediumImpact();
        break;
      case 'heavy':
        HapticFeedback.heavyImpact();
        break;
      case 'success':
        HapticFeedback.vibrate();
        break;
      default:
        HapticFeedback.selectionClick();
    }
  }

  void toggleHaptics() {
    haptics = !haptics;
    if (haptics) vibrate(type: 'medium');
  }

  void track(String event, [dynamic data]) {
    debugPrint('[Karakuri Tracker] $event: $data');
  }

  int saveRecord() {
    usageCount++;
    return usageCount;
  }

  void clearData(VoidCallback onSuccess) {
    usageCount = 0;
    onSuccess();
  }
}

/* =========================================
   Domain Logic (Fortune Engine)
   ========================================= */
class FortuneEngine {
  static int getMoonPhase(DateTime date) {
    const lp = 2551443;
    final newMoon = DateTime.utc(1970, 1, 7, 20, 35, 0).millisecondsSinceEpoch;
    final phase = (date.millisecondsSinceEpoch - newMoon) % lp;
    return ((phase / lp) * 28).floor() + 1;
  }

  static Map<String, String>? getSunSignInfo(DateTime? date) {
    if (date == null) return null;
    int month = date.month;
    int day = date.day;
    List<int> dates = [20, 19, 21, 20, 21, 21, 23, 23, 23, 23, 22, 22];
    List<Map<String, String>> signs = [
      {"name": "山羊座", "element": "土"},
      {"name": "水瓶座", "element": "風"},
      {"name": "魚座", "element": "水"},
      {"name": "牡羊座", "element": "火"},
      {"name": "牡牛座", "element": "土"},
      {"name": "双子座", "element": "風"},
      {"name": "蟹座", "element": "水"},
      {"name": "獅子座", "element": "火"},
      {"name": "乙女座", "element": "土"},
      {"name": "天秤座", "element": "風"},
      {"name": "蠍座", "element": "水"},
      {"name": "射手座", "element": "火"},
    ];
    int index = day > dates[month - 1] ? month : month - 1;
    return signs[index % 12];
  }

  static Map<String, dynamic>? getDetailedReport(
    String phaseName,
    Map<String, String>? signInfo,
  ) {
    if (signInfo == null) return null;
    Map<String, String> elementAdvice = {
      "火": "情熱と直感を司る「火」の属性を持つあなた。今日は特に「最初のひらめき」を信じて即座に行動に移すことで、月の神託を最大限に活かせます。",
      "土":
          "現実感覚と安定を司る「土」の属性を持つあなた。今日は論理的な思考よりも、「五感で心地よいと感じること」を基準に選択をしてみてください。",
      "風":
          "知性とコミュニケーションを司る「風」の属性を持つあなた。今日は「新鮮な情報」と「多様な人との軽やかな対話」が、停滞を打ち破る起爆剤になります。",
      "水":
          "感情と深い共感を司る「水」の属性を持つあなた。今日は理屈や効率はいったん脇に置き、「心の底から湧き上がる感情」を最優先して自分を癒してください。",
    };

    Map<String, Map<String, dynamic>> reports = {
      "新月": {
        "work": "新しいサイクルの始まり。過去にとらわれず、全く新しいアプローチや企画を立ち上げるのに最適なタイミングです。",
        "love": "出会い運が刷新される時期。新しい環境に足を踏み入れることで、価値観の合う人との縁が繋がりやすくなります。",
        "self": "深いデトックスとリセットの時。新しい気を取り込むために、まずは心身の不要なものを手放しましょう。",
        "power": 80,
      },
      "満月": {
        "work": "これまでの努力が実を結び、一つのピークを迎えます。成果をしっかりと受け取り、感謝を忘れないでください。",
        "love": "感情が最大限に高まる日。ロマンチックな時間を過ごせる一方で、衝動的な衝突には気をつけて。",
        "self": "気が満ち溢れ、少し興奮状態になりやすいです。質の高い睡眠をとることを最優先に。",
        "power": 100,
      },
    };
    Map<String, dynamic> baseReport =
        reports[phaseName] ??
        {
          "work": "一歩ずつ着実な歩みを。周囲とのコミュニケーションを大切に。",
          "love": "小さな優しさが実を結ぶ日。相手の話をよく聞くことが鍵。",
          "self": "好きな香りに包まれてリラックス。心身のバランスを整えて。",
          "power": 70,
        };
    return {...baseReport, "elementAdvice": elementAdvice[signInfo["element"]]};
  }

  static int calculateHarmony(
    Map<String, String>? userSign,
    Map<String, String>? partnerSign,
    int moonAge,
  ) {
    if (userSign == null || partnerSign == null) return 0;
    int score = 60;
    if (userSign["element"] == partnerSign["element"]) score += 25;
    if (moonAge >= 13 && moonAge <= 16) score += 10;
    return math.min(score, 100);
  }

  static Map<String, String> getPhaseInfo(int age) {
    if (age == 1) return {"name": "新月", "keyword": "意図", "icon": "🌑"};
    if (age < 7) return {"name": "三日月", "keyword": "挑戦", "icon": "🌙"};
    if (age <= 8) return {"name": "上弦の月", "keyword": "決断", "icon": "🌓"};
    if (age < 14) return {"name": "満月前", "keyword": "洗練", "icon": "🌔"};
    if (age <= 16) return {"name": "満月", "keyword": "成就", "icon": "🌕"};
    if (age < 22) return {"name": "下弦の月", "keyword": "手放し", "icon": "🌗"};
    return {"name": "鎮静の月", "keyword": "休息", "icon": "🌘"};
  }
}

/* =========================================
   Canvas Background (Astrolabe Animation)
   ========================================= */
class AstrolabeBackground extends StatefulWidget {
  final double speedMultiplier;
  const AstrolabeBackground({Key? key, this.speedMultiplier = 1.0})
    : super(key: key);

  @override
  _AstrolabeBackgroundState createState() => _AstrolabeBackgroundState();
}

class _AstrolabeBackgroundState extends State<AstrolabeBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: AstrolabePainter(
            _controller.value * 2 * math.pi,
            widget.speedMultiplier,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class AstrolabePainter extends CustomPainter {
  final double time;
  final double speedMultiplier;

  AstrolabePainter(this.time, this.speedMultiplier);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseSpeed = 0.5 * speedMultiplier;

    // Particles
    final particlePaint = Paint()..color = AppColors.gold.withOpacity(0.4);
    for (int i = 0; i < 40; i++) {
      final px = (math.sin(i * 123 + time * 0.5) * 0.5 + 0.5) * w;
      final py = (math.cos(i * 321 + time * 0.75) * 0.5 + 0.5) * h;
      final s = (math.sin(i + time * 10) * 0.5 + 0.5) * 1.5;
      canvas.drawCircle(Offset(px, py), s, particlePaint);
    }

    // Astrolabe
    final cx = w / 2;
    final cy = h / 2 - 50;
    final r = math.min(w, h) * 0.35;

    canvas.save();
    canvas.translate(cx, cy);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.gold.withOpacity(0.2)
      ..strokeWidth = 1;

    canvas.drawCircle(Offset.zero, r, linePaint);
    canvas.drawCircle(
      Offset.zero,
      r * 1.05,
      linePaint..color = AppColors.gold.withOpacity(0.05),
    );

    linePaint.color = AppColors.gold.withOpacity(0.3);

    canvas.save();
    canvas.rotate(time * baseSpeed);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.4),
      linePaint,
    );
    canvas.restore();

    canvas.save();
    canvas.rotate(-time * baseSpeed * 0.8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.6, height: r * 2),
      linePaint,
    );
    canvas.restore();

    canvas.save();
    canvas.rotate(time * baseSpeed * 0.5);
    _drawDashedOval(
      canvas,
      Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 1.6),
      linePaint,
    );
    canvas.restore();

    canvas.restore();
  }

  void _drawDashedOval(Canvas canvas, Rect rect, Paint paint) {
    Path path = Path()..addOval(rect);
    for (PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = 5.0;
        final gap = 10.0;
        canvas.drawPath(metric.extractPath(distance, distance + length), paint);
        distance += length + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AstrolabePainter oldDelegate) => true;
}

/* =========================================
   UI Components
   ========================================= */
class KarakuriCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const KarakuriCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: AppColors.gold),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isBorderDark;

  const GlassPanel({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16),
    this.isBorderDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.winBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isBorderDark
              ? Colors.white.withOpacity(0.1)
              : AppColors.gold.withOpacity(0.3),
        ),
      ),
      child: child,
    );
  }
}

/* =========================================
   Main Application
   ========================================= */
class MoonPhaseOracleApp extends StatelessWidget {
  const MoonPhaseOracleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '月相神託',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.spaceBg,
        primaryColor: AppColors.gold,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum AppState { onboarding, loading, main }

enum AppTab { oracle, compatibility }

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final KarakuriCore core = KarakuriCore();
  AppState view = AppState.onboarding;
  AppTab activeTab = AppTab.oracle;
  String? activeModal; // 'settings', 'paywall', 'review', 'share'

  bool isPro = false;
  bool isTempUnlocked = false;
  bool get isUnlocked => isPro || isTempUnlocked;

  String userName = "";
  DateTime? birthDate;
  DateTime? partnerBirth;

  bool showHanko = false;
  String loadingMsg = "";

  late DateTime today;
  late int moonAge;
  late Map<String, String> phaseInfo;

  @override
  void initState() {
    super.initState();
    core.init();
    today = DateTime.now();
    moonAge = FortuneEngine.getMoonPhase(today);
    phaseInfo = FortuneEngine.getPhaseInfo(moonAge);
  }

  void switchTab(AppTab tab) {
    core.vibrate(type: 'light');
    setState(() {
      activeTab = tab;
      if (!isPro) isTempUnlocked = false;
    });
  }

  Future<void> handleStart() async {
    if (userName.isEmpty || birthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('お名前と生誕の日を入力してください')));
      return;
    }

    core.vibrate(type: 'heavy');
    setState(() => view = AppState.loading);

    List<String> msgs = [
      "星辰の歯車を同調中...",
      "魂の波長を解析中...",
      "古代の叡智へ接続...",
      "運命の軌道を算出...",
    ];
    for (String msg in msgs) {
      if (!mounted) return;
      setState(() => loadingMsg = msg);
      await Future.delayed(const Duration(milliseconds: 600));
    }

    int count = core.saveRecord();
    if (!mounted) return;
    setState(() => view = AppState.main);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => showHanko = true);
        core.vibrate(type: 'success');
      }
    });

    if (count == 3) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => activeModal = 'review');
      });
    }
  }

  void handleDataClear() {
    core.vibrate(type: 'heavy');
    core.clearData(() {
      setState(() {
        view = AppState.onboarding;
        userName = "";
        birthDate = null;
        partnerBirth = null;
        activeModal = null;
        isPro = false;
        isTempUnlocked = false;
        showHanko = false;
      });
    });
  }

  // ★ バグ修正: 追加されたメソッド
  void handleProUnlock() {
    core.vibrate(type: 'success');
    setState(() {
      isPro = true;
      activeModal = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pro版が解放されました。神託の深淵へようこそ。')));
  }

  void showModal(String modalName) {
    core.vibrate(type: 'light');
    setState(() => activeModal = modalName);
  }

  void closeModal() {
    core.vibrate(type: 'light');
    setState(() => activeModal = null);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return "日付を選択";
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate(BuildContext context, bool isPartner) async {
    core.vibrate(type: 'light');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.spaceBg,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isPartner) {
          partnerBirth = picked;
        } else {
          birthDate = picked;
        }
      });
    }
  }

  /* --- Views --- */
  Widget _buildOnboarding() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Celestial Karakuri",
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                letterSpacing: 4.0,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "月相神託",
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                shadows: [Shadow(color: Color(0x4DD4AF37), blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "天球のからくりが交差する。\n生誕の刻を刻み、汝の星宿を読み解け。",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.silver,
                fontSize: 12,
                height: 2.0,
                fontFamily: 'sans-serif',
              ),
            ),
            const SizedBox(height: 48),
            GlassPanel(
              borderRadius: 32,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "御名 (NAME)",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                  TextField(
                    onChanged: (v) => setState(() => userName = v),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'serif',
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: "旅人",
                      hintStyle: TextStyle(color: AppColors.textDim),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.gold),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.gold, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "生誕の日 (DATE OF BIRTH)",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.gold),
                        ),
                      ),
                      child: Text(
                        _formatDate(birthDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'serif',
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  InkWell(
                    onTap: handleStart,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gold),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "星の軌道を計算する",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 16,
                          letterSpacing: 4,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            loadingMsg,
            style: const TextStyle(
              color: AppColors.silver,
              fontSize: 14,
              letterSpacing: 2,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "CALCULATING ORBIT",
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              letterSpacing: 3,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMain(
    Map<String, String>? userSign,
    Map<String, String>? partnerSign,
    int harmonyScore,
    Map<String, dynamic>? report,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ORACLE",
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                          letterSpacing: 3,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$userName 殿",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.silver),
                    onPressed: () => showModal('settings'),
                  ),
                ],
              ),
            ),

            // Content Scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: activeTab == AppTab.oracle
                    ? _buildOracleTab(userSign, report)
                    : _buildCompatibilityTab(
                        userSign,
                        partnerSign,
                        harmonyScore,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOracleTab(
    Map<String, String>? userSign,
    Map<String, dynamic>? report,
  ) {
    if (report == null) return const SizedBox();
    return Column(
      children: [
        // Header with Hanko
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text(
                    "POWER ${report["power"]}%",
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      letterSpacing: 2,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "これが貴方の魂に刻まれた\n本日の星々の羅針盤です。",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.silver,
                    fontSize: 11,
                    height: 1.6,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: -20,
              child: AnimatedScale(
                scale: showHanko ? 1.0 : 3.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: showHanko ? 0.85 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Transform.rotate(
                    angle: 15 * math.pi / 180,
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "月読\n完了",
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Moon Phase Main Card
        KarakuriCard(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(
                phaseInfo["icon"]!,
                style: const TextStyle(
                  fontSize: 72,
                  shadows: [Shadow(color: Color(0x99D4AF37), blurRadius: 20)],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                phaseInfo["name"]!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Energy: ${phaseInfo["keyword"]}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
            ],
          ),
        ),

        // Free Sections
        _buildSectionCard(Icons.work_outline, "仕事と才能", report["work"]),
        _buildSectionCard(Icons.favorite_border, "対人と思慕", report["love"]),

        // Pro Feature 1
        KarakuriCard(
          onTap: () => !isUnlocked ? showModal('paywall') : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.gold,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "心身の浄化（セルフケア）",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                  const Spacer(),
                  if (!isUnlocked)
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.textDim,
                      size: 14,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (isUnlocked)
                Text(
                  report["self"],
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 13,
                    height: 2.0,
                  ),
                )
              else
                Column(
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: const Text(
                        "ここは保護された神託テキストです。Pro版に昇格することで表示されます。心身の浄化について深い洞察を得ましょう。",
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 13,
                          height: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.4),
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: AppColors.gold,
                            size: 14,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "鍵を開ける",
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'sans-serif',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Pro Feature 2 (Ad Mock)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUnlocked
                  ? [
                      AppColors.gold.withOpacity(0.3),
                      AppColors.gold.withOpacity(0.1),
                    ]
                  : [Colors.grey.shade800, Colors.grey.shade900],
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.spaceBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "${userSign?["element"] ?? "星"}の属性を持つあなたへ",
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isUnlocked)
                  Text(
                    report["elementAdvice"],
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 13,
                      height: 2.0,
                    ),
                  )
                else
                  Column(
                    children: [
                      InkWell(
                        onTap: () {
                          core.vibrate();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('広告を再生します(Mock)')),
                          );
                          setState(() => isTempUnlocked = true);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            border: Border.all(color: Colors.white10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: AppColors.accent,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "動画を見て1回だけ神託を読む",
                                style: TextStyle(
                                  color: AppColors.silver,
                                  fontSize: 12,
                                  fontFamily: 'sans-serif',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => showModal('paywall'),
                        child: const Text.rich(
                          TextSpan(
                            text: "または ",
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                            children: [
                              TextSpan(
                                text: "Pro版で広告を完全非表示",
                                style: TextStyle(
                                  color: AppColors.gold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(IconData icon, String title, String text) {
    return KarakuriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.silver, size: 16),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.silver,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontFamily: 'sans-serif',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 13,
              height: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityTab(
    Map<String, String>? userSign,
    Map<String, String>? partnerSign,
    int harmonyScore,
  ) {
    return Column(
      children: [
        KarakuriCard(
          padding: const EdgeInsets.only(
            top: 32,
            bottom: 48,
            left: 24,
            right: 24,
          ),
          child: Column(
            children: [
              const Text(
                "魂 の 共 鳴",
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "月の引力が引き寄せる二人の調和",
                style: TextStyle(
                  color: AppColors.silver,
                  fontSize: 11,
                  fontFamily: 'sans-serif',
                ),
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "相手の生誕日",
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    letterSpacing: 2,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context, true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.gold)),
                  ),
                  child: Text(
                    _formatDate(partnerBirth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'serif',
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (partnerSign != null)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF111520),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "$harmonyScore",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      "%",
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 24,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "SOUL HARMONY",
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    letterSpacing: 4,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Text(
                            "YOU",
                            style: TextStyle(
                              color: AppColors.silver,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userSign?["name"] ?? "あなた",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'sans-serif',
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.favorite,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      Column(
                        children: [
                          const Text(
                            "PARTNER",
                            style: TextStyle(
                              color: AppColors.silver,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            partnerSign["name"]!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'sans-serif',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildModalOverlay() {
    return Stack(
      children: [
        GestureDetector(
          onTap: closeModal,
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _getModalContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getModalContent() {
    switch (activeModal) {
      case 'settings':
        return _buildSettingsModal();
      case 'paywall':
        return _buildPaywallModal();
      case 'review':
        return _buildReviewModal();
      case 'share':
        return _buildShareModal();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSettingsModal() {
    return GlassPanel(
      borderRadius: 32,
      padding: const EdgeInsets.all(32),
      isBorderDark: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "設定・記録",
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  letterSpacing: 4,
                  fontFamily: 'serif',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textDim),
                onPressed: closeModal,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup("DATA", [
            _buildSettingsItem(
              Icons.download,
              "記録をCSV出力",
              AppColors.silver,
              onTap: () {
                core.vibrate();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('CSV出力を実行します')));
              },
            ),
            _buildSettingsItem(
              Icons.delete_outline,
              "データを全削除",
              Colors.redAccent,
              onTap: handleDataClear,
            ),
          ]),
          _buildSettingsGroup("ABOUT APP", [
            _buildSettingsItem(
              Icons.star,
              "Pro版へ昇格",
              AppColors.silver,
              trailing: isPro
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "PRO",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                core.vibrate();
                showModal('paywall');
              },
            ),
            _buildSettingsItem(
              Icons.favorite,
              "瓦版で応援する",
              AppColors.silver,
              iconColor: AppColors.accent,
              onTap: () {
                core.vibrate();
                showModal('review');
              },
            ),
          ]),
          _buildSettingsGroup("SYSTEM", [
            _buildSettingsItem(
              Icons.vibration,
              "触覚フィードバック",
              AppColors.silver,
              trailing: Switch(
                value: core.haptics,
                onChanged: (v) => setState(() => core.toggleHaptics()),
                activeColor: AppColors.gold,
                activeTrackColor: AppColors.gold.withOpacity(0.5),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFF1a2233),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontFamily: 'sans-serif',
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    Color color, {
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.gold, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontFamily: 'sans-serif',
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPaywallModal() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.winBg,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    AppColors.gold.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: AppColors.gold, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "神託の深淵へ",
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Pro版に昇格して、月のメッセージを完全に読み解きましょう。",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    height: 1.5,
                    fontFamily: 'sans-serif',
                  ),
                ),
                const SizedBox(height: 32),
                _buildPaywallFeature("心身のバランスを整える「セルフケアの導き」"),
                _buildPaywallFeature("星座属性に基づく「パーソナル神託」"),
                _buildPaywallFeature("相性診断の詳細解説とアドバイス"),
                _buildPaywallFeature("広告の完全非表示"),
                const SizedBox(height: 32),
                InkWell(
                  onTap: () {
                    handleProUnlock();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66D4AF37), blurRadius: 15),
                      ],
                    ),
                    child: const Text(
                      "月額 ¥480 で解放する",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    handleProUnlock();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "¥1,200 で永久解放（買い切り）",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: closeModal,
                  child: const Text(
                    "今はしない",
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppColors.gold, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.silver,
                fontSize: 14,
                fontFamily: 'sans-serif',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewModal() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.winBg,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.gold, size: 48),
          const SizedBox(height: 16),
          const Text(
            "開発者を応援しませんか？",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "月相神託をご利用いただきありがとうございます。もしよろしければ、5つ星評価で応援をお願いします。",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              height: 1.5,
              fontFamily: 'sans-serif',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (_) => const Icon(Icons.star, color: AppColors.gold, size: 32),
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: () {
              core.vibrate(type: 'success');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('ストアへ遷移します')));
              closeModal();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "5つ星で応援する",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: closeModal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "あとで",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDim,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareModal() {
    Map<String, String>? userSign = FortuneEngine.getSunSignInfo(birthDate);
    Map<String, dynamic>? report = FortuneEngine.getDetailedReport(
      phaseInfo["name"]!,
      userSign,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.winBg,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "SHARE",
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  letterSpacing: 4,
                  fontFamily: 'serif',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textDim),
                onPressed: closeModal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.spaceBg, Color(0xFF1A1F2E)],
                ),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 40),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.gold.withOpacity(0.8),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        phaseInfo["icon"]!,
                        style: const TextStyle(
                          fontSize: 64,
                          shadows: [
                            Shadow(color: Color(0x99D4AF37), blurRadius: 15),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        phaseInfo["name"]!,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "ENERGY: ${phaseInfo["keyword"]}",
                        style: const TextStyle(
                          color: AppColors.silver,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ],
                  ),
                  const Positioned(
                    bottom: 16,
                    child: Text(
                      "MOON PHASE ORACLE",
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 10,
                        letterSpacing: 4,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
              core.vibrate();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('画像を保存しました')));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "画像を保存する",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              core.vibrate();
              Clipboard.setData(
                ClipboardData(
                  text:
                      "今日の月は${phaseInfo["name"]}。私のパワーレベルは${report?["power"] ?? '?'}%でした。 #月相神託",
                ),
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('テキストをコピーしました')));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share, color: Colors.black, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "リンクテキストで共有",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ★ バグ修正: 重複していた最初のbuildメソッドを削除し、
  //    ナビゲーションバーを含む完全版のbuildメソッドを1つに統合しました。
  @override
  Widget build(BuildContext context) {
    Map<String, String>? userSign = FortuneEngine.getSunSignInfo(birthDate);
    Map<String, String>? partnerSign = FortuneEngine.getSunSignInfo(
      partnerBirth,
    );
    int harmonyScore = FortuneEngine.calculateHarmony(
      userSign,
      partnerSign,
      moonAge,
    );
    Map<String, dynamic>? report = FortuneEngine.getDetailedReport(
      phaseInfo["name"]!,
      userSign,
    );

    return Scaffold(
      body: Stack(
        children: [
          AstrolabeBackground(
            speedMultiplier: view == AppState.loading ? 30 : 1,
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    if (view == AppState.onboarding) _buildOnboarding(),
                    if (view == AppState.loading) _buildLoading(),
                    if (view == AppState.main)
                      _buildMain(userSign, partnerSign, harmonyScore, report),
                  ],
                ),
              ),
            ),
          ),
          if (view == AppState.main)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420 - 48),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.winBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 20),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          Icons.dashboard,
                          "神託",
                          activeTab == AppTab.oracle,
                          () => switchTab(AppTab.oracle),
                        ),
                        _buildNavItem(
                          Icons.people,
                          "相性",
                          activeTab == AppTab.compatibility,
                          () => switchTab(AppTab.compatibility),
                        ),
                        _buildNavItem(
                          Icons.share,
                          "瓦版",
                          false,
                          () => showModal('share'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (activeModal != null) _buildModalOverlay(),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    final color = isActive ? AppColors.gold : AppColors.silver;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: 'sans-serif',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
