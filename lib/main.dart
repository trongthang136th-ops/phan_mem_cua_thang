import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

// --- MIXIN / LỚP HỖ TRỢ XOAY NGANG (Dành cho các mục sau) ---
mixin LuonXoayNgang<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
class AlarmClock extends StatefulWidget {
  const AlarmClock({super.key});
  @override
  State<AlarmClock> createState() => _AlarmClockState();
}
class _AlarmClockState extends State<AlarmClock> {
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  // SỬ DỤNG showGeneralDialog ĐỂ TẠO LỚP NỔI ĐỘC LẬP HOÀN TOÀN, KHÔNG CO GIÃN BẢN ĐỒ
  Future<void> _selectMinutesAndStart(BuildContext context) async {
    final TextEditingController controller = TextEditingController(
      text: _totalSeconds > 0 ? (_totalSeconds ~/ 60).toString() : "",
    );
    int? selectedMinutes = await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cài đặt thời gian",
      barrierColor:
          Colors.black.withOpacity(0.6), // Lớp nền tối mờ mịn bên ngoài
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_rounded,
                        size: 50, color: Colors.orange),
                    const SizedBox(height: 12),
                    const Text(
                      "Cài đặt thời gian học",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Nhập số phút",
                        hintText: "Ví dụ: 15",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Hủy",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              int? minutes = int.tryParse(controller.text);
                              if (minutes != null && minutes > 0) {
                                Navigator.pop(context, minutes);
                              } else {
                                Navigator.pop(context, null);
                              }
                            },
                            child: const Text(
                              "Bắt đầu",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (selectedMinutes != null) {
      setState(() {
        _totalSeconds = selectedMinutes * 60;
        _remainingSeconds = _totalSeconds;
      });
      _startCountdown();
    }
  }
  void _startCountdown() {
    _timer?.cancel();
    _audioPlayer.stop();
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _playAlarmSound();
        }
      });
    });
  }
  void _stopAlarm() {
    _timer?.cancel();
    _audioPlayer.stop();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }
  void _playAlarmSound() async {
    await _audioPlayer.play(AssetSource('number_song.mp3'));
  }
  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    String timeFormatted =
        "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    int totalMinutesSetting = _totalSeconds ~/ 60;
    String buttonText = "Hẹn giờ học";
    Color buttonColor = Colors.orange;
    IconData buttonIcon = Icons.timer;
    if (_isRunning) {
      buttonText = "Dừng ($timeFormatted)";
      buttonColor = Colors.red;
      buttonIcon = Icons.stop;
    } else if (_totalSeconds > 0) {
      buttonText = "$totalMinutesSetting Phút (Chạm để đổi)";
      buttonColor = Colors.orange;
      buttonIcon = Icons.edit_rounded;
    }
    return Material(
      color: Colors.transparent,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        onPressed: () {
          if (_isRunning) {
            _stopAlarm();
          } else {
            _selectMinutesAndStart(context);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(buttonIcon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("CHAY TU PROJECT PHAN_MEM_CUA_THANG");

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phần Mềm Của Thắng',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

// --- TRANG 1: HÌNH NỀN ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TrangBanDo()),
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
  child: Image.asset(
  'assets/anhnen.png',
  fit: BoxFit.fill,
),
),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Đang vào ứng dụng cho bé...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TRANG 2 BẢN ĐỒ
class TrangBanDo extends StatefulWidget {
  const TrangBanDo({super.key});
  @override
  State<TrangBanDo> createState() => _TrangBanDoState();
}
class _TrangBanDoState extends State<TrangBanDo> {
  @override
  void initState() {
    super.initState();
    // Khóa chặt hướng dọc và ẩn thanh điều hướng hệ thống ngay khi khởi tạo
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Đảm bảo khi bé bấm nút quay lại từ các trang con (như Mầm Non) về Bản Đồ,
    // màn hình sẽ ngay lập tức được ép về lại hướng dọc chính xác.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  @override
  void dispose() {
    // Mở lại toàn bộ các hướng (dọc và ngang) để các trang con tự do quyết định hướng của nó
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
  String tieuDe = "Khám phá Việt Nam";
  String moTa = "Nhấn vào mỗi tỉnh để xem điều thú vị con";
  String anhVien = "";
  String anhVien2 = "";
  void _hienThongTin(String name, String info, String img1, String img2) {
    setState(() {
      tieuDe = name;
      moTa = info;
      anhVien = img1;
      anhVien2 = img2 == "" ? img1 : img2;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: Stack(
        children: [
          InteractiveViewer(
            clipBehavior: Clip.none,
            panEnabled: true,
            scaleEnabled: true,
            minScale: 1.0,
            maxScale: 5.0,
            child: SizedBox.expand(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'images/bando.png',
                    fit: BoxFit.fill,
                  ),
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "BẢN ĐỒ CHỦ QUYỀN VIỆT NAM",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // --- DANH SÁCH TỈNH THÀNH ---
                  _tinh(
                      0.14,
                      0.26,
                      "Lào Cai",
                      "Lào Cai(Sáp nhập Yên Bái 2025) Diện tích: 13.257 km².Là Cửa ngõ giao thương và du lịch vùng núi cao.Di sản & Thiên nhiên: Đỉnh Fansipan, ruộng bậc thang Mù Cang Chải.Di tích: Đền Bảo Hà, bãi đá cổ Sa Pa.Đặc sản & Lễ hội: Thịt trâu gác bếp, lợn cắp nách, thắng cố, Lễ hội xuống đồng của người Giáy, Festival dù lượn Mù Cang Chải.",
                      "images/laocai.png",
                      "images/laocai1.png"),
                  _tinh(
                      0.13,
                      0.13,
                      "Lai Châu",
                      "Lai Châu Diện tích: 9.068,73 km². Vùng biên cương Tây Bắc.Vùng biên giới sầm uất với các đỉnh núi cao và hang động hoang sơ.Di sản & Thiên nhiên: Đèo Ô Quy Hồ (một trong tứ đại đỉnh đèo), Đỉnh Putaleng, Động Tiên Sơn.Di tích: Di tích bia Lê Lợi.Đặc sản & Lễ hội: Thịt lợn bản, rêu đá nướng, rượu mông kê, Lễ hội Tú Cải của người Dao.",
                      "images/laichau.png",
                      "images/laichau1.png"),
                  _tinh(
                      0.17,
                      0.11,
                      "Điện Biên",
                      "Điện Biên Diện tích: 9.539,93 km². Di tích lịch sử Điện Biên Phủ.Địa danh lừng lẫy năm châu gắn liền với chiến thắng Điện Biên Phủ.Di sản & Thiên nhiên: Đèo Pha Đinh, Hồ Pá Khoang, cánh đồng Mường Thanh.Di tích: Quần thể di tích chiến trường Điện Biên Phủ (Hầm Đờ Cát, đồi A1, tượng đài chiến thắng).Đặc sản & Lễ hội: Gà nướng mắc khén, xôi nếp nương, Lễ hội Hoa Ban.",
                      "images/dienbien.png",
                      "images/dienbien1.png"),
                  _tinh(
                      0.18,
                      0.2,
                      "Sơn La",
                      "Sơn La Diện tích: 14.109,83 km². Cao nguyên Mộc Châu xanh mướt.Vùng cao Tây Bắc với cao nguyên đồng cỏ và nhà máy thủy điện lớn nhất Đông Nam Á.Di sản & Thiên nhiên: Cao nguyên Mộc Châu, Đèo Pha Đinh, Hồ thủy điện Sơn La.Di tích: Nhà tù Sơn La, cây đào Tô Hiệu.Đặc sản & Lễ hội: Sữa bò Mộc Châu, nộm da trâu, cá nướng Pa Pỉnh Tộp, Lễ hội Hết Chá.",
                      "images/sonla.png",
                      "images/sonla1.png"),
                  _tinh(
                      0.11,
                      0.36,
                      "Tuyên Quang",
                      "Tuyên Quang(Sáp nhập Hà Giang 2025) Diện tích: 13.795,60 km². Thủ đô kháng chiến sơn kỳ thủy túDi sản & Thiên nhiên: Cao nguyên đá Đồng Văn, rừng đặc dụng Na Hang.Di tích: Khu di tích Tân Trào, cột cờ Lũng Cú.Đặc sản & Lễ hội: Cháo ấu tẩu, cam sành, Lễ hội Thành Tuyên.",
                      "images/tuyenquang.png"),
                  _tinh(
                      0.095,
                      0.5,
                      "Cao Bằng",
                      "Cao Bằng Diện tích: 6.700,39 km². Thác Bản Giốc, hang Pác Bó.Vùng đất biên cương với những kỳ quan địa chất hùng vĩ.Di sản & Thiên nhiên: Thác Bản Giốc (thác nước lớn thứ 4 thế giới nằm trên đường biên giới), Động Ngườm Ngao.Di tích: Khu di tích quốc gia đặc biệt Pác Bó (Suối Lê-nin, Núi Các Mác).Đặc sản & Lễ hội: Hạt dẻ Trùng Khánh, vịt quay 7 vị, bánh áp chao, Lễ hội mời Mẹ Trăng (Nàng Hai)",
                      "images/caobang.png",
                      "images/caobang1.png"),
                  _tinh(
                      0.15,
                      0.57,
                      "Lạng Sơn",
                      "Lạng Sơn Diện tích: 8.310,18 km². Cửa khẩu Hữu Nghị, mẫu Sơn.Cửa ngõ giao thương biên giới phía Bắc và văn hóa xứ Lạng.Di sản & Thiên nhiên: Khu nghỉ dưỡng Mẫu Sơn, Động Nhị Thanh - Tam Thanh.Di tích: Ải Chi Lăng, Đền Mẫu Đồng Đăng, Đền Kỳ Cùng.Đặc sản & Lễ hội: Vịt quay lá mắc mật, khâu nhục, phở chua, Lễ hội Lồng Tồng.",
                      "images/langson.png"),
                  _tinh(
                      0.14,
                      0.45,
                      "Thái Nguyên",
                      "Thái Nguyên(Sáp nhập Bắc Kạn 2025) Diện tích: 8.375,30 km². Thủ phủ trà (chè),Đệ nhất danh trà và hệ sinh thái hồ núi vùng Việt Bắc.Di sản & Thiên nhiên: Hồ Ba Bể (di sản ASEAN), hồ Núi Cốc.Di tích: Khu di tích ATK Định Hóa, di tích lịch sử 915.Đặc sản & Lễ hội: Chè Tân Cương, bánh chưng bờ đậu, tôm chua Ba Bể, Lễ hội Lồng Tồng.",
                      "images/thainguyen.png"),
                  _tinh(
                      0.21,
                      0.37,
                      "Phú Thọ",
                      "Phú Thọ(Sáp nhập Vĩnh Phúc, Hòa Bình 2025) Diện tích: 9.361,40 km².Cội nguồn dân tộc và văn hóa các dân tộc vùng núi. Đất Tổ Hùng Vương linh thiêng.Di sản & Thiên nhiên: Tín ngưỡng thờ cúng Hùng Vương, Hát Xoan, Vườn quốc gia Xuân Sơn.Di tích: Đền Hùng, Thung Nai.",
                      "images/phutho.png"),
                  _tinh(
                      0.195,
                      0.44,
                      "Hà Nội",
                      "Hà Nội Diện tích: 3.359,84 km². Thủ đô ngàn năm văn hiến, Trái tim của cả nước, Thành phố vì hòa bình.Di sản và Thiên nhiên: Hồ Gươm tháp Rùa, Sông Hồng chảy trong lòng thành phố, Vườn quốc gia Ba Vì, Đường Phan Đình Phùng lá bay.Di tích: Lăng Bác, Văn Miếu - Quốc Tử Giám, Hoàng thành Thăng Long, 36 phố phường, Chùa Một Cột.Đặc sản & Lễ hội: Phở, Bún chả, Cốm làng Vòng, Chả cá Lã Vọng. Lễ hội gò Đống Đa, Lễ hội chùa Hương, Lễ hội đền Gióng.",
                      "images/hanoi.png",
                      "images/hanoi1.png"),
                  _tinh(
                      0.19,
                      0.53,
                      "Bắc Ninh",
                      "Bắc Ninh(Sáp nhập Bắc Giang 2025) Diện tích: 4.718,60 km². Kinh bắc hào hoa, dân ca Quan họ.Di sản & Thiên nhiên: Dân ca Quan họ, mộc bản chùa Vĩnh Nghiêm.Di tích: Chùa Phật Tích, Đền Đô, chùa Bổ Đà.Đặc sản & Lễ hội: Bánh phu thê, vải thiều Lục Ngạn, Hội Lim.",
                      "images/bacninh.png"),
                  _tinh(
                      0.24,
                      0.55,
                      "Hưng Yên",
                      "Hưng Yên(Sáp nhập Thái Bình 2025) Diện tích: 2.514,80 km². Phố Hiến - Thứ nhất Kinh Kỳ, thứ nhì Phố Hiến.Cái nôi văn hóa lúa nước và các làng nghề truyền thống xứ Đông.Di sản & Thiên nhiên: Chùa Keo (kiến trúc gỗ độc đáo), Phố Hiến (Thứ nhất Kinh Kỳ, thứ nhì Phố Hiến).Di tích: Đền Đa Hòa - Dạ Trạch (Chử Đồng Tử), Cụm di tích đền Trần Thái Bình.Đặc sản & Lễ hội: Nhãn lồng Hưng Yên, bún thang lươn, bánh cáy, Lễ hội chùa Keo",
                      "images/hungyen.png"),
                  _tinh(
                      0.18,
                      0.69,
                      "Quảng Ninh",
                      "Quảng Ninh Diện tích: 6.207,93 km². Kỳ quan thế giới Vịnh Hạ Long.Trung tâm khai thác than đá và du lịch biển đẳng cấp quốc tế.Di sản & Thiên nhiên:Di sản thiên nhiên thế giới Vịnh Hạ Long, Đảo Cô Tô, Quan Lạn.Di tích: Khu di tích lịch sử và danh thắng Yên Tử (đất tổ Thiền phái Trúc Lâm), di tích chiến thắng Bạch Đằng.Đặc sản & Lễ hội: Chả mực Hạ Long, sá sùng, gà Tiên Yên, Lễ hội Carnaval Hạ Long.",
                      "images/quangninh.png"),
                  _tinh(
                      0.215,
                      0.59,
                      "Hải Phòng",
                      "Hải Phòng(Sáp nhập Hải Dương 2025) Diện tích: 4.180 km^2. Thành phố Hoa phượng đỏ, cảng biển lớn Di sản & Thiên nhiên: Quần thể di sản thiên nhiên thế giới Vịnh Hạ Long - Cát Bà.Di tích:Côn Sơn - Kiếp Bạc, Văn miếu Mao Điền.Đặc sản & Lễ hội: Bánh đa cua, bánh đậu xanh, Lễ hội chọi trâu Đồ Sơn.",
                      "images/haiphong.png",
                      "images/haiphong1.png"),
                  _tinh(
                      0.253,
                      0.49,
                      "Ninh Bình",
                      "Ninh Bình(Sáp nhập Nam Định, Hà Nam 2025) Diện tích: 4.352 km².Vùng đất văn hiến, tâm linh và thắng cảnh núi đá vôi.Cố đô Hoa Lư,Đền Trần, Chùa Tam Chúc.danh thắng Tràng An.Đặc sản & Lễ hội: Cơm cháy, phở bò Nam Định, lễ hội đền Trần.",
                      "images/ninhbinh.png"),
                  _tinh(
                      0.275,
                      0.41,
                      "Thanh Hóa",
                      "Thanh Hóa Diện tích: 11.114,71 km².Vùng đất địa linh nhân kiện được mệnh danh là quê vua đất chúa,Di sản & Thiên nhiên: Thành Nhà Hồ (UNESCO), Vườn quốc gia Bến En, biển Sầm Sơn.Di tích: Khu di tích Lam Kinh, đền Bà Triệu.Đặc sản & Lễ hội: Nem chua, chả tôm, bánh răng bừa, Lễ hội Lam Kinh.",
                      "images/thanhhoa.png"),
                  _tinh(
                      0.31,
                      0.36,
                      "Nghệ An",
                      "Nghệ An Diện tích: 16.486,49 km². Quê hương Bác Hồ,Vùng đất học, quê hương các danh nhân văn hóa thế giới.Di sản & Thiên nhiên:Núi Hồng sông Lam, Ngã ba Đồng Lộc Dân ca Ví Giặm Nghệ Tĩnh, Vườn quốc gia Pù Mát, biển Thiên Cầm.Di tích: Khu di tích Kim Liên (quê Bác), đền ông Hoàng Mười.Đặc sản & Lễ hội: Súp lươn, nhút Thanh Chương, Lễ hội làng Sen.",
                      "images/nghean.png"),
                  _tinh(
                      0.365,
                      0.46,
                      "Hà Tĩnh",
                      "Hà Tĩnh Diện tích: 5.994,4 km². Quê hương của Đại thi hào Nguyễn Du, vùng đất địa linh nhân kiệt với truyền thống hiếu học. Di sản & Thiên nhiên: Hồ Kẻ Gỗ, Vườn quốc gia Vũ Quang, biển Thiên Cầm, chùa Hương Tích (Hoan Châu đệ nhất danh lam). Di tích: Khu di tích Ngã ba Đồng Lộc, khu lưu niệm Nguyễn Du, đền Chợ Củi. Đặc sản & Lễ hội: Kẹo cu đơ, gỏi cá đục, mực nhảy Vũng Áng, cam bù Hương Sơn, Lễ hội chùa Hương Tích.",
                      "images/hatinh.png"),
                  _tinh(
                      0.42,
                      0.55,
                      "Quảng Trị",
                      "Quảng Trị(Sáp nhập Quảng Bình 2025) Diện tích: 12.700 km². Thành cổ oai hùng, vĩ tuyến 17.Vương quốc hang động và địa chỉ đỏ giáo dục truyền thống cách mạng.Di sản & Thiên nhiên: Vườn quốc gia Phong Nha - Kẻ Bàng, bãi biển Cửa Tùng.Di tích: Thành cổ Quảng Trị, Địa đạo Vịnh Mốc, Nghĩa trang Trường Sơn, Hiền Lương - Bến Hải.Đặc sản & Lễ hội: Cháo canh, gà nướng sả Lào, khoai gieo, Lễ hội Thống nhất non sông.",
                      "images/quangtri.png"),
                  _tinh(
                      0.485,
                      0.68,
                      "Huế",
                      "Huế Diện tích: 4.947,11 km². Thành phố di sản, bảo tồn kiến trúc cung đình Di sản & Thiên nhiên: Quần thể cố đô Huế, Nhã nhạc cung đình, Hệ đầm phá Tam Giang.Di tích: Hệ thống lăng tẩm triều Nguyễn, Chùa Thiên Mụ.Đặc sản & Lễ hội: Bún bò Huế, bánh cung đình, Festival Huế.",
                      "images/hue.png",
                      "images/hue1.png"),
                  _tinh(
                      0.52,
                      0.75,
                      "Đà Nẵng",
                      "Đà Nẵng (Sáp nhập Quảng Nam 2025) Diện tích: 11.859,60 km². Thành phố của những cây cầu hiện đại Trung tâm du lịch miền Trung, thành phố đáng sống kết hợp đô thị cổDi sản & Thiên nhiên: Phố cổ Hội An, Thánh địa Mỹ Sơn, Khu sinh quyển Cù Lao Chàm.Di tích: Ngũ Hành Sơn, Bảo tàng Điêu khắc Chăm.Đặc sản & Lễ hội: Mì Quảng, Cao lầu, Bê thui Cầu Mống Lễ hội pháo hoa quốc tế DIFF.",
                      "images/danang.png",
                      "images/danang1.png"),
                  _tinh(
                      0.57,
                      0.81,
                      "Quảng Ngãi",
                      "Quảng Ngãi(Sáp nhập Kon Tum 2025) Diện tích: 14.832,60 km². Núi Ấn sông Trà, đảo Lý Sơn.Là nơi Địa chính trị quan trọng, văn hóa Sa Huỳnh và vùng cao Măng Đen.Di sản & Thiên nhiên: Đảo Lý Sơn (di tích núi lửa), rừng thông Măng Đen.Di tích: Khu di tích Sơn Mỹ, Nhà thờ gỗ Kon Tum, Ngục Kon Tum.Đặc sản & Lễ hội: Cá bống sông Trà, tỏi Lý Sơn, gỏi lá Kon Tum, Lễ đâm trâu.",
                      "images/quangngai.png"),
                  _tinh(
                      0.725,
                      0.89,
                      "Khánh Hòa",
                      "Khánh Hòa(Sáp nhập Ninh Thuận 2025) Diện tích: 8.555,90 km². Biển Nha Trang, xứ sở Trầm Hương.Là Trung tâm du lịch biển đảo quốc tế, thủ phủ Nho và năng lượng sạch Di sản & Thiên nhiên: Vịnh Nha Trang một trong những vịnh đẹp nhất thế giới Vườn quốc gia Núi Chúa.Di tích: Tháp Bà Ponagar, Tháp Po Klong Garai, Nghệ thuật làm gốm của người Chăm.Đặc sản & Lễ hội: Yến sào, bún sứa, thịt cừu Ninh Thuận, Lễ hội Tháp Bà, Lễ hội Katê.",
                      "images/khanhhoa.png"),
                  _tinh(
                      0.61,
                      0.76,
                      "Gia Lai",
                      "Gia Lai(Sáp nhập Bình Định 2025) Diện tích: 21.576,50 km². Cao nguyên Pleiku,Di sản & Thiên nhiên: Không gian văn hóa Cồng chiêng, Biển Hồ (Pleiku), bãi tắm Kỳ Co - Eo Gió.Di tích: Hệ thống Tháp Chăm, Bảo tàng Quang Trung,núi lửa Chư Đăng Ya.Đặc sản & Lễ hội: Phở hai tô, rượu Bàu Đá, bún song thằn,bò một nắng, muối kiến vàng Lễ hội Đống Đa - Tây Sơn.",
                      "images/gialai.png",
                      "images/gialai1.png"),
                  _tinh(
                      0.675,
                      0.8,
                      "Đắk Lắk",
                      "Đắk Lắk(Sáp nhập Phú Yên 2025) Diện tích: 18.096,40 km².Thủ phủ Cà phê thế giới kết hợp xứ sở Hoa vàng trên cỏ xanh.Di sản & Thiên nhiên: Thác Dray Nur - Dray Sap, Gành Đá Đĩa, Vịnh Xuân Đài.Di tích: Nhà đày Buôn Ma Thuột, Tháp Nhạn.Đặc sản & Lễ hội: Cà phê, gà nướng bản Đôn, mắt cá ngừ đại dương, Lễ hội Voi, Lễ hội Cà phê.",
                      "images/daklak.png"),
                  _tinh(
                      0.74,
                      0.74,
                      "Lâm Đồng",
                      "Lâm Đồng(Sáp nhập Bình Thuận, Đắk Nông 2025) Diện tích: 24.233,10 km². diện tích lớn nhất Văn hóa các dân tộc Tây Nguyên, lễ hội hoa Thành phố Đà Lạt, hồ Tuyền Lâm, Langbiang Cà phê, rau củ quả tươi, mứt Đà Lạt.Di sản & Thiên nhiên: Công viên địa chất Đắk Nông, hồ Tà Đùng, biển Mũi Né.Di tích: Tháp Po Sah Inư, kiến trúc Pháp Đà Lạt.Đặc sản & Lễ hội: Lẩu gà lá é, nước mắm Phan Thiết, Festival Hoa",
                      "images/lamdong.png"),
                  _tinh(
                      0.76,
                      0.62,
                      "Đồng Nai",
                      "Đồng Nai Sáp nhập Bình Phước 2025 Diện tích: 12.737,20 km². Vùng kinh tế trọng điểm phía Nam Hào khí Đồng Nai 300 năm hình thành Thác Giang Điền vườn quốc gia Cát Tiên, Suối Mơ, đảo Ó Gỏi.cá Tân Mai, bưởi Tân Triều.",
                      "images/dongnai.png",
                      "images/dongnai1.png"),
                  _tinh(
                      0.76,
                      0.49,
                      "Tây Ninh",
                      "Tây Ninh(Sáp nhập Long An 2025) Diện tích: 8.536,50 km². Núi Bà Đen, Tòa thánh Cao Đài.Cửa ngõ biên giới Campuchia, vùng đệm sinh thái Đồng Tháp Mười.Di sản & Thiên nhiên: Núi Bà Đen, Khu bảo tồn đất ngập nước Láng Sen, Vườn quốc gia Lò Gò - Xa Mát.Di tích: Tòa thánh Cao Đài, Căn cứ Trung ương Cục miền Nam.Đặc sản & Lễ hội: Bánh canh Trảng Bàng, muối tôm Tây Ninh, rượu đế Gò Đen, Hội xuân Núi Bà.",
                      "images/tayninh.png"),
                  _tinh(
                      0.805,
                      0.57,
                      "Hồ Chí Minh",
                      "Hồ Chí Minh(Sáp nhập Bà Rịa - Vũng Tàu, Bình Dương 2025)Diện tích: 6.772,60 km².Trung tâm kinh tế lớn nhất cả nước Hòn ngọc Viễn Đông Đô thị kinh tế - biển .Dinh Độc Lập, Phố đi bộ,Địa đạo Củ Chi, Nhà tù Côn Đảo,Biển Vũng Tàu.Cơm tấm, Bánh khọt, Lẩu súng.",
                      "images/hcm.png",
                      "images/hcm1.png"),
                  _tinh(
                      0.82,
                      0.46,
                      "Đồng Tháp",
                      "Đồng Tháp(Sáp nhập Tiền Giang 2025) Diện tích: 5.938,70 km².Thủ phủ Sen hồng và vùng trọng điểm trái cây Nam Bộ.Di sản & Thiên nhiên: Vườn quốc gia Tràm Chim, khu du lịch Xẻo Quýt, Cù lao Thới Sơn.Di tích: Khu di tích Gò Tháp, lăng cụ Phó bảng Nguyễn Sinh Sắc, chùa Vĩnh Tràng.Đặc sản & Lễ hội: Nem Lai Vung, hủ tiếu Mỹ Tho, xoài Cát Hòa Lộc, Lễ hội hoa Sa Đéc",
                      "images/dongthap.png"),
                  _tinh(
                      0.82,
                      0.345,
                      "An Giang",
                      "An Giang(Sáp nhập Kiên Giang 2025) Diện tích: 9.888,90 km².Kinh tế biên giới và du lịch biển đảo cao cấp. Vùng đất Thất Sơn tâm linh Văn hóa vùng Bảy Núi huyền bí Rừng tràm Trà Sư Vườn quốc gia U Minh Thượng, đảo ngọc Phú Quốc,Di chỉ Óc Eo, Miếu Bà Chúa Xứ, nhà tù Hà Tiên Xứ Lẩu mắm, tung lò mò, thốt nốt.Đặc sản & Lễ hội: Bún cá Long Xuyên, gỏi cá trích, lễ hội Vía Bà.",
                      "images/angiang.png"),
                  _tinh(
                      0.86,
                      0.46,
                      "Cần Thơ",
                      "Cần Thơ(Sáp nhập Hậu Giang, Sóc Trăng 2025) Diện tích: 6.360,80 km². Thủ phủ Miền Tây sông nước Gạo trắng nước trong, xứ Tây Đô Chợ nổi Cái Răng,Di tích: Chùa Dơi, Chùa Đất Sét, đền thờ Bác Hồ. bến Ninh Kiều Lẩu vịt nấu chao, nem nướng Cái Răng Lễ hội đua ghe Ngo.",
                      "images/cantho.png",
                      "images/cantho1.png"),
                  _tinh(
                      0.84,
                      0.54,
                      "Vĩnh Long",
                      "Vĩnh Long(Sáp nhập Trà Vinh, Bến Tre 2025) Diện tích: 6.296,20 km². Vùng đất cù lao trù phú.Vùng đất địa linh nhân kiệt Văn Thánh Miếu, cù lao An Bình Di tích: Chùa Hang, Chùa Ang, di tích Đồng Khởi.Đặc sản & Lễ hội: Kẹo dừa, bánh tét Trà Cuôn, lễ hội Nghinh Ông  Khoai lang Bình Tân, cá tai tượng",
                      "images/vinhlong.png"),
                  _tinh(
                      0.88,
                      0.39,
                      "Cà Mau",
                      "Cà Mau(Sáp nhập Bạc Liêu 2025) Diện tích: 7.942,40 km². Điểm cực Nam của Tổ quốc rừng đước bạt ngàn nuôi trồng thủy hải sản lớn nhất.Di sản & Thiên nhiên: Vườn quốc gia Mũi Cà Mau, rừng đước.Di tích: Nhà Công tử Bạc Liêu, khu lưu niệm Cao Văn Lầu hòn Đá Bạc Cua Năm Căn,Đặc sản & Lễ hội: Cua Cà Mau, Ba khía muối, Đờn ca tài tử.",
                      "images/camau.png"),
                  _tinh(
                      0.55,
                      1,
                      "Hoàng Sa",
                      "Quần đảo thiêng liêng Lịch sử xác lập và thực thi chủ quyền của Việt Nam tại Hoàng Sa Cảnh quan thiên nhiên và các rạn san hô quý hiếm Tài nguyên biển dồi dào và vị trí chiến lược quốc phòng, chủ quyền không thể tách rời của Việt Nam.",
                      "images/hoangsa.png",
                      "images/hoangsa1.png"),
                  _tinh(
                      0.9,
                      0.9,
                      "Trường Sa",
                      "Cột mốc chủ quyền thiêng liêng và đời sống quân dân trên đảo hệ sinh thái biển đảo và các nhà giàn DK1 Sức sống bền bỉ của cây bàng vuông và tình yêu biển đảo.Máu thịt của Tổ quốc nơi đầu sóng, huyện đảo của tỉnh Khánh Hòa.",
                      "images/truongsa.png",
                      "images/truongsa1.png"),
                ],
              ),
            ),
          ),
          // --- KHUNG THÔNG TIN TỈNH THÀNH ---
          if (tieuDe != "Khám phá Việt Nam")
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 2.1,
                    height: 620,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black54,
                            blurRadius: 20,
                            spreadRadius: 5)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 170,
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    anhVien,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          size: 30),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    anhVien2,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          size: 50),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tieuDe,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    moTa,
                                    style: const TextStyle(
                                        fontSize: 14, height: 1.4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => setState(() {
                                    tieuDe = "Khám phá Việt Nam";
                                  }),
                                  child: const Text(
                                    "VỀ BẢN ĐỒ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
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
                ),
              ),
            ),
          // --- CÁC NÚT ĐIỀU KHIỂN ---
          if (tieuDe == "Khám phá Việt Nam") ...[
            Positioned(
              top: 370,
              right: 190,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      // 🛡️ DÁN ĐOẠN CODE NÀY VÀO THAY THẾ CHO LỆNH NAVIGATOR.PUSH CŨ
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const TrangMamNon(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                        ),
                      ).then((_) {
                        // Đảm bảo khi vừa quay về trang Bản Đồ, hệ thống ép thẳng về dọc,
                        // triệt tiêu mọi xung đột từ việc mở/đóng thông tin trước đó.
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                        ]);
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/3den5tuoi.png',
                        width: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {},
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/7tuoi.png',
                        width: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 10,
              left: 10,
              child: AlarmClock(),
            ),
            _nutQuayLaiChuan(context),
          ],
        ],
      ),
    );
  }

  Widget _tinh(
      double top, double left, String name, String info, String imagePath,
      [String imagePath2 = ""]) {
    return Align(
      alignment: Alignment(left * 2 - 1, top * 2 - 1),
      child: GestureDetector(
        onTap: () => _hienThongTin(
            name, info, imagePath, imagePath2 == "" ? imagePath : imagePath2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 22),
            Text(name,
                style:
                    const TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _nutQuayLaiChuan(BuildContext context) {
    return Positioned(
      top: 15,
      left: 7,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            SystemNavigator.pop();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.power_settings_new,
              color: Colors.red,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// --- TRANG 3-1: LỚP MẦM NON (MENU CHÍNH - VUỐT NGANG HOÀN CHỈNH & ĐẶC SẮC) ---
class TrangMamNon extends StatefulWidget {
  const TrangMamNon({super.key});
  @override
  State<TrangMamNon> createState() => _TrangMamNonState();
}
class _TrangMamNonState extends State<TrangMamNon> with LuonXoayNgang {
  final PageController _mainPageController =
      PageController(viewportFraction: 0.55);
  double _viTriTrangHienTai = 0.0;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 🛡️ BẢO VỆ 1: Dùng khoảng trễ an toàn để luôn thắng thế mọi dialog/thông tin đang mở ở bản đồ
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
    _mainPageController.addListener(() {
      if (mounted) {
        setState(() {
          _viTriTrangHienTai = _mainPageController.page ?? 0.0;
        });
      }
    });
  }
  @override
  void dispose() {
    // 🛡️ BẢO VỆ 2: Trả về dọc khi dispose
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _mainPageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuHoc = [
      {
        "t": "Tiếng Anh",
        "sub": "Language & Communication",
        "img": "assets/tienganh.png",
        "c": Colors.pinkAccent,
        "d": const TrangTiengAnh()
      },
      {
        "t": "Tiếng Việt",
        "sub": "Reading & Writing",
        "img": "assets/tiengviet.png",
        "c": Colors.orangeAccent,
        "d": const TrangTiengViet()
      },
      {
        "t": "Toán Học",
        "sub": "Numbers & Logic",
        "img": "assets/toanhoc.png",
        "c": Colors.green,
        "d": const TrangToan()
      },
      {
        "t": "Ghép Hình",
        "sub": "Puzzles & Thinking",
        "img": "assets/ghephinh.png",
        "c": Colors.teal,
        "d": const TrangGhepHinh()
      },
      {
        "t": "Truyện Kể",
        "sub": "Stories & Imagination",
        "img": "assets/truyenke.png",
        "c": Colors.purpleAccent,
        "d": const TrangChuyenKe()
      },
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      body: Stack(
        children: [
          Positioned(
              top: -50,
              right: -50,
              child: _bongBongTrangTri(200, Colors.pink.withOpacity(0.05))),
          Positioned(
              bottom: -60,
              left: -40,
              child: _bongBongTrangTri(220, Colors.blue.withOpacity(0.05))),
          Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: PageView.builder(
                controller: _mainPageController,
                physics: const BouncingScrollPhysics(),
                itemCount: menuHoc.length,
                itemBuilder: (context, index) {
                  final item = menuHoc[index];
                  double hieuUngScale = 1.0;
                  double doMo = 1.0;
                  if (_viTriTrangHienTai.floor() == index) {
                    hieuUngScale = 1.0 - (_viTriTrangHienTai - index) * 0.12;
                    doMo = 1.0 - (_viTriTrangHienTai - index) * 0.2;
                  } else if (_viTriTrangHienTai.floor() + 1 == index) {
                    hieuUngScale = 0.88 + (index - _viTriTrangHienTai) * 0.12;
                    doMo = 0.8 + (index - _viTriTrangHienTai) * 0.2;
                  } else {
                    hieuUngScale = 0.88;
                    doMo = 0.8;
                  }
                  bool dangOChinhGiua =
                      (_viTriTrangHienTai - index).abs() < 0.3;
                  return Transform.scale(
                    scale: hieuUngScale,
                    child: Opacity(
                      opacity: doMo.clamp(0.5, 1.0),
                      child: _taoKhungHocHorizontal(context, item["t"],
                          item["img"], item["c"], item["d"], dangOChinhGiua),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: _nutQuayLaiChuan(context),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.brown.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                    border:
                        Border.all(color: Colors.amber.shade200, width: 1.5)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe_rounded,
                        color: Colors.brown.shade400, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Bé vuốt sang để chọn môn học nhé",
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
  // 🛡️ BẢO VỆ 1: Ép dọc ngay lập tức khi vừa chạm vào nút quay lại
  Widget _nutQuayLaiChuan(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
          border: Border.all(color: Colors.amber.shade300, width: 2),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.brown,
          size: 24,
        ),
      ),
    );
  }
  Widget _bongBongTrangTri(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
  Widget _taoKhungHocHorizontal(BuildContext context, String tieuDe,
      String imagePath, Color mau, Widget trangDich, bool isCenter) {
    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => trangDich));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          border: Border.all(
            color: isCenter ? mau : mau.withOpacity(0.4),
            width: isCenter ? 5.5 : 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: mau.withOpacity(isCenter ? 0.35 : 0.1),
              blurRadius: isCenter ? 20 : 8,
              offset: Offset(0, isCenter ? 10 : 4),
            )
          ],
        ),
        child: Container(),
      ),
    );
  }
}

// 1. MENU CHÍNH TIẾNG ANH
class TrangTiengAnh extends StatelessWidget {
  const TrangTiengAnh({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: const Text(
          "Tiếng Anh Cho Bé",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: const ui.Color.fromARGB(213, 64, 255, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMenuCard(
                    context,
                    title: "HỌC CƠ BẢN",
                    subtitle: "Alphabet, Numbers & Colors",
                    icon: "🔤",
                    color: Colors.lightBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangMenuHocCoBanTiengAnh()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    title: "HỌC MỞ RỘNG",
                    subtitle: "Phonics & Vocabulary",
                    icon: "🧩",
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangHocMoRongTiengAnh()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    title: "TRÒ CHƠI",
                    subtitle: "Games & Practice",
                    icon: "🎮",
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TrangTroChoiTiengAnh()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. MENU CON CỦA HỌC CƠ BẢN TIẾNG ANH
class TrangMenuHocCoBanTiengAnh extends StatelessWidget {
  const TrangMenuHocCoBanTiengAnh({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        toolbarHeight: 60, // Tăng chiều cao một chút để chứa 2 dòng chữ
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "BASIC LEARNING", // Chữ tiếng Anh to ở trên
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Học Cơ Bản", // Chữ tiếng Việt nhỏ ở dưới
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const ui.Color.fromARGB(148, 3, 236, 244),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSubMenuCard(
                    context,
                    title: "ALPHABET",
                    subtitle: "Bảng chữ cái",
                    icon: "🅰️",
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangBangChuCaiTiengAnh()),
                      );
                    },
                  ),
                  _buildSubMenuCard(
                    context,
                    title: "NUMBERS",
                    subtitle: "Chữ số & Tập đếm",
                    icon: "🔢",
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangBangChuSoTiengAnh()),
                      );
                    },
                  ),
                  _buildSubMenuCard(
                    context,
                    title: "COLORS",
                    subtitle: "Màu sắc",
                    icon: "🎨",
                    color: Colors.pink,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangBangMauSacTiengAnh()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// BẢNG CHỮ CÁI TIẾNG ANH (CÓ NÚT BÀI HÁT ABC SONG)
class TrangBangChuCaiTiengAnh extends StatefulWidget {
  const TrangBangChuCaiTiengAnh({super.key});
  @override
  State<TrangBangChuCaiTiengAnh> createState() =>
      _TrangBangChuCaiTiengAnhState();
}
class _TrangBangChuCaiTiengAnhState extends State<TrangBangChuCaiTiengAnh>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Phát bài hát ABC Song
  bool _isSongPlaying = false;
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  late AnimationController _nhayController;
  late Animation<double> _nhayAnimation;
  // Đã thêm trường "pa" (Phiên âm) cho từng chữ cái
  final List<Map<String, String>> alphabetData = [
    {"chu": "A", "pa": "/eɪ/", "vat": "Apple", "icon": "🍎", "cau": " A ... Apple."},
    {"chu": "B", "pa": "/biː/", "vat": "Ball", "icon": "⚽", "cau": " B... Ball."},
    {"chu": "C", "pa": "/siː/", "vat": "Cat", "icon": "🐱", "cau": " C...  Cat."},
    {"chu": "D", "pa": "/diː/", "vat": "Dog", "icon": "🐶", "cau": " D...  Dog."},
    {"chu": "E", "pa": "/iː/", "vat": "Elephant", "icon": "🐘", "cau": " E...  Elephant."},
    {"chu": "F", "pa": "/ef/", "vat": "Fish", "icon": "🐟", "cau": " F.... Fish."},
    {"chu": "G", "pa": "/dʒiː/", "vat": "Grape", "icon": "🍇", "cau": " G... Grape."},
    {"chu": "H", "pa": "/eɪtʃ/", "vat": "Hat", "icon": "👒", "cau": " H... Hat."},
    {"chu": "I", "pa": "/aɪ/", "vat": "Ice cream", "icon": "🍦", "cau": " I... Ice cream."},
    {"chu": "J", "pa": "/dʒeɪ/", "vat": "Juice", "icon": "🧃", "cau": " J... Juice."},
    {"chu": "K", "pa": "/keɪ/", "vat": "Kite", "icon": "🪁", "cau": " K... Kite."},
    {"chu": "L", "pa": "/el/", "vat": "Lion", "icon": "🦁", "cau": " L... Lion."},
    {"chu": "M", "pa": "/em/", "vat": "Monkey", "icon": "🐵", "cau": " M... Monkey."},
    {"chu": "N", "pa": "/en/", "vat": "Nest", "icon": "🪹", "cau": " N... Nest."},
    {"chu": "O", "pa": "/oʊ/", "vat": "Owl", "icon": "🦉", "cau": " O... Owl."},
    {"chu": "P", "pa": "/piː/", "vat": "Pen", "icon": "🖊️", "cau": " P... Pen."},
    {"chu": "Q", "pa": "/kjuː/", "vat": "Queen", "icon": "👑", "cau": " Q... Queen."},
    {"chu": "R", "pa": "/ɑːr/", "vat": "Rabbit", "icon": "🐰", "cau": " R... Rabbit."},
    {"chu": "S", "pa": "/es/", "vat": "Sun", "icon": "☀️", "cau": " S... Sun."},
    {"chu": "T", "pa": "/tiː/", "vat": "Train", "icon": "🚂", "cau": " T... Train."},
    {"chu": "U", "pa": "/juː/", "vat": "Umbrella", "icon": "☂️", "cau": " U... Umbrella."},
    {"chu": "V", "pa": "/viː/", "vat": "Van", "icon": "🚐", "cau": " V... Van."},
    {"chu": "W", "pa": "/ˈdʌb.əl.juː/", "vat": "Watch", "icon": "⌚", "cau": " W... Watch."},
    {"chu": "X", "pa": "/eks/", "vat": "Xylophone", "icon": "xylophone", "cau": " X... Xylophone."},
    {"chu": "Y", "pa": "/waɪ/", "vat": "Yo-yo", "icon": "🪀", "cau": " Y... Yo-yo."},
    {"chu": "Z", "pa": "/zed/", "vat": "Zebra", "icon": "🦓", "cau": " Z... Zebra."},
  ];
  @override
  void initState() {
    super.initState();
    _khoiTaoTts();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _nhayController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _nhayAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    flutterTts.stop();
    _audioPlayer.dispose();
    _nhayController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.3);
  }
  // Phát bài hát ABC Song
  Future<void> _toggleAbcSong() async {
    if (_isSongPlaying) {
      await _audioPlayer.stop();
      setState(() => _isSongPlaying = false);
    } else {
      try {
        await _audioPlayer.play(AssetSource('abc_song.mp3'));
        setState(() => _isSongPlaying = true);
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isSongPlaying = false);
        });
      } catch (_) {}
    }
  }
  Future<void> _hienThiChiTiet(Map<String, String> data) async {
    await flutterTts.stop();
    setState(() {
      _currentWordStart = 0;
      _currentWordEnd = 0;
    });
    String chu = data["chu"]!;
    String phienAm = data["pa"]!; // Lấy phiên âm
    String icon = data["icon"]!;
    String vat = data["vat"]!;
    String fullText = data["cau"]!;
    bool hasPopped = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Center(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              flutterTts.setProgressHandler((text, start, end, word) {
                if (mounted) {
                  setDialogState(() {
                    _currentWordStart = start;
                    _currentWordEnd = end;
                  });
                }
              });
              flutterTts.setCompletionHandler(() {
                if (!hasPopped && mounted) {
                  hasPopped = true;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop();
                    }
                  });
                }
              });
              return Dialog(
                backgroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(color: Colors.blueAccent, width: 3),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chữ cái chính
                        Text(
                          chu,
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Thêm phần hiển thị Phiên âm (Pronunciation)
                        Text(
                          phienAm,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Icon nhảy nhót
                        AnimatedBuilder(
                          animation: _nhayAnimation,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, _nhayAnimation.value),
                            child: Text(icon,
                                style: const TextStyle(fontSize: 50)),
                          ),
                        ),
                        const SizedBox(height: 0),
                        Text(
                          vat,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 0),
                        // Câu karaoke
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildHighlightedText(fullText),
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    await flutterTts.speak(fullText);
  }
  List<TextSpan> _buildHighlightedText(String text) {
    List<TextSpan> spans = [];
    if (_currentWordStart >= 0 &&
        _currentWordEnd <= text.length &&
        _currentWordStart < _currentWordEnd) {
      spans.add(TextSpan(text: text.substring(0, _currentWordStart)));
      spans.add(TextSpan(
        text: text.substring(_currentWordStart, _currentWordEnd),
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: text.substring(_currentWordEnd)));
    } else {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        toolbarHeight: 47,
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: const Text("Alphabet (A - Z)",
            style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        backgroundColor: const ui.Color.fromARGB(255, 68, 202, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            iconSize: 42,
            icon: Icon(
                _isSongPlaying ? Icons.music_note : Icons.play_circle_fill,
                color: Colors.yellowAccent),
            tooltip: "ABC Song",
            onPressed: _toggleAbcSong,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            // Đã đổi khoảng cách dưới từ 0 thành 60 để không bị sát đáy
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: alphabetData.length,
              itemBuilder: (context, index) {
                final item = alphabetData[index];
                return GestureDetector(
                  onTap: () => _hienThiChiTiet(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.3),
                          width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 2))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item["icon"]!,
                            style: const TextStyle(fontSize: 22)),
                        Text(
                          item["chu"]!,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent),
                        ),
                        Text(
                          item["vat"]!,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//   BẢNG CHỮ SỐ TIẾNG ANH (CÓ NÚT BÀI HÁT NUMBER SONG)
class TrangBangChuSoTiengAnh extends StatefulWidget {
  const TrangBangChuSoTiengAnh({super.key});
  @override
  State<TrangBangChuSoTiengAnh> createState() => _TrangBangChuSoTiengAnhState();
}
class _TrangBangChuSoTiengAnhState extends State<TrangBangChuSoTiengAnh>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Phát bài hát Number Song
  bool _isNumberSongPlaying = false;
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  late AnimationController _nhayController;
  late Animation<double> _nhayAnimation;
  late Animation<double> _chiTayAnimation;
  final List<Map<String, String>> numberData = [
    {"chu": "0","pa": "Zero","vat": "Zero","icon": "⭕","cau": "Number Zero."},
    {"chu": "1","pa": "One","vat": "Apple","icon": "🍎","cau": "Number One. 1 Apple."},
    {"chu": "2","pa": "Two","vat": "Bees","icon": "🐝","cau": "Number Two. 2 Bees."},
    {"chu": "3","pa": "Three","vat": "Stars","icon": "⭐","cau": "Number Three. 3 Stars."},
    {"chu": "4","pa": "Four","vat": "Fishes","icon": "🐟","cau": "Number Four. 4 Fishes."},
    {"chu": "5","pa": "Five","vat": "Apples","icon": "🍎","cau": "Number Five. 5 Apples."},
    {"chu": "6","pa": "Six","vat": "Eggs","icon": "🥚","cau": "Number Six. 6 Eggs."},
    {"chu": "7","pa": "Seven","vat": "Rainbow","icon": "🌈","cau": "Number Seven. 7 Rainbows."},
    {"chu": "8","pa": "Eight","vat": "Spiders","icon": "🕷️","cau": "Number Eight. 8 Spiders."},
    {"chu": "9","pa": "Nine","vat": "Balloons","icon": "🎈","cau": "Number Nine. 9 Balloons."},
    {"chu": "10","pa": "Ten","vat": "Hands","icon": "👐","cau": "Number Ten. 10 Hands."},
    {"chu": "11","pa": "Eleven","vat": "Birds","icon": "🐦","cau": "Number Eleven. 11 Birds."},
    {"chu": "12","pa": "Twelve","vat": "Gifts","icon": "🎁","cau": "Number Twelve. 12 Gifts."},
    {"chu": "13", "pa": "Thirteen", "vat": "Cakes", "icon": "🍰", "cau": "Number Thirteen. 13 Cakes."},
    {"chu": "14", "pa": "Fourteen", "vat": "Hats", "icon": "👒", "cau": "Number Fourteen. 14 Hats."},
    {"chu": "15", "pa": "Fifteen", "vat": "Balls", "icon": "⚽", "cau": "Number Fifteen. 15 Balls."},
    {"chu": "16", "pa": "Sixteen", "vat": "Cars", "icon": "🚗", "cau": "Number Sixteen. 16 Cars."},
    {"chu": "17", "pa": "Seventeen", "vat": "Leaves", "icon": "🍃", "cau": "Number Seventeen. 17 Leaves."},
    {"chu": "18", "pa": "Eighteen", "vat": "Candies", "icon": "🍬", "cau": "Number Eighteen. 18 Candies."},
    {"chu": "19", "pa": "Nineteen", "vat": "Flowers", "icon": "🌸", "cau": "Number Nineteen. 19 Flowers."},
    {"chu": "20", "pa": "Twenty", "vat": "Trees", "icon": "🌳", "cau": "Number Twenty. 20 Trees."}
  ];
  @override
  void initState() {
    super.initState();
    _khoiTaoTts();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _nhayController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _nhayAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
    _chiTayAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    flutterTts.stop();
    _audioPlayer.dispose();
    _nhayController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.45);
  }
  // Phát bài hát Number Song
  Future<void> _toggleNumberSong() async {
    if (_isNumberSongPlaying) {
      await _audioPlayer.stop();
      setState(() => _isNumberSongPlaying = false);
    } else {
      try {
        await _audioPlayer.play(AssetSource('number_song.mp3'));
        setState(() => _isNumberSongPlaying = true);
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isNumberSongPlaying = false);
        });
      } catch (_) {}
    }
  }
  Future<void> _hienThiChiTietSo(Map<String, String> data) async {
    await flutterTts.stop();
    setState(() {
      _currentWordStart = 0;
      _currentWordEnd = 0;
    });
    String chu = data["chu"]!;
    String phienAm = data["pa"]!; // Lấy tên tiếng Anh (One, Two...)
    String icon = data["icon"]!;
    String vat = data["vat"]!;
    String fullText = data["cau"]!;
    int soLuong = int.tryParse(chu) ?? 0;
    bool hasPopped = false;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Center(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              flutterTts.setProgressHandler((text, start, end, word) {
                if (mounted) {
                  setDialogState(() {
                    _currentWordStart = start;
                    _currentWordEnd = end;
                  });
                }
              });
              flutterTts.setCompletionHandler(() {
                if (!hasPopped && mounted) {
                  hasPopped = true;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop();
                    }
                  });
                }
              });
              return Dialog(
                backgroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 450,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.purple, width: 3),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _chiTayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(_chiTayAnimation.value, 0),
                                child: const Text("👉",
                                    style: TextStyle(fontSize: 30)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedBuilder(
                              animation: _nhayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, _nhayAnimation.value),
                                child: Text(
                                  chu,
                                  style: const TextStyle(
                                    fontSize: 60,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // HIỂN THỊ TÊN TIẾNG ANH (ONE, TWO...) NGAY DƯỚI SỐ
                        Text(
                          phienAm,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 0),
                        soLuong > 0
                            ? Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: List.generate(
                                  soLuong,
                                  (index) => Text(icon,
                                      style: const TextStyle(fontSize: 26)),
                                ),
                              )
                            : Text(icon, style: const TextStyle(fontSize: 42)),
                        const SizedBox(height: 0),
                        Text(vat,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        const SizedBox(height: 0),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildHighlightedText(fullText),
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    await flutterTts.speak(fullText);
  }
  List<TextSpan> _buildHighlightedText(String text) {
    List<TextSpan> spans = [];
    if (_currentWordStart >= 0 &&
        _currentWordEnd <= text.length &&
        _currentWordStart < _currentWordEnd) {
      spans.add(TextSpan(text: text.substring(0, _currentWordStart)));
      spans.add(TextSpan(
        text: text.substring(_currentWordStart, _currentWordEnd),
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: text.substring(_currentWordEnd)));
    } else {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: const Text("Numbers (0 - 20)",
            style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        backgroundColor: const ui.Color.fromARGB(162, 39, 176, 176),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // Nút phát bài hát Number Song trên thanh AppBar
          IconButton(
            iconSize: 42,
            icon: Icon(
                _isNumberSongPlaying
                    ? Icons.music_note
                    : Icons.play_circle_fill,
                color: Colors.yellowAccent),
            tooltip: "Number Song",
            onPressed: _toggleNumberSong,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: numberData.length,
              itemBuilder: (context, index) {
                final item = numberData[index];
                return GestureDetector(
                  onTap: () => _hienThiChiTietSo(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.purple.withOpacity(0.3), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 2))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                item["chu"]!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                    fontSize: 32),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            item["pa"]!,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 5. BẢNG MÀU SẮC TIẾNG ANH
class TrangBangMauSacTiengAnh extends StatefulWidget {
  const TrangBangMauSacTiengAnh({super.key});
  @override
  State<TrangBangMauSacTiengAnh> createState() =>
      _TrangBangMauSacTiengAnhState();
}
class _TrangBangMauSacTiengAnhState extends State<TrangBangMauSacTiengAnh>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  // Các biến phục vụ hiệu ứng karaoke và hoạt hình
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  late AnimationController _nhayController;
  late Animation<double> _nhayAnimation;
  late Animation<double> _chiTayAnimation;
  final List<Map<String, dynamic>> colorData = [
    {"ten": "Red", "pa": "Red", "color": Colors.red, "icon": "🔴", "cau": "This is Red color."},
    {"ten": "Blue", "pa": "Blue", "color": Colors.blue, "icon": "🔵", "cau": "This is Blue color."},
    {"ten": "Green", "pa": "Green", "color": Colors.green, "icon": "🟢", "cau": "This is Green color."},
    {"ten": "Yellow", "pa": "Yellow", "color": Colors.yellow, "icon": "🟡", "cau": "This is Yellow color."},
    {"ten": "Orange", "pa": "Orange", "color": Colors.orange, "icon": "🟠", "cau": "This is Orange color."},
    {"ten": "Purple", "pa": "Purple", "color": Colors.purple, "icon": "🟣", "cau": "This is Purple color."},
    {"ten": "Pink", "pa": "Pink", "color": Colors.pink, "icon": "🌸", "cau": "This is Pink color."},
    {"ten": "Brown", "pa": "Brown", "color": Colors.brown, "icon": "🌰", "cau": "Brown."},
  ];

  @override
  void initState() {
    super.initState();
    _khoiTaoTts();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Khởi tạo hiệu ứng nhảy nhót (giống bên Số)
    _nhayController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _nhayAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
    _chiTayAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    flutterTts.stop();
    _nhayController.dispose();
    // để khi bấm quay lại thanh điều hướng không bị hiện lên.
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.35);
  }
  // Hàm hiển thị Popup chi tiết khi bấm vào một màu (giống bên Số)
  Future<void> _hienThiChiTietMau(Map<String, dynamic> data) async {
    await flutterTts.stop();
    setState(() {
      _currentWordStart = 0;
      _currentWordEnd = 0;
    });
    String tenMau = data["ten"]!;
    String phienAm = data["pa"]!; // Lấy phiên âm
    String icon = data["icon"]!;
    Color mauSac = data["color"] as Color;
    String fullText = data["cau"]!;
    bool hasPopped = false;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Center(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              // Lắng nghe tiến trình đọc của TTS để đổi màu chữ (hiệu ứng Karaoke)
              flutterTts.setProgressHandler((text, start, end, word) {
                if (mounted) {
                  setDialogState(() {
                    _currentWordStart = start;
                    _currentWordEnd = end;
                  });
                }
              });
              // Tự động đóng popup khi đọc xong câu
              flutterTts.setCompletionHandler(() {
                if (!hasPopped && mounted) {
                  hasPopped = true;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop();
                    }
                  });
                }
              });
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 450,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: mauSac, width: 3),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dòng icon và tên màu có hiệu ứng nhảy & chỉ tay
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _chiTayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(_chiTayAnimation.value, 0),
                                child: const Text("👉",
                                    style: TextStyle(fontSize: 30)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedBuilder(
                              animation: _nhayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, _nhayAnimation.value),
                                child: Text(
                                  tenMau,
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                    color: mauSac,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Thêm phiên âm ngay dưới tên màu trong popup
                        Text(
                          phienAm,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Icon màu sắc phóng to ở giữa
                        Text(icon, style: const TextStyle(fontSize: 60)),
                        const SizedBox(height: 20),
                        // Câu hoàn chỉnh có hiệu ứng sáng chữ theo giọng đọc (Karaoke)
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildHighlightedText(fullText),
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    // Bắt đầu đọc câu
    await flutterTts.speak(fullText);
  }
  // Hàm chia nhỏ text để tô màu chữ đang đọc
  List<TextSpan> _buildHighlightedText(String text) {
    List<TextSpan> spans = [];
    if (_currentWordStart >= 0 &&
        _currentWordEnd <= text.length &&
        _currentWordStart < _currentWordEnd) {
      spans.add(TextSpan(text: text.substring(0, _currentWordStart)));
      spans.add(TextSpan(
        text: text.substring(_currentWordStart, _currentWordEnd),
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: text.substring(_currentWordEnd)));
    } else {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: const Text("Colors (Màu sắc)",
            style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        backgroundColor: const ui.Color.fromARGB(255, 30, 195, 233),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: colorData.length,
              itemBuilder: (context, index) {
                final item = colorData[index];
                return GestureDetector(
                  onTap: () => _hienThiChiTietMau(item), // Gọi hàm hiển thị popup chi tiết
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: item["color"] as Color, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 2))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item["icon"] as String,
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(
                          item["ten"] as String,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: item["color"] as Color),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TuVungModel {
  final String tiengAnh;
  final String phienAm;
  final String tiengViet;
  final String? hinhAnh;
  TuVungModel({
    required this.tiengAnh,
    required this.phienAm,
    required this.tiengViet,
    this.hinhAnh,
  });
  String get duongDanAnh => 'assets/images/${tiengAnh.toLowerCase()}.png';
}
class ChuDeModel {
  final int idLevel;
  final String tieuDe;
  final String tieuDeTiengViet;
  final Color mauChuDao;
  final List<TuVungModel> danhSachTu;
  final String? anhNenCustom;
  ChuDeModel({
    required this.idLevel,
    required this.tieuDe,
    required this.tieuDeTiengViet,
    required this.mauChuDao,
    required this.danhSachTu,
    this.anhNenCustom,
  });
  String get anhNenThe => 'assets/images/menu/bg_${tieuDe.toLowerCase()}.png';
}
final List<ChuDeModel> dataAppTiengAnh = [
  ChuDeModel(
    idLevel: 1,
    tieuDe: "FAMILY",
    tieuDeTiengViet: "1. GIA ĐÌNH (LEVEL 1)",
    mauChuDao: const ui.Color.fromARGB(255, 0, 195, 255),
    anhNenCustom: "assets/chudegiadinh.png",
    danhSachTu: [
      TuVungModel(
        tiengAnh: "Father",
        phienAm: "/ˈfɑː.ðər/",
        tiengViet: "Bố / Cha",
        hinhAnh: "images/father.png",
      ),
      TuVungModel(
        tiengAnh: "Mother",
        phienAm: "/ˈmʌð.ər/",
        tiengViet: "Mẹ",
        hinhAnh: "images/mother.png",
      ),
      TuVungModel(
        tiengAnh: "Baby",
        phienAm: "/ˈbeɪ.bi/",
        tiengViet: "Em bé",
        hinhAnh: "images/baby.png",
      ),
      TuVungModel(
        tiengAnh: "Grandfather",
        phienAm: "/ˈɡrændˌfɑː.ðər/",
        tiengViet: "Ông",
        hinhAnh: "images/grandfather.png",
      ),
      TuVungModel(
        tiengAnh: "Grandmother",
        phienAm: "/ˈɡrændˌmʌð.ər/",
        tiengViet: "Bà",
        hinhAnh: "images/grandmother.png",
      ),
      // --- Bổ sung các thành viên họ hàng liên quan ---
      TuVungModel(
        tiengAnh: "Brother",
        phienAm: "/ˈbrʌð.ər/",
        tiengViet: "Anh / Em trai",
        hinhAnh: "images/brother.png",
      ),
      TuVungModel(
        tiengAnh: "Sister",
        phienAm: "/ˈsɪs.tər/",
        tiengViet: "Chị / Em gái",
        hinhAnh: "images/sister.png",
      ),
      TuVungModel(
        tiengAnh: "Uncle",
        phienAm: "/ˈʌŋ.kəl/",
        tiengViet: "Bác / Chú / Cậu / Dượng",
        hinhAnh: "images/uncle.png",
      ),
      TuVungModel(
        tiengAnh: "Aunt",
        phienAm: "/ænt/",
        tiengViet: "Bác gái / Cô / Dì / Mợ",
        hinhAnh: "images/aunt.png",
      ),
      TuVungModel(
        tiengAnh: "Cousin",
        phienAm: "/ˈkʌz.ən/",
        tiengViet: "Anh chị em họ",
        hinhAnh: "images/cousin.png",
      ),
      TuVungModel(
        tiengAnh: "Nephew",
        phienAm: "/ˈnef.juː/",
        tiengViet: "Cháu trai (con của anh/chị/em)",
        hinhAnh: "images/nephew.png",
      ),
      TuVungModel(
        tiengAnh: "Niece",
        phienAm: "/niːs/",
        tiengViet: "Cháu gái (con của anh/chị/em)",
        hinhAnh: "images/niece.png",
      ),
      TuVungModel(
        tiengAnh: "Son",
        phienAm: "/sʌn/",
        tiengViet: "Con trai",
        hinhAnh: "images/son.png",
      ),
      TuVungModel(
        tiengAnh: "Daughter",
        phienAm: "/ˈdɔː.tər/",
        tiengViet: "Con gái",
        hinhAnh: "images/daughter.png",
      ),
      TuVungModel(
        tiengAnh: "Husband",
        phienAm: "/ˈhʌz.bənd/",
        tiengViet: "Chồng",
        hinhAnh: "images/husband.png",
      ),
      TuVungModel(
        tiengAnh: "Wife",
        phienAm: "/waɪf/",
        tiengViet: "Vợ",
        hinhAnh: "images/wife.png",
      ),
    ],
  ),
  ChuDeModel(
    idLevel: 2,
    tieuDe: "HOME",
    tieuDeTiengViet: "2. ĐỒ DÙNG TRONG NHÀ (LEVEL 2)",
    mauChuDao: const Color(0xFF9C27B0),
    anhNenCustom: "assets/dodungtrongnha.png",
    danhSachTu: [
      TuVungModel(
          tiengAnh: "Chair",
          phienAm: "/tʃeər/",
          tiengViet: "Cái ghế",
          hinhAnh: "images/chair.png"),
      TuVungModel(
          tiengAnh: "Table",
          phienAm: "/ˈteɪ.bl̩/",
          tiengViet: "Cái bàn",
          hinhAnh: "images/table.png"),
      TuVungModel(
          tiengAnh: "Bed",
          phienAm: "/bed/",
          tiengViet: "Cái giường",
          hinhAnh: "images/bed.png"),
    ],
  ),
  ChuDeModel(
    idLevel: 3,
    tieuDe: "ANIMALS",
    tieuDeTiengViet: "3. ĐỘNG VẬT",
    mauChuDao: const Color(0xFF2196F3),
    anhNenCustom: "assets/chudedongvat.png",
    danhSachTu: [
      TuVungModel(
          tiengAnh: "Dog",
          phienAm: "/dɒɡ/",
          tiengViet: "Con chó",
          hinhAnh: "images/dog.png"),
      TuVungModel(
          tiengAnh: "Cat",
          phienAm: "/kæt/",
          tiengViet: "Con mèo",
          hinhAnh: "images/cat.png"),
      TuVungModel(
          tiengAnh: "Lion",
          phienAm: "/ˈlaɪ.ən/",
          tiengViet: "Sư tử",
          hinhAnh: "images/lion.png"),
    ],
  ),
  ChuDeModel(
    idLevel: 4,
    tieuDe: "TRANSPORT",
    tieuDeTiengViet: "4. GIAO THÔNG",
    mauChuDao: const Color(0xFFE91E63),
    anhNenCustom: "assets/chudegiaothong.png",
    danhSachTu: [
      TuVungModel(
          tiengAnh: "Car",
          phienAm: "/kɑːr/",
          tiengViet: "Ô tô",
          hinhAnh: "images/car.png"),
      TuVungModel(
          tiengAnh: "Bicycle",
          phienAm: "/ˈbaɪ.sɪ.kl̩/",
          tiengViet: "Xe đạp",
          hinhAnh: "images/bicycle.png"),
    ],
  ),
  ChuDeModel(
    idLevel: 5,
    tieuDe: "WEATHER",
    tieuDeTiengViet: "5. THỜI TIẾT",
    mauChuDao: const Color(0xFF00BCD4),
    anhNenCustom: "assets/chudethoitiet.png",
    danhSachTu: [
      TuVungModel(
          tiengAnh: "Sun",
          phienAm: "/sʌn/",
          tiengViet: "Mặt trời",
          hinhAnh: "images/sun.png"),
      TuVungModel(
          tiengAnh: "Rain",
          phienAm: "/reɪn/",
          tiengViet: "Cơn mưa",
          hinhAnh: "images/rain.png"),
      TuVungModel(
          tiengAnh: "Cloud",
          phienAm: "/klaʊd/",
          tiengViet: "Đám mây",
          hinhAnh: "images/cloud.png"),
    ],
  ),
];
class TrangHocMoRongTiengAnh extends StatefulWidget {
  const TrangHocMoRongTiengAnh({super.key});
  @override
  State<TrangHocMoRongTiengAnh> createState() => _TrangHocMoRongTiengAnhState();
}
class _TrangHocMoRongTiengAnhState extends State<TrangHocMoRongTiengAnh> {
  int levelHienTaiCuaBe = 1;
  int _giayConLai = 1800; // 30 phút
  Timer? _timerCuaBe;
  bool _daHetGioHoc = false;
  final PageController _mainPageController =
      PageController(viewportFraction: 0.68);
  double _viTriTrangHienTai = 0.0;
  @override
  void initState() {
    super.initState();
    _batDauDemGioHoc();
    _mainPageController.addListener(() {
      setState(() {
        _viTriTrangHienTai = _mainPageController.page ?? 0.0;
      });
    });
  }
  void _batDauDemGioHoc() {
    _timerCuaBe = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_giayConLai > 0) {
        setState(() {
          _giayConLai--;
          if (_giayConLai == 60) {
            _hienThongBaoNghiNgoi(ngayLapTuc: false);
          }
        });
      } else {
        _timerCuaBe?.cancel();
        setState(() => _daHetGioHoc = true);
        _hienThongBaoNghiNgoi(ngayLapTuc: true);
      }
    });
  }
  void _hienThongBaoNghiNgoi({required bool ngayLapTuc}) {
    showDialog(
      context: context,
      barrierDismissible: !ngayLapTuc,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.alarm_on_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("Nhắc Nhở Bé Yêu",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Giờ nạp kiến thức của con đã phù hợp, con hãy dừng lại và nghỉ ngơi nhé!",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Dạ vâng ạ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }
  String _dinhDangThoiGian(int tongSoGiay) {
    int phut = tongSoGiay ~/ 60;
    int giay = tongSoGiay % 60;
    return '${phut.toString().padLeft(2, '0')}:${giay.toString().padLeft(2, '0')}';
  }
  @override
  void dispose() {
    _timerCuaBe?.cancel();
    _mainPageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 118, 188, 200),
      body: Stack(
        children: [
          Positioned(
              top: -50,
              right: -50,
              child: _bongBongTrangTri(200, Colors.white.withOpacity(0.1))),
          Positioned(
              bottom: -60,
              left: -40,
              child: _bongBongTrangTri(220, Colors.white.withOpacity(0.1))),
          Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.68,
              child: PageView.builder(
                controller: _mainPageController,
                physics: const BouncingScrollPhysics(),
                itemCount: dataAppTiengAnh.length,
                itemBuilder: (context, index) {
                  final chuDe = dataAppTiengAnh[index];
                  final bool laLevelHopLe = chuDe.idLevel <= levelHienTaiCuaBe;
                  double hieuUngScale = 1.0;
                  double doMo = 1.0;
                  if (_viTriTrangHienTai.floor() == index) {
                    hieuUngScale = 1.0 - (_viTriTrangHienTai - index) * 0.12;
                    doMo = 1.0 - (_viTriTrangHienTai - index) * 0.2;
                  } else if (_viTriTrangHienTai.floor() + 1 == index) {
                    hieuUngScale = 0.88 + (index - _viTriTrangHienTai) * 0.12;
                    doMo = 0.8 + (index - _viTriTrangHienTai) * 0.2;
                  } else {
                    hieuUngScale = 0.88;
                    doMo = 0.8;
                  }
                  bool dangOChinhGiua =
                      (_viTriTrangHienTai - index).abs() < 0.3;
                  return Transform.scale(
                    scale: hieuUngScale,
                    child: Opacity(
                      opacity: doMo.clamp(0.5, 1.0),
                      child: _taoKhungHocHorizontal(
                        context,
                        chuDe,
                        laLevelHopLe,
                        dangOChinhGiua,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _nutQuayLaiChuan(context),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _daHetGioHoc ? Colors.red : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_sharp,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _dinhDangThoiGian(_giayConLai),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swipe_rounded,
                        color: Colors.blueGrey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Bé vuốt sang để chọn môn học nhé",
                      style: TextStyle(
                        color: Colors.blueGrey.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
// NÚT QUAY LẠI CHUNG Ở PHẦN CHỦ ĐỀ TIẾNG ANH
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.brown,
          size: 20,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
  Widget _bongBongTrangTri(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
  Widget _taoKhungHocHorizontal(
      BuildContext context, dynamic chuDe, bool laLevelHopLe, bool isCenter) {
    return GestureDetector(
      onTap: () {
        if (_daHetGioHoc) {
          _hienThongBaoNghiNgoi(ngayLapTuc: true);
          return;
        }
        if (!laLevelHopLe) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  "Bé yêu ơi! Hãy hoàn thành các Level trước để mở khóa môn học này nhé!"),
              backgroundColor: Colors.amber.shade900,
            ),
          );
          return;
        }
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrangChiTietTuVung(
              chuDe: chuDe,
              onLevelHoanThanh: () {
                if (levelHienTaiCuaBe == chuDe.idLevel) {
                  setState(() {
                    levelHienTaiCuaBe++;
                  });
                }
              },
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          // Thiết kế đường viền sắc nét theo đúng màu chủ đạo (rực rỡ giống ảnh mẫu)
          border: Border.all(
            color: chuDe.mauChuDao,
            width: isCenter ? 4.5 : 3.5,
          ),
          // Đổ bóng theo màu chủ đạo giúp thẻ nổi bật
          boxShadow: [
            BoxShadow(
              color: chuDe.mauChuDao.withOpacity(isCenter ? 0.35 : 0.15),
              blurRadius: isCenter ? 18 : 8,
              offset: Offset(0, isCenter ? 6 : 3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                color: laLevelHopLe
                    ? chuDe.mauChuDao.withOpacity(0.12)
                    : Colors.grey.shade200,
                child: Text(
                  chuDe.tieuDeTiengViet,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color:
                        laLevelHopLe ? chuDe.mauChuDao : Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Giữ nguyên màu sắc rực rỡ của ảnh nền ngay cả khi bị khóa
                    Image.asset(
                      chuDe.anhNenCustom ?? chuDe.anhNenThe,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.image_rounded,
                            size: 50, color: Colors.grey.shade400),
                      ),
                    ),
                    // Lớp phủ mờ hiển thị biểu tượng ổ khóa khi bài học chưa được mở
                    if (!laLevelHopLe)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.white70,
                              radius: 26,
                              child: Icon(Icons.lock_rounded,
                                  color: Colors.black54, size: 30),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Cần hoàn thành bài trước",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// CHI TIẾT TỪ VỰNG
class TrangChiTietTuVung extends StatefulWidget {
  final ChuDeModel chuDe;
  final VoidCallback onLevelHoanThanh;
  const TrangChiTietTuVung({
    super.key,
    required this.chuDe,
    required this.onLevelHoanThanh,
  });
  @override
  State<TrangChiTietTuVung> createState() => _TrangChiTietTuVungState();
}
class _TrangChiTietTuVungState extends State<TrangChiTietTuVung> {
  late FlutterTts _flutterTts;
  int _indexDangDoc = -1;
  bool _dangTuDongDoc = false;
  bool _dangTamDung = false;
  late List<TuVungModel> _danhSachNgauNhien;
  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _khoiTaoTts();
    _danhSachNgauNhien = List<TuVungModel>.from(widget.chuDe.danhSachTu);
    _danhSachNgauNhien.shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1200))
          .then((_) => _chayDocVaKiemTraTheoCum(0));
    });
  }
  void _khoiTaoTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.1);
  }
  Future<void> _chayDocVaKiemTraTheoCum(int viTriBatDau) async {
    if (_dangTuDongDoc || !mounted) return;
    setState(() {
      _dangTuDongDoc = true;
      _dangTamDung = false;
    });
    int viTriKetThuc = (viTriBatDau + 5 < _danhSachNgauNhien.length)
        ? viTriBatDau + 5
        : _danhSachNgauNhien.length;
    for (int i = viTriBatDau; i < viTriKetThuc; i++) {
      if (!mounted) break;
      while (_dangTamDung && mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (!mounted) break;
      setState(() {
        _indexDangDoc = i;
      });
      final tu = _danhSachNgauNhien[i];
      final String tiengAnhAnToan = tu.tiengAnh;
      final String tiengVietAnToan = tu.tiengViet;
      // ================= 1. ĐỌC TIẾNG ANH =================
      var completerAnh = Completer<void>();
      _flutterTts.setCompletionHandler(() {
        if (!completerAnh.isCompleted) {
          completerAnh.complete();
        }
      });
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.1);
      await _flutterTts.speak(tiengAnhAnToan);
      await Future.any([
        completerAnh.future,
        Future.delayed(Duration(milliseconds: (tiengAnhAnToan.length * 100) + 1000))
      ]);
      if (!mounted || _dangTamDung) break;
      // Nghỉ giữa tiếng Anh và tiếng Việt
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || _dangTamDung) break;
      // ================= 2. ĐỌC TIẾNG VIỆT THUYẾT MINH =================
      var completerViet = Completer<void>();
      _flutterTts.setCompletionHandler(() {
        if (!completerViet.isCompleted) {
          completerViet.complete();
        }
      });
      await _flutterTts.setLanguage("vi-VN");
      await _flutterTts.setSpeechRate(0.55);
      await _flutterTts.setPitch(1.2);
      String cauThuyetMinh = "Đây là $tiengVietAnToan,";
      await _flutterTts.speak(cauThuyetMinh);
      await Future.any([
        completerViet.future,
        Future.delayed(Duration(milliseconds: (cauThuyetMinh.length * 100) + 1000))
      ]);
      if (!mounted) break;
      // Nghỉ ngắn trước khi sang từ tiếp theo
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted && !_dangTamDung) {
      setState(() {
        _dangTuDongDoc = false;
        _indexDangDoc = -1;
      });
      List<TuVungModel> namTuVuaHoc =
          _danhSachNgauNhien.sublist(viTriBatDau, viTriKetThuc);
      _chuyenSangManHinhKiemTra5Tu(namTuVuaHoc, viTriKetThuc);
    }
  }
  void _chuyenSangManHinhKiemTra5Tu(
    List<TuVungModel> danhSach5Tu, int viTriTiepTheo) {
    if (!mounted) return;
    _flutterTts.stop();
    final chuDeCuomModel = ChuDeModel(
      idLevel: widget.chuDe.idLevel,
      tieuDe: widget.chuDe.tieuDe,
      tieuDeTiengViet: "${widget.chuDe.tieuDeTiengViet} (Kiểm tra)",
      mauChuDao: widget.chuDe.mauChuDao,
      danhSachTu: danhSach5Tu,
      anhNenCustom: widget.chuDe.anhNenCustom,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManHinhKiemTraLeVel(
          chuDeHienTai: chuDeCuomModel,
          onMoKhoaLevelTiepTheo: () {
            Navigator.pop(context, true);
          },
        ),
      ),
    ).then((ketQua) {
      if (!mounted) return;
      setState(() {
        _dangTuDongDoc = false;
      });
      if (viTriTiepTheo >= _danhSachNgauNhien.length) {
        widget.onLevelHoanThanh();
        Navigator.pop(context);
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _chayDocVaKiemTraTheoCum(viTriTiepTheo);
          }
        });
      }
    });
  }
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 1, 16, 1),
          child: Column(
            children: [
              // ================= HÀNG CHỨA NÚT QUAY LẠI, TIÊU ĐỀ VÀ NÚT TẠM DỪNG =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // 1. NÚT QUAY LẠI TRÒN
                    GestureDetector(
                      onTap: () {
                        _flutterTts.stop();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.chuDe.mauChuDao,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.brown,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 2. TIÊU ĐỀ NẰM BÊN HÔNG
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(-50, 130),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, right: 4),
                          child: Text(
                            widget.chuDe.tieuDeTiengViet,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: widget.chuDe.mauChuDao,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 3. NÚT TẠM DỪNG / PHÁT
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.chuDe.mauChuDao,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _dangTamDung ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: widget.chuDe.mauChuDao,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _dangTamDung = !_dangTamDung;
                            if (_dangTamDung) {
                              _flutterTts.stop();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // ================= KHUNG LỚN PHÍA TRÊN =================
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.52,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  padding: const EdgeInsets.fromLTRB(20, 1, 20, 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _indexDangDoc != -1
                          ? Colors.redAccent
                          : widget.chuDe.mauChuDao.withOpacity(0.3),
                      width: _indexDangDoc != -1 ? 4 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _indexDangDoc != -1 &&
                          _indexDangDoc < _danhSachNgauNhien.length
                      ? Builder(
                          builder: (context) {
                            final tuDangDoc = _danhSachNgauNhien[_indexDangDoc];
                            final String duongDanAnh =
                                (tuDangDoc.hinhAnh != null &&
                                        tuDangDoc.hinhAnh!.startsWith("images/"))
                                    ? tuDangDoc.hinhAnh!
                                    : "images/${tuDangDoc.hinhAnh ?? ''}";
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      duongDanAnh,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image_rounded,
                                              size: 50,
                                              color: Colors.redAccent),
                                          SizedBox(height: 2),
                                          Text("Lỗi tải ảnh asset",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tuDangDoc.tiengAnh,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  tuDangDoc.phienAm,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  tuDangDoc.tiengViet,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 54,
                                  color: widget.chuDe.mauChuDao.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text(
                                "Đang chuẩn bị học từ vựng...",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              // ================= DANH SÁCH CUỘN NGANG PHÍA DƯỚI =================
              SizedBox(
                height: 95,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _danhSachNgauNhien.length,
                  itemBuilder: (context, index) {
                    final tuHienTai = _danhSachNgauNhien[index];
                    final bool dangHighlight = (_indexDangDoc == index);
                    final String duongDanAnh =
                        (tuHienTai.hinhAnh != null &&
                                tuHienTai.hinhAnh!.startsWith("images/"))
                            ? tuHienTai.hinhAnh!
                            : "images/${tuHienTai.hinhAnh ?? ''}";
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _indexDangDoc = index;
                        });
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: dangHighlight
                              ? Colors.yellow.shade100
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: dangHighlight
                                ? Colors.redAccent
                                : widget.chuDe.mauChuDao.withOpacity(0.3),
                            width: dangHighlight ? 3 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                duongDanAnh,
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_rounded,
                                    size: 24,
                                    color: widget.chuDe.mauChuDao),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tuHienTai.tiengAnh,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: dangHighlight
                                          ? Colors.redAccent
                                          : widget.chuDe.mauChuDao,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tuHienTai.tiengViet, // 👈 Đã sửa lại đúng biến tiếng Việt thay vì tiếng Anh
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
class ManHinhKiemTraLeVel extends StatefulWidget {
  final ChuDeModel chuDeHienTai;
  final VoidCallback onMoKhoaLevelTiepTheo;
  const ManHinhKiemTraLeVel({
    super.key,
    required this.chuDeHienTai,
    required this.onMoKhoaLevelTiepTheo,
  });
  @override
  State<ManHinhKiemTraLeVel> createState() => _ManHinhKiemTraLeVelState();
}

class _ManHinhKiemTraLeVelState extends State<ManHinhKiemTraLeVel> {
  late FlutterTts _flutterTts;
  int _indexCauHoi = 0;
  List<TuVungModel> _danhSachLuaChon = [];
  TuVungModel? _tuDapAnDung;
  TuVungModel? _tuDaChon;
  TuVungModel? _tuBiSaiDangPhongTo; // Dùng để phóng to và ẩn các thành phần khác
  bool _daChonDung = false; 
  int _chiSoDangDoc = -1; 
  int _chiSoPhienAmDangDoc = -1;
  bool _dangChayHieuUongDoc = false;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _khoiTaoTts();
    _chuanBiCauHoi();
  }

  void _khoiTaoTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.1);
  }

  void _phatAmVaChayChu(String tuVung, String phienAm) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak(tuVung);
    if (_dangChayHieuUongDoc) return;
    setState(() {
      _dangChayHieuUongDoc = true;
      _chiSoDangDoc = 0;
      _chiSoPhienAmDangDoc = phienAm.isNotEmpty ? 0 : -1;
    });
    int doDaiTu = tuVung.length;
    int doDaiPhienAm = phienAm.length;
    int thoiGianMoiKyTuTu = (1200 ~/ doDaiTu).clamp(80, 250);
    int maxSteps = doDaiTu > doDaiPhienAm ? doDaiTu : doDaiPhienAm;
    for (int i = 0; i < maxSteps; i++) {
      await Future.delayed(Duration(milliseconds: thoiGianMoiKyTuTu));
      if (!mounted) return;
      setState(() {
        if (i < doDaiTu) _chiSoDangDoc = i;
        if (phienAm.isNotEmpty && i < doDaiPhienAm) {
          _chiSoPhienAmDangDoc = i;
        }
      });
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _chiSoDangDoc = -1;
        _chiSoPhienAmDangDoc = -1;
        _dangChayHieuUongDoc = false;
      });
    }
  }

  void _chuanBiCauHoi() {
    setState(() {
      _tuDaChon = null;
      _tuBiSaiDangPhongTo = null; // Reset trạng thái phóng to khi sang câu mới
      _daChonDung = false;
      _chiSoDangDoc = -1;
      _chiSoPhienAmDangDoc = -1;
      _tuDapAnDung = widget.chuDeHienTai.danhSachTu[_indexCauHoi];
      List<TuVungModel> danhSachNieu = List<TuVungModel>.from(widget.chuDeHienTai.danhSachTu);
      danhSachNieu.remove(_tuDapAnDung);
      danhSachNieu.shuffle();
      int soLuongLuaChon = danhSachNieu.length >= 2 ? 2 : danhSachNieu.length;
      _danhSachLuaChon = [_tuDapAnDung!];
      _danhSachLuaChon.addAll(danhSachNieu.sublist(0, soLuongLuaChon));
      _danhSachLuaChon.shuffle();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _phatAmVaChayChu(_tuDapAnDung!.tiengAnh, _tuDapAnDung!.phienAm);
      }
    });
  }

  void _chuyenCauHoicoDinh() {
    if (_indexCauHoi < widget.chuDeHienTai.danhSachTu.length - 1) {
      setState(() {
        _indexCauHoi++;
      });
      _chuanBiCauHoi();
    } else {
      widget.onMoKhoaLevelTiepTheo();
      setState(() {
        _indexCauHoi = 0;
      });
      _chuanBiCauHoi();
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tuHienThi = _tuBiSaiDangPhongTo ?? _tuDapAnDung;
    String tuHienTai = tuHienThi?.tiengAnh ?? "";
    String phienAmHienTai = _tuBiSaiDangPhongTo != null ? "" : (_tuDapAnDung?.phienAm ?? ""); 
    final String duongDanAnhHienThi = (tuHienThi?.hinhAnh != null && tuHienThi!.hinhAnh!.startsWith("images/"))
        ? tuHienThi.hinhAnh!
        : "images/${tuHienThi?.hinhAnh ?? ''}";

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              // --- PHẦN THAY THẾ CHO APPBAR (GIỮ NGUYÊN MÀU SẮC BAN ĐẦU) ---
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _flutterTts.stop();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded, 
                        color: Colors.brown, 
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.chuDeHienTai.tieuDeTiengViet,
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        color: widget.chuDeHienTai.mauChuDao, // Hoặc màu tự nhiên bạn muốn
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Nút loa để đọc lại nội dung ở góc phải
                  GestureDetector(
                    onTap: () {
                      if (_tuDapAnDung != null) {
                        _phatAmVaChayChu(_tuDapAnDung!.tiengAnh, _tuDapAnDung!.phienAm);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded, 
                        color: Colors.orange, 
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- PHẦN NỘI DUNG CHÍNH BÊN DƯỚI ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _tuBiSaiDangPhongTo != null ? Colors.red.shade400 : Colors.orange.withOpacity(0.3),
                      width: _tuBiSaiDangPhongTo != null ? 3.5 : 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      duongDanAnhHienThi,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_rounded, size: 60, color: Colors.orange),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(tuHienTai.length, (index) {
                  bool dangDocKyTuNay = (_tuBiSaiDangPhongTo == null && index <= _chiSoDangDoc);
                  return Text(
                    tuHienTai[index],
                    style: TextStyle(
                      fontSize: _tuBiSaiDangPhongTo != null ? 38 : 32,
                      fontWeight: FontWeight.w900,
                      color: _tuBiSaiDangPhongTo != null 
                          ? Colors.red 
                          : (dangDocKyTuNay ? Colors.green.shade700 : Colors.redAccent),
                    ),
                  );
                }),
              ),
              if (phienAmHienTai.isNotEmpty && _tuBiSaiDangPhongTo == null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(phienAmHienTai.length, (index) {
                    bool dangDocPhienAmNay = (index <= _chiSoPhienAmDangDoc);
                    return Text(
                      phienAmHienTai[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: dangDocPhienAmNay ? Colors.green.shade600 : Colors.brown.shade400,
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 12),
              if (_tuBiSaiDangPhongTo == null)
                SizedBox(
                  height: 50, 
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: _danhSachLuaChon.length,
                    itemBuilder: (context, index) {
                      final tuLuaChon = _danhSachLuaChon[index];
                      final bool laLuaChonCuaBe = (_tuDaChon == tuLuaChon);
                      final bool laDapAnDung = (tuLuaChon == _tuDapAnDung);
                      Color borderColor = Colors.orange.withOpacity(0.3);
                      Color backgroundColor = Colors.white;
                      if (_daChonDung && laDapAnDung) {
                        borderColor = Colors.green;
                        backgroundColor = Colors.green.shade50;
                      } else if (_tuDaChon != null && laLuaChonCuaBe && !laDapAnDung) {
                        borderColor = Colors.red;
                        backgroundColor = Colors.red.shade50;
                      }
                      return GestureDetector(
                        onTap: (_tuDaChon != null && !_daChonDung) ? null : () async {
                          setState(() {
                            _tuDaChon = tuLuaChon;
                          });
                          if (laDapAnDung) {
                            setState(() {
                              _daChonDung = true; 
                            });
                            await _flutterTts.setLanguage("en-US");
                            _flutterTts.speak("Very good!");
                            Future.delayed(const Duration(milliseconds: 2000), () {
                              if (mounted) _chuyenCauHoicoDinh();
                            });
                          } else {
                            setState(() {
                              _tuBiSaiDangPhongTo = tuLuaChon;
                            });
                            await _flutterTts.setLanguage("vi-VN");
                            _flutterTts.speak("Sai rồi bé ơi, đây là!");
                            Future.delayed(const Duration(milliseconds: 2000), () async {
                              if (mounted) {
                                await _flutterTts.setLanguage("en-US");
                                _flutterTts.speak(tuLuaChon.tiengAnh);
                              }
                            });
                            Future.delayed(const Duration(milliseconds: 3000), () async {
                              if (mounted) {
                                await _flutterTts.setLanguage("vi-VN");
                                _flutterTts.speak(tuLuaChon.tiengViet);
                              }
                            });
                            Future.delayed(const Duration(milliseconds: 3500), () {
                              if (mounted) {
                                setState(() {
                                  _tuDaChon = null;
                                  _tuBiSaiDangPhongTo = null;
                                });
                              }
                            });
                          }
                        },
                        child: Container(
                          width: 170,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor, 
                              width: (laLuaChonCuaBe || (_daChonDung && laDapAnDung)) ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  tuLuaChon.tiengViet,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                              if (_daChonDung && laDapAnDung) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                              ] else if (_tuDaChon != null && laLuaChonCuaBe && !laDapAnDung) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );}}

class ItemTuVungCard extends StatefulWidget {
  final TuVungModel tu;
  final Color mauChuDao;
  final FlutterTts flutterTts;
  final AudioPlayer audioPlayer;
  const ItemTuVungCard({
    super.key,
    required this.tu,
    required this.mauChuDao,
    required this.flutterTts,
    required this.audioPlayer,
  });
  @override
  State<ItemTuVungCard> createState() => _ItemTuVungCardState();
}

class _ItemTuVungCardState extends State<ItemTuVungCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _dangTai = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.30)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.30, end: 0.85)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.85, end: 1.10)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
    ]).animate(_controller);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _kichHoatHanhDong() async {
    if (_dangTai) return;
    await widget.flutterTts.stop();
    await widget.audioPlayer.stop();
    _controller.reset();
    await widget.flutterTts.speak(widget.tu.tiengAnh);
    Future.delayed(const Duration(milliseconds: 850), () async {
      if (!mounted) return;
      _controller.forward();
      setState(() => _dangTai = true);
      final url = Uri.parse(
          'https://api.dictionaryapi.dev/api/v2/entries/en/${widget.tu.tiengAnh.toLowerCase()}');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          String urlAudio = "";
          if (data.isNotEmpty && data[0]['phonetics'] != null) {
            for (var phonetic in data[0]['phonetics']) {
              if (phonetic['audio'] != null &&
                  phonetic['audio'].toString().isNotEmpty) {
                urlAudio = phonetic['audio'];
                break;
              }
            }
          }
          if (urlAudio.isNotEmpty && mounted) {
            if (urlAudio.startsWith('//')) urlAudio = 'https:$urlAudio';
            await widget.audioPlayer.play(UrlSource(urlAudio));
          }
        }
      } catch (e) {
        debugPrint("Lỗi tải âm thanh API: $e");
      } finally {
        if (mounted) setState(() => _dangTai = false);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _kichHoatHanhDong,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: widget.mauChuDao.withOpacity(0.2), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.mauChuDao.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _dangTai
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: widget.mauChuDao))
                        : Image.asset(
                            widget.tu.duongDanAnh,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.image_rounded,
                                color: widget.mauChuDao.withOpacity(0.3),
                                size: 22),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.tu.tiengAnh,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: widget.mauChuDao)),
                  const SizedBox(height: 2),
                  Text(widget.tu.tiengViet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF666666))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.volume_up_rounded,
                  color: widget.mauChuDao, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// TRÒ CHƠI TIẾNG ANH
class TrangTroChoiTiengAnh extends StatelessWidget {
  const TrangTroChoiTiengAnh({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text("English Games",
            style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          const Center(
            child: Text(
              "Trò chơi tiếng Anh đang được hoàn thiện...",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepOrange),
            ),
          ),
        ],
      ),
    );
  }
}
Widget _nutQuayLaiChuan(BuildContext context) {
  return Positioned(
    bottom: 25,
    left: 25,
    child: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
            color: Colors.redAccent, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
      ),
    ),
  );
}

//  TRANG TIẾNG VIỆT CHUNG
class TrangTiengViet extends StatelessWidget {
  const TrangTiengViet({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC), // Màu nền vàng kem ấm áp
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text(
          "Tiếng Việt Cho Bé",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        // Áp dụng màu AppBar trong suốt mờ ảo cực đẹp giống trang Đếm Quả
        backgroundColor: const ui.Color.fromARGB(148, 64, 255, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Nội dung chính: 3 Menu lựa chọn lớn (Học cơ bản, Học mở rộng, Trò chơi)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMenuCard(
                    context,
                    title: "HỌC CƠ BẢN",
                    subtitle: "Chữ cái, Số & Màu sắc",
                    icon: "🔤",
                    color: Colors.lightBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangMenuHocCoBanTiengViet()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    title: "HỌC MỞ RỘNG",
                    subtitle: "Ghép âm & Từ vựng",
                    icon: "🧩",
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangHocMoRongTiengViet()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    title: "TRÒ CHƠI",
                    subtitle: "Ôn tập & Luyện tập",
                    icon: "🎮",
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangTroChoiTiengViet()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Hàm tạo Nút quay lại chuẩn hình tròn viền cam có bóng đổ
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// TRANG HỌC CƠ BẢN TIẾNG VIỆT
class TrangMenuHocCoBanTiengViet extends StatelessWidget {
  const TrangMenuHocCoBanTiengViet({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text(
          "Học Cơ Bản Tiếng Việt",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        // Áp dụng màu AppBar trong suốt mờ ảo đồng bộ
        backgroundColor: const ui.Color.fromARGB(148, 64, 255, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSubMenuCard(
                    context,
                    title: "BẢNG CHỮ CÁI",
                    subtitle: "A, Ă, Â, B, C...",
                    icon: "🅰️",
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangBangChuCaiTiengViet()),
                      );
                    },
                  ),
                  _buildSubMenuCard(
                    context,
                    title: "BẢNG CHỮ SỐ",
                    subtitle: "1, 2, 3, 4...",
                    icon: "🔢",
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangBangChuSoTiengViet()),
                      );
                    },
                  ),
                  _buildSubMenuCard(
                    context,
                    title: "BẢNG MÀU SẮC",
                    subtitle: "Đỏ, Xanh, Vàng...",
                    icon: "🎨",
                    color: Colors.pink,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrangBangMauSacTiengViet()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm tạo Nút quay lại chuẩn hình tròn viền cam có bóng đổ
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSubMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// BẢNG CHỮ CÁI TIẾNG VIỆT
// 1. CHI TIẾT BẢNG CHỮ CÁI TIẾNG VIỆT
// ==========================================
class TrangBangChuCaiTiengViet extends StatefulWidget {
  const TrangBangChuCaiTiengViet({super.key});
  @override
  State<TrangBangChuCaiTiengViet> createState() =>
      _TrangBangChuCaiTiengVietState();
}
class _TrangBangChuCaiTiengVietState extends State<TrangBangChuCaiTiengViet>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  late AnimationController _nhayController;
  late Animation<double> _nhayAnimation;

  final List<Map<String, String>> alphabetData = [
    {"chu": "A", "phatAm": "a", "vat": "", "icon": "🍎", "cau": "Chữ A. Quả Táo."},
    {"chu": "Ă", "phatAm": "ắ", "vat": "", "icon": "🌙", "cau": "Chữ Ă. Mặt Trăng."},
    {"chu": "Â", "phatAm": "ớ", "vat": "", "icon": "🍄", "cau": "Chữ Â. Cây Nấm."},
    {"chu": "B", "phatAm": "bờ", "vat": "", "icon": "🐮", "cau": "Chữ B. Con Bò."},
    {"chu": "C", "phatAm": "cờ", "vat": "", "icon": "🐟", "cau": "Chữ C. Con Cá."},
    {"chu": "D", "phatAm": "dờ", "vat": "", "icon": "🍉", "cau": "Chữ D. Quả Dưa."},
    {"chu": "Đ", "phatAm": "đờ", "vat": "", "icon": "🔦", "cau": "Chữ Đ. Đèn Pin."},
    {"chu": "E", "phatAm": "e", "vat": "", "icon": "👶", "cau": "Chữ E. Em Bé."},
    {"chu": "Ê", "phatAm": "ê", "vat": "", "icon": "🐸", "cau": "Chữ Ê. Con Ếch."},
    {"chu": "G", "phatAm": "gờ", "vat": "", "icon": "🐔", "cau": "Chữ G. Con Gà."},
    {"chu": "H", "phatAm": "hờ", "vat": "", "icon": "🌸", "cau": "Chữ H. Bông Hoa."},
    {"chu": "I", "phatAm": "i", "vat": "", "icon": "🔮", "cau": "Chữ I. Viên Bi."},
    {"chu": "K", "phatAm": "ca", "vat": "", "icon": "🥤", "cau": "Chữ K. Cái Ca."},
    {"chu": "L", "phatAm": "lờ", "vat": "", "icon": "🍃", "cau": "Chữ L. Chiếc Lá."},
    {"chu": "M", "phatAm": "mờ", "vat": "", "icon": "🐱", "cau": "Chữ M. Con Mèo."},
    {"chu": "N", "phatAm": "nờ", "vat": "", "icon": "🎀", "cau": "Chữ N. Nơ Hồng."},
    {"chu": "O", "phatAm": "o", "vat": "", "icon": "🐝", "cau": "Chữ O. Con Ong."},
    {"chu": "Ô", "phatAm": "ô", "vat": "", "icon": "☂️", "cau": "Chữ Ô. Cái Ô."},
    {"chu": "Ơ", "phatAm": "ơ", "vat": "", "icon": "🚩", "cau": "Chữ Ơ. Lá Cờ."},
    {"chu": "P", "phatAm": "pờ", "vat": "", "icon": "💎", "cau": "Chữ P. Pha Lê."},
    {"chu": "Q", "phatAm": "quy", "vat": "", "icon": "🪭", "cau": "Chữ Q. Quạt Giấy."},
    {"chu": "R", "phatAm": "rờ", "vat": "", "icon": "🐢", "cau": "Chữ R. Con Rùa."},
    {"chu": "S", "phatAm": "sờ", "vat": "", "icon": "⭐", "cau": "Chữ S. Ngôi Sao."},
    {"chu": "T", "phatAm": "tờ", "vat": "", "icon": "🐰", "cau": "Chữ T. Con Thỏ."},
    {"chu": "U", "phatAm": "u", "vat": "", "icon": "🦉", "cau": "Chữ U. Con Cú."},
    {"chu": "Ư", "phatAm": "ư", "vat": "", "icon": "🦌", "cau": "Chữ Ư. Con Hươu."},
    {"chu": "V", "phatAm": "vờ", "vat": "", "icon": "🐘", "cau": "Chữ V. Con Voi."},
    {"chu": "X", "phatAm": "xờ", "vat": "", "icon": "🚚", "cau": "Chữ X. Xe Tải."},
    {"chu": "Y", "phatAm": "i dài", "vat": "", "icon": "👩‍⚕️", "cau": "Chữ Y. Y Sĩ"}
  ];

  @override
  void initState() {
    super.initState();
    _khoiTaoTts();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _nhayController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _nhayAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    flutterTts.stop();
    _nhayController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.45);
  }
  Future<void> _hienThiChiTiet(Map<String, String> data) async {
    await flutterTts.stop();
    setState(() {
      _currentWordStart = 0;
      _currentWordEnd = 0;
    });
    String chu = data["chu"]!;
    String phatAm = data["phatAm"]!;
    String icon = data["icon"]!;
    String fullText = data["cau"]!;
    bool hasPopped = false;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Center(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              flutterTts.setProgressHandler((text, start, end, word) {
                if (mounted) {
                  setDialogState(() {
                    _currentWordStart = start;
                    _currentWordEnd = end;
                  });
                }
              });
              flutterTts.setCompletionHandler(() {
                if (!hasPopped && mounted) {
                  hasPopped = true;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop();
                    }
                  });
                }
              });
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.blueAccent, width: 3),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(chu,
                            style: const TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent)),
                        const SizedBox(height: 2),
                        // Hiển thị phần phát âm ngay dưới chữ cái trong popup phóng to
                        Text(
                          phatAm,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedBuilder(
                          animation: _nhayAnimation,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, _nhayAnimation.value),
                            child: Text(icon,
                                style: const TextStyle(fontSize: 50)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildHighlightedText(fullText),
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    await flutterTts.speak(fullText);
  }
  List<TextSpan> _buildHighlightedText(String text) {
    List<TextSpan> spans = [];
    if (_currentWordStart >= 0 &&
        _currentWordEnd <= text.length &&
        _currentWordStart < _currentWordEnd) {
      spans.add(TextSpan(text: text.substring(0, _currentWordStart)));
      spans.add(TextSpan(
        text: text.substring(_currentWordStart, _currentWordEnd),
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: text.substring(_currentWordEnd)));
    } else {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }
  // Hàm tạo Nút quay lại chuẩn hình tròn viền cam có bóng đổ
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text("Bảng Chữ Cái Tiếng Việt",
            style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        // Áp dụng màu AppBar trong suốt mờ ảo đồng bộ
        backgroundColor: const ui.Color.fromARGB(148, 64, 255, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.1,
              ),
              itemCount: alphabetData.length,
              itemBuilder: (context, index) {
                final item = alphabetData[index];
                return GestureDetector(
                  onTap: () => _hienThiChiTiet(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.3),
                          width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 2))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item["icon"]!,
                            style: const TextStyle(fontSize: 20)),
                        Text(
                          item["chu"]!,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent),
                        ),
                        // Thêm dòng phát âm nhỏ ở dưới chân ô ngoài màn hình chính
                        Text(
                          item["phatAm"]!,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 2. BẢNG CHỮ SỐ TIẾNG VIỆT
class TrangBangChuSoTiengViet extends StatefulWidget {
  const TrangBangChuSoTiengViet({super.key});
  @override
  State<TrangBangChuSoTiengViet> createState() =>
      _TrangBangChuSoTiengVietState();
}
class _TrangBangChuSoTiengVietState extends State<TrangBangChuSoTiengViet>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  late AnimationController _nhayController;
  late Animation<double> _nhayAnimation;
  late Animation<double> _chiTayAnimation;
  final List<Map<String, String>> numberData = [
    {"chu": "0", "pa": "Không", "vat": "", "icon": "", "cau": "Số Không. Không có gì"},
    {"chu": "1", "pa": "Một", "vat": "", "icon": "🍎", "cau": "Số Một. 1 quả Táo"},
    {"chu": "2", "pa": "Hai", "vat": "", "icon": "🐝", "cau": "Số Hai. 2 con Ong"},
    {"chu": "3", "pa": "Ba", "vat": "", "icon": "⭐", "cau": "Số Ba. 3 ngôi Sao"},
    {"chu": "4", "pa": "Bốn", "vat": "", "icon": "🐟", "cau": "Số Bốn. 4 con Cá"},
    {"chu": "5", "pa": "Năm", "vat": "", "icon": "🍎", "cau": "Số Năm. 5 quả Táo"},
    {"chu": "6", "pa": "Sáu", "vat": "", "icon": "🥚", "cau": "Số Sáu. 6 quả Trứng"},
    {"chu": "7", "pa": "Bảy", "vat": "", "icon": "🌈", "cau": "Số Bảy. 7 cầu Vồng"},
    {"chu": "8", "pa": "Tám", "vat": "", "icon": "🕷️", "cau": "Số Tám. 8 con Nhện"},
    {"chu": "9", "pa": "Chín", "vat": "", "icon": "🎈", "cau": "Số Chín. 9 quả Bóng Bay"},
    {"chu": "10", "pa": "Mười", "vat": "", "icon": "👐", "cau": "Số Mười. 10 Bàn Tay"},
    {"chu": "11", "pa": "Mười Một", "vat": "", "icon": "🐦", "cau": "Số Mười Một. 11 Con Chim"},
    {"chu": "12", "pa": "Mười Hai", "vat": "", "icon": "🎁", "cau": "Số Mười Hai. 12 Hộp Quà"},
    {"chu": "13", "pa": "Mười Ba", "vat": "", "icon": "🍰", "cau": "Số Mười Ba. 13 Cái Bánh"},
    {"chu": "14", "pa": "Mười Bốn", "vat": "", "icon": "👒", "cau": "Số Mười Bốn. 14 Cái Mũ"},
    {"chu": "15", "pa": "Mười Năm", "vat": "", "icon": "⚽", "cau": "Số Mười Năm. 15 Quả Bóng"},
    {"chu": "16", "pa": "Mười Sáu", "vat": "", "icon": "🚗", "cau": "Số Mười Sáu. 16 Ô Tô"},
    {"chu": "17", "pa": "Mười Bảy", "vat": "", "icon": "🍃", "cau": "Số Mười Bảy. 17 Chiếc Lá"},
    {"chu": "18", "pa": "Mười Tám", "vat": "", "icon": "🍬", "cau": "Số Mười Tám. 18 Viên Kẹo"},
    {"chu": "19", "pa": "Mười Chín", "vat": "", "icon": "🌸", "cau": "Số Mười Chín. 19 Bông Hoa"},
    {"chu": "20", "pa": "Hai Mươi", "vat": "", "icon": "🌳", "cau": "Số Hai Mươi. 20 Cái Cây"}
  ];

  @override
  void initState() {
    super.initState();
    _khoiTaoTts();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _nhayController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    // Hiệu ứng nhảy cho số
    _nhayAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
    // Hiệu ứng dịch chuyển nhẹ cho ngón tay chỉ vào số
    _chiTayAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _nhayController.dispose();
    super.dispose();
  }

  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.45);
  }

  Future<void> _hienThiChiTietSo(Map<String, String> data) async {
    await flutterTts.stop();
    setState(() {
      _currentWordStart = 0;
      _currentWordEnd = 0;
    });
    String chu = data["chu"]!;
    String icon = data["icon"]!;
    String vat = data["vat"]!;
    String fullText = data["cau"]!;
    int soLuong = int.tryParse(chu) ?? 0;
    bool hasPopped = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Center(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              flutterTts.setProgressHandler((text, start, end, word) {
                if (mounted) {
                  setDialogState(() {
                    _currentWordStart = start;
                    _currentWordEnd = end;
                  });
                }
              });
              flutterTts.setCompletionHandler(() {
                if (!hasPopped && mounted) {
                  hasPopped = true;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop();
                    }
                  });
                }
              });
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 450,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.purple, width: 3),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // HÀNG CHỨA NGÓN TAY CHỈ VÀ CON SỐ NHẢY MÚA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Ngón tay chỉ trái qua phải/lên xuống thu hút bé
                            AnimatedBuilder(
                              animation: _chiTayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(_chiTayAnimation.value, 0),
                                child: const Text("👉",
                                    style: TextStyle(fontSize: 30)),
                              ),
                            ),
                            const SizedBox(width: 0),
                            // Con số nhảy múa chính
                            AnimatedBuilder(
                              animation: _nhayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, _nhayAnimation.value),
                                child: Text(
                                  chu,
                                  style: const TextStyle(
                                    fontSize: 60,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 0),
                        // CÁC ICON VẬT THỂ MINH HỌA SỐ LƯỢNG
                        soLuong > 0
                            ? Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: List.generate(
                                  soLuong,
                                  (index) => Text(icon,
                                      style: const TextStyle(fontSize: 26)),
                                ),
                              )
                            : Text(icon, style: const TextStyle(fontSize: 42)),
                        const SizedBox(height: 0),
                        Text(vat,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        const SizedBox(height: 0),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildHighlightedText(fullText),
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    await flutterTts.speak(fullText);
  }

  List<TextSpan> _buildHighlightedText(String text) {
    List<TextSpan> spans = [];
    if (_currentWordStart >= 0 &&
        _currentWordEnd <= text.length &&
        _currentWordStart < _currentWordEnd) {
      spans.add(TextSpan(text: text.substring(0, _currentWordStart)));
      spans.add(TextSpan(
        text: text.substring(_currentWordStart, _currentWordEnd),
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: text.substring(_currentWordEnd)));
    } else {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }

  // Hàm tạo Nút quay lại chuẩn hình tròn viền cam có bóng đổ
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text("Bảng Chữ Số Tiếng Việt (0 - 20)",
            style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        // Áp dụng màu AppBar trong suốt mờ ảo đồng bộ
        backgroundColor: const ui.Color.fromARGB(148, 64, 255, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: numberData.length,
              itemBuilder: (context, index) {
                final item = numberData[index];
                return GestureDetector(
                  onTap: () => _hienThiChiTietSo(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.purple.withOpacity(0.3), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 2))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                item["chu"]!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                    fontSize: 32),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            item["pa"]!,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. CHI TIẾT BẢNG MÀU SẮC TIẾNG VIỆT
class TrangBangMauSacTiengViet extends StatefulWidget {
  const TrangBangMauSacTiengViet({super.key});
  @override
  State<TrangBangMauSacTiengViet> createState() =>
      _TrangBangMauSacTiengVietState();
}
class _TrangBangMauSacTiengVietState extends State<TrangBangMauSacTiengViet>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  late AnimationController _nhayController;
  late Animation<double> _nhayAnimation;
  late Animation<double> _chiTayAnimation;
  final List<Map<String, dynamic>> colorData = [
    {"ten": "Màu Đỏ", "pa": "Màu Đỏ", "color": Colors.red, "icon": "🔴", "cau": "Đây là Màu Đỏ."},
    {"ten": "Màu Xanh Dương", "pa": "Màu Xanh Dương", "color": Colors.blue, "icon": "🔵", "cau": "Đây là Màu Xanh Dương."},
    {"ten": "Màu Xanh Lá", "pa": "Màu Xanh Lá", "color": Colors.green, "icon": "🟢", "cau": "Đây là Màu Xanh Lá."},
    {"ten": "Màu Vàng", "pa": "Màu Vàng", "color": Colors.yellow, "icon": "🟡", "cau": "Đây là Màu Vàng."},
    {"ten": "Màu Cam", "pa": "Màu Cam", "color": Colors.orange, "icon": "🟠", "cau": "Đây là Màu Cam."},
    {"ten": "Màu Tím", "pa": "Màu Tím", "color": Colors.purple, "icon": "🟣", "cau": "Đây là Màu Tím."},
    {"ten": "Màu Hồng", "pa": "Màu Hồng", "color": Colors.pink, "icon": "🌸", "cau": "Đây là Màu Hồng."},
    {"ten": "Màu Nâu", "pa": "Màu Nâu", "color": Colors.brown, "icon": "🌰", "cau": "Đây là Màu Nâu."},
    {"ten": "Màu Trắng", "pa": "Màu Trắng", "color": Colors.white, "icon": "⚪", "cau": "Đây là Màu Trắng."},
    {"ten": "Màu Đen", "pa": "Màu Đen", "color": Colors.black, "icon": "⚫", "cau": "Đây là Màu Đen."},
    {"ten": "Màu Xám", "pa": "Màu Xám", "color": Colors.grey, "icon": "🗿", "cau": "Đây là Màu Xám."},
    {"ten": "Màu Xanh Ngọc", "pa": "Màu Xanh Ngọc", "color": Colors.cyan, "icon": "💠", "cau": "Đây là Màu Xanh Ngọc."},
    {"ten": "Màu Hổ Phách", "pa": "Màu Hổ Phách", "color": Colors.amber, "icon": "🔸", "cau": "Đây là Màu Hổ Phách."},
    {"ten": "Màu Xanh Mòng Két", "pa": "Màu Xanh Mòng Két", "color": Colors.teal, "icon": "🟩", "cau": "Đây là Màu Xanh Mòng Két."},
    {"ten": "Màu Chàm", "pa": "Màu Chàm", "color": Colors.indigo, "icon": "🔷", "cau": "Đây là Màu Chàm."},
  ];

  @override
  void initState() {
    super.initState();
    _khoiTaoTts();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _nhayController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _nhayAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
    _chiTayAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    flutterTts.stop();
    _nhayController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.45);
  }
  Future<void> _hienThiChiTietMau(Map<String, dynamic> data) async {
    await flutterTts.stop();
    setState(() {
      _currentWordStart = 0;
      _currentWordEnd = 0;
    });
    String tenMau = data["ten"]!;
    String phienAm = data["pa"]!;
    String icon = data["icon"]!;
    Color mauSac = data["color"] as Color;
    String fullText = data["cau"]!;
    bool hasPopped = false;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Center(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              flutterTts.setProgressHandler((text, start, end, word) {
                if (mounted) {
                  setDialogState(() {
                    _currentWordStart = start;
                    _currentWordEnd = end;
                  });
                }
              });
              flutterTts.setCompletionHandler(() {
                if (!hasPopped && mounted) {
                  hasPopped = true;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop();
                    }
                  });
                }
              });
              return Dialog(
                backgroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(color: mauSac, width: 3),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 450,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _chiTayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(_chiTayAnimation.value, 0),
                                child: const Text("👉",
                                    style: TextStyle(fontSize: 30)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedBuilder(
                              animation: _nhayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, _nhayAnimation.value),
                                child: Text(
                                  tenMau,
                                  style: TextStyle(
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                    color: mauSac,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Hiển thị phiên âm ngay dưới tên màu trong popup
                        Text(
                          phienAm,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(icon, style: const TextStyle(fontSize: 60)),
                        const SizedBox(height: 20),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildHighlightedText(fullText),
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    await flutterTts.speak(fullText);
  }
  List<TextSpan> _buildHighlightedText(String text) {
    List<TextSpan> spans = [];
    if (_currentWordStart >= 0 &&
        _currentWordEnd <= text.length &&
        _currentWordStart < _currentWordEnd) {
      spans.add(TextSpan(text: text.substring(0, _currentWordStart)));
      spans.add(TextSpan(
        text: text.substring(_currentWordStart, _currentWordEnd),
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: text.substring(_currentWordEnd)));
    } else {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }
  // Hàm tạo Nút quay lại chuẩn hình tròn viền cam có bóng đổ
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text("Bảng Màu Sắc Tiếng Việt",
            style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        // Áp dụng màu AppBar trong suốt mờ ảo đồng bộ
        backgroundColor: const ui.Color.fromARGB(148, 64, 255, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemCount: colorData.length,
              itemBuilder: (context, index) {
                final item = colorData[index];
                return GestureDetector(
                  onTap: () => _hienThiChiTietMau(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: item["color"] as Color, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 2))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item["icon"] as String,
                            style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 4),
                        Text(
                          item["ten"] as String,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: item["color"] as Color),
                        ),
                        // Thêm phiên âm nhỏ ở dưới chân ô ngoài màn hình chính
                        Text(
                          item["pa"]!,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// TRANG HỌC MỞ RỘNG TIẾNG VIỆT (Dành cho bé 5-6 tuổi)
class TrangHocMoRongTiengViet extends StatelessWidget {
  const TrangHocMoRongTiengViet({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text(
          "Học Mở Rộng Tiếng Việt",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(148, 64, 128, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: GridView.count(
          crossAxisCount: 2, // Hiển thị 2 cột trên màn hình ngang/tablet
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _buildMoRongCard(
              context,
              title: "1. GHÉP VẦN & ÂM VẬN",
              subtitle: "Luyện vần đôi, ghép âm, tạo tiếng",
              icon: "🧩",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrangGhepVan()),
                );
              },
            ),
            _buildMoRongCard(
              context,
              title: "2. TỪ VỰNG TRỰC QUAN",
              subtitle: "Gia đình, Động vật, Đồ vật quanh bé",
              icon: "📚",
              color: Colors.blueAccent,
              onTap: () {
                // Đảm bảo bạn đã định nghĩa class TrangTuVungTrucQuan ở phần khác của dự án
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrangTuVungTrucQuan()),
                );
              },
            ),
            _buildMoRongCard(
              context,
              title: "3. TẬP ĐỌC THƠ & CÂU",
              subtitle: "Thơ ca đồng dao & Câu ngắn vui nhộn",
              icon: "📖",
              color: Colors.purple,
              onTap: () {
                // Đảm bảo bạn đã định nghĩa class TrangTapDoctho ở phần khác của dự án
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrangTapDoctho()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Nút quay lại chuẩn
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // Khung thẻ bấm cho từng mục mở rộng
  Widget _buildMoRongCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. CÁC MÔ HÌNH DỮ LIỆU CHUẨN (Đã bỏ NhomVan)
class TiengHoc {
  final String tieng;
  final String amDau;
  final String van;
  final String thanh;
  final String cachDanhVan;
  final String giaiThich;
  final String cauViDu;
  final String bieuTuong; 
  const TiengHoc({
    required this.tieng,
    required this.amDau,
    required this.van,
    required this.thanh,
    required this.cachDanhVan,
    required this.giaiThich,
    required this.cauViDu,
    required this.bieuTuong,
  });
}

// Mô hình một bài học vần cụ thể
class BaiHocVan {
  final String tenBai;
  final String van;
  final String moTa;
  final List<TiengHoc> danhSachTieng;
  const BaiHocVan({
    required this.tenBai,
    required this.van,
    required this.moTa,
    required this.danhSachTieng,
  });
}

// CẤP ĐỘ HỌC
class CapDoHoc {
  final int id;
  final String tenCapDo;
  final String moTa;
  final Color mauSac;
  final List<BaiHocVan> danhSachBai;
  const CapDoHoc({
    required this.id,
    required this.tenCapDo,
    required this.moTa,
    required this.mauSac,
    required this.danhSachBai,
  });
}
// KHO DỮ LIỆU GHÉP ÂM
class KhoDuLieuHocTap {
  static const List<CapDoHoc> danhSachCapDo = [
    // CẤP ĐỘ 1: LÀM QUEN ÂM VÀ CHỮ
    CapDoHoc(
      id: 1,
      tenCapDo: "Cấp độ 1: Làm quen âm và chữ",
      moTa: "Làm quen nguyên âm đơn và các tiếng vỡ lòng",
      mauSac: Colors.green,
      danhSachBai: [
        BaiHocVan(
          tenBai: "Bài học nguyên âm A",
          van: "a",
          moTa: "Làm quen nguyên âm a và luyện đánh vần các tiếng vỡ lòng",
          danhSachTieng: [
            TiengHoc(
              tieng: "ba",
              amDau: "b",
              van: "a",
              thanh: "ngang",
              cachDanhVan: "a ... bờ - a - ba",
              giaiThich: "Người sinh ra và nuôi dưỡng bé.",
              cauViDu: "Ba mua quà cho bé.",
              bieuTuong: "👨",
            ),
            TiengHoc(
              tieng: "bà",
              amDau: "b",
              van: "a",
              thanh: "huyền",
              cachDanhVan: "a ... bờ - a - ba ... huyền ... bà",
              giaiThich: "Mẹ của ba hoặc mẹ của mẹ.",
              cauViDu: "Bà kể chuyện cho bé nghe.",
              bieuTuong: "👵",
            ),
            TiengHoc(
              tieng: "cá",
              amDau: "c",
              van: "a",
              thanh: "sắc",
              cachDanhVan: "a ... cờ - a - ca ... sắc ... cá",
              giaiThich: "Động vật sống dưới nước, bơi lội.",
              cauViDu: "Con cá bơi trong hồ.",
              bieuTuong: "🐟",
            ),
            TiengHoc(
              tieng: "ga",
              amDau: "g",
              van: "a",
              thanh: "ngang",
              cachDanhVan: "a ... gờ - a - ga",
              giaiThich: "Nơi tàu hỏa dừng đỗ đón trả khách.",
              cauViDu: "Tàu hỏa rời ga.",
              bieuTuong: "🚂",
            ),
          ],
        ),
        BaiHocVan(
          tenBai: "Bài học nguyên âm E",
          van: "e",
          moTa: "Làm quen và nhận biết nguyên âm E",
          danhSachTieng: [
            TiengHoc(
              tieng: "bé",
              amDau: "b",
              van: "e",
              thanh: "sắc",
              cachDanhVan: "e ... bờ - e - be ... sắc ... bé",
              giaiThich: "Em bé hoặc trẻ nhỏ.",
              cauViDu: "Bé chăm ngoan học giỏi.",
              bieuTuong: "👶",
            ),
            TiengHoc(
              tieng: "mẹ",
              amDau: "m",
              van: "e",
              thanh: "nặng",
              cachDanhVan: "e ... mờ - e - me ... nặng ... mẹ",
              giaiThich: "Người sinh ra bé.",
              cauViDu: "Mẹ yêu bé nhất.",
              bieuTuong: "👩",
            ),
            TiengHoc(
              tieng: "ve",
              amDau: "v",
              van: "e",
              thanh: "ngang",
              cachDanhVan: "e ... vờ - e - ve",
              giaiThich: "Côn trùng thường kêu vào mùa hè.",
              cauViDu: "Tiếng ve kêu râm ran.",
              bieuTuong: "🦗",
            ),
          ],
        ),
        BaiHocVan(
          tenBai: "Bài học nguyên âm O",
          van: "o",
          moTa: "Làm quen và nhận biết nguyên âm O",
          danhSachTieng: [
            TiengHoc(
              tieng: "bò",
              amDau: "b",
              van: "o",
              thanh: "huyền",
              cachDanhVan: "o ... bờ - o - bo ... huyền ... bò",
              giaiThich: "Động vật nuôi cho sữa ở nông trại.",
              cauViDu: "Con bò ăn cỏ trên đồng.",
              bieuTuong: "🐄",
            ),
            TiengHoc(
              tieng: "cô",
              amDau: "c",
              van: "o",
              thanh: "ngang",
              cachDanhVan: "o ... cờ - o - cô",
              giaiThich: "Người dạy học cho bé ở trường.",
              cauViDu: "Cô giáo dạy bé hát.",
              bieuTuong: "👩‍🏫",
            ),
            TiengHoc(
              tieng: "gà",
              amDau: "g",
              van: "o",
              thanh: "huyền",
              cachDanhVan: "o ... gờ - o - go ... huyền ... gà",
              giaiThich: "Động vật nuôi trong gia đình.",
              cauViDu: "Đàn gà mái đang mổ thóc.",
              bieuTuong: "🐔",
            ),
          ],
        ),
      ],
    ),

    // ==========================================
    // CẤP ĐỘ 2: GHÉP VẦN CƠ BẢN
    // ==========================================
    CapDoHoc(
      id: 2,
      tenCapDo: "Cấp độ 2: Ghép vần cơ bản",
      moTa: "Luyện đọc các vần không có âm cuối (ai, ao...)",
      mauSac: Colors.blueAccent,
      danhSachBai: [
        BaiHocVan(
          tenBai: "Bài học vần AI",
          van: "ai",
          moTa: "Làm quen và ghép tiếng với vần ai",
          danhSachTieng: [
            TiengHoc(
              tieng: "mai",
              amDau: "m",
              van: "ai",
              thanh: "ngang",
              cachDanhVan: "ai ... mờ - ai - mai",
              giaiThich: "Ngày tiếp theo hôm nay.",
              cauViDu: "Ngày mai bé đi dã ngoại.",
              bieuTuong: "📅",
            ),
            TiengHoc(
              tieng: "bài",
              amDau: "b",
              van: "ai",
              thanh: "huyền",
              cachDanhVan: "ai ... bờ - ai - bai ... huyền ... bài",
              giaiThich: "Nội dung học tập hoặc trò chơi.",
              cauViDu: "Bé làm bài tập rất chăm.",
              bieuTuong: "📚",
            ),
            TiengHoc(
              tieng: "hái",
              amDau: "h",
              van: "ai",
              thanh: "sắc",
              cachDanhVan: "ai ... hờ - ai - hai ... sắc ... hái",
              giaiThich: "Dùng tay ngắt lấy quả hoặc hoa.",
              cauViDu: "Bé hái hoa cúc tặng mẹ.",
              bieuTuong: "🌻",
            ),
          ],
        ),
        BaiHocVan(
          tenBai: "Bài học vần AO",
          van: "ao",
          moTa: "Làm quen và ghép tiếng với vần ao",
          danhSachTieng: [
            TiengHoc(
              tieng: "sao",
              amDau: "s",
              van: "ao",
              thanh: "ngang",
              cachDanhVan: "ao ... sờ - ao - sao",
              giaiThich: "Thiên thể tỏa sáng trên bầu trời đêm.",
              cauViDu: "Ngôi sao lấp lánh trên trời.",
              bieuTuong: "⭐",
            ),
            TiengHoc(
              tieng: "gào",
              amDau: "g",
              van: "ao",
              thanh: "huyền",
              cachDanhVan: "ao ... gờ - ao - gao ... huyền ... gào",
              giaiThich: "Kêu lớn tiếng.",
              cauViDu: "Gió thổi gào rít qua khe cửa.",
              bieuTuong: "💨",
            ),
            TiengHoc(
              tieng: "áo",
              amDau: "∅",
              van: "ao",
              thanh: "sắc",
              cachDanhVan: "ao ... sắc ... áo",
              giaiThich: "Trang phục mặc để che thân, giữ ấm.",
              cauViDu: "Mẹ mua cho bé áo mới.",
              bieuTuong: "👕",
            ),
          ],
        ),
      ],
    ),

    // ==========================================
    // CẤP ĐỘ 3: VẦN CÓ ÂM CUỐI
    // ==========================================
    CapDoHoc(
      id: 3,
      tenCapDo: "Cấp độ 3: Vần có âm cuối phong phú",
      moTa: "Nhận biết và ghép các tiếng vần an, ât...",
      mauSac: Colors.deepOrange,
      danhSachBai: [
        BaiHocVan(
          tenBai: "Bài học vần AN",
          van: "an",
          moTa: "Làm quen và luyện đọc vần an",
          danhSachTieng: [
            TiengHoc(
              tieng: "bàn",
              amDau: "b",
              van: "an",
              thanh: "huyền",
              cachDanhVan: "an ... bờ - an - ban ... huyền ... bàn",
              giaiThich: "Đồ vật có mặt phẳng để học tập, làm việc.",
              cauViDu: "Bé ngồi học bên bàn.",
              bieuTuong: "🪑",
            ),
            TiengHoc(
              tieng: "bạn",
              amDau: "b",
              van: "an",
              thanh: "nặng",
              cachDanhVan: "an ... bờ - an - ban ... nặng ... bạn",
              giaiThich: "Người cùng học hoặc cùng chơi với bé.",
              cauViDu: "Lan là bạn của bé.",
              bieuTuong: "👦",
            ),
            TiengHoc(
              tieng: "bán",
              amDau: "b",
              van: "an",
              thanh: "sắc",
              cachDanhVan: "an ... bờ - an - ban ... sắc ... bán",
              giaiThich: "Đưa hàng hóa để đổi lấy tiền.",
              cauViDu: "Mẹ bán rau ở chợ.",
              bieuTuong: "🛒",
            ),
            TiengHoc(
              tieng: "đàn",
              amDau: "đ",
              van: "an",
              thanh: "huyền",
              cachDanhVan: "an ... đờ - an - đan ... huyền ... đàn",
              giaiThich: "Nhạc cụ dùng để tạo ra âm thanh.",
              cauViDu: "Anh chơi đàn rất hay.",
              bieuTuong: "🎸",
            ),
            TiengHoc(
              tieng: "đan",
              amDau: "đ",
              van: "an",
              thanh: "ngang",
              cachDanhVan: "an ... đờ - an - đan",
              giaiThich: "Kết đan các sợi lại với nhau thành tấm, vật dụng.",
              cauViDu: "Bà đan áo ấm cho bé.",
              bieuTuong: "🧶",
            ),
            TiengHoc(
              tieng: "lan",
              amDau: "l",
              van: "an",
              thanh: "ngang",
              cachDanhVan: "an ... lờ - an - lan",
              giaiThich: "Tên loài hoa đẹp hoặc tên người.",
              cauViDu: "Hoa lan nở rộ trước sân.",
              bieuTuong: "🌸",
            ),
            TiengHoc(
              tieng: "màn",
              amDau: "m",
              van: "an",
              thanh: "huyền",
              cachDanhVan: "an ... mờ - an - man ... huyền ... màn",
              giaiThich: "Tấm vải căng ra để che hoặc làm màn cửa, màn ngủ.",
              cauViDu: "Mẹ buông màn cho bé ngủ.",
              bieuTuong: "🛏️",
            ),
            TiengHoc(
              tieng: "nhãn",
              amDau: "nh",
              van: "an",
              thanh: "ngã",
              cachDanhVan: "an ... nhờ - an - nhan ... ngã ... nhãn",
              giaiThich: "Tên một loại quả ngọt cùi dày, hạt nhỏ.",
              cauViDu: "Quả nhãn lồng rất ngọt.",
              bieuTuong: "🍇",
            ),
            TiengHoc(
              tieng: "tan",
              amDau: "t",
              van: "an",
              thanh: "ngang",
              cachDanhVan: "an ... tờ - an - tan",
              giaiThich: "Kết thúc một buổi học hoặc sự việc hòa tan.",
              cauViDu: "Bé tan trường về nhà.",
              bieuTuong: "🏫",
            ),
            TiengHoc(
              tieng: "tán",
              amDau: "t",
              van: "an",
              thanh: "sắc",
              cachDanhVan: "an ... tờ - an - tan ... sắc ... tán",
              giaiThich: "Phần rộng ở phía trên như tán cây, chiếc ô.",
              cauViDu: "Cây bàng tỏa tán lá rộng.",
              bieuTuong: "🌳",
            ),
          ],
        ),
        BaiHocVan(
          tenBai: "Bài học vần ÂT",
          van: "ât",
          moTa: "Làm quen và luyện đọc vần ât",
          danhSachTieng: [
            TiengHoc(
              tieng: "đất",
              amDau: "đ",
              van: "ât",
              thanh: "sắc",
              cachDanhVan: "ât ... đờ - ât - ât ... sắc ... đất",
              giaiThich: "Lớp bề mặt trái đất nơi cây cối sinh trưởng.",
              cauViDu: "Cây xanh bám rễ sâu vào đất.",
              bieuTuong: "🌱",
            ),
            TiengHoc(
              tieng: "mật",
              amDau: "m",
              van: "ât",
              thanh: "nặng",
              cachDanhVan: "ât ... mờ - ât - mât ... nặng ... mật",
              giaiThich: "Chất lỏng có vị ngọt đậm do ong hút mật hoa.",
              cauViDu: "Ong chăm chỉ hút mật.",
              bieuTuong: "🍯",
            ),
            TiengHoc(
              tieng: "nhất",
              amDau: "nh",
              van: "ât",
              thanh: "sắc",
              cachDanhVan: "ât ... nhờ - ât - nhất ... sắc ... nhất",
              giaiThich: "Vị trí đầu tiên, đứng đầu.",
              cauViDu: "Bé là học sinh chăm ngoan nhất lớp.",
              bieuTuong: "🥇",
            ),
          ],
        ),
      ],
    ),
  ];
}

// 2. GIAO DIỆN CHÍNH: TRANG CHỌN CẤP ĐỘ
class TrangGhepVan extends StatelessWidget {
  const TrangGhepVan({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  _nutQuayLaiChuan(context),
                  const SizedBox(width: 16),
                  const Text(
                    "Lộ Trình Học Vần Tiếng Việt",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: KhoDuLieuHocTap.danhSachCapDo.length,
                itemBuilder: (context, index) {
                  final capDo = KhoDuLieuHocTap.danhSachCapDo[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: capDo.mauSac, width: 2),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        capDo.tenCapDo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: capDo.mauSac,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          capDo.moTa,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrangDanhSachBaiHoc(capDo: capDo),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}

// 3. TRANG DANH SÁCH BÀI HỌC TRONG CẤP ĐỘ
class TrangDanhSachBaiHoc extends StatelessWidget {
  final CapDoHoc capDo;
  const TrangDanhSachBaiHoc({super.key, required this.capDo});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: Text(capDo.tenCapDo, style: const TextStyle(fontSize: 15, color: Colors.white)),
        backgroundColor: capDo.mauSac,
      ),
      body: capDo.danhSachBai.isEmpty
          ? const Center(
              child: Text(
                "Đang biên soạn bài học cho cấp độ này...",
                style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: capDo.danhSachBai.length,
              itemBuilder: (context, index) {
                final bai = capDo.danhSachBai[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: capDo.mauSac.withOpacity(0.2),
                      child: Text(bai.van.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: capDo.mauSac)),
                    ),
                    title: Text(bai.tenBai, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(bai.moTa),
                    trailing: const Icon(Icons.play_circle_fill, color: Colors.green, size: 32),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChiTietBaiHocScreen(baiHoc: bai),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// TRANG CHI TIẾT BÀI HỌC (Dùng âm thanh Text-to-Speech của máy)
class ChiTietBaiHocScreen extends StatefulWidget {
  final BaiHocVan baiHoc;
  const ChiTietBaiHocScreen({super.key, required this.baiHoc});

  @override
  State<ChiTietBaiHocScreen> createState() => _ChiTietBaiHocScreenState();
}

class _ChiTietBaiHocScreenState extends State<ChiTietBaiHocScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _caiDatTts();
  }

  // Cấu hình giọng đọc tiếng Việt cho máy
  Future<void> _caiDatTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.42); // Chỉnh tốc độ chậm hơn chút cho bé dễ nghe nhịp đánh vần
    await _flutterTts.setPitch(1.0);
  }

  // Hàm gọi máy đọc nội dung bất kỳ
  Future<void> _docThanhVien(String noiDung) async {
    if (noiDung.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(noiDung);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        title: Text(widget.baiHoc.tenBai, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BƯỚC 1: NHẬN BIẾT VẦN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepOrange, width: 3),
              ),
              child: Column(
                children: [
                  const Text("Bước 1: Nhận biết vần", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    widget.baiHoc.van.toUpperCase(),
                    style: const TextStyle(fontSize: 55, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () {
                      _docThanhVien(widget.baiHoc.van);
                    },
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    label: const Text("Nghe phát âm vần", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BƯỚC 2: HỌC TIẾNG MINH HỌA & ĐÁNH VẦN SƯ PHẠM
            const Text("Bước 2: Học tiếng & Đánh vần", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 10),
            ...widget.baiHoc.danhSachTieng.map((tieng) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(tieng.bieuTuong, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tieng.tieng.toUpperCase(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                            const SizedBox(height: 2),
                            // 👉 HIỂN THỊ CHUẨN CÁCH ĐÁNH VẦN SƯ PHẠM (ví dụ: bờ - a - ba - huyền - bà)
                            Text(
                              "Đánh vần: ${tieng.cachDanhVan}",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange),
                            ),
                            const SizedBox(height: 2),
                            Text(tieng.giaiThich, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text("Ví dụ: \"${tieng.cauViDu}\"", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.green)),
                          ],
                        ),
                      ),
                      // Nút phát âm: Bấm vào sẽ đọc cả cách đánh vần và từ để bé nghe nhịp chuẩn
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.blue, size: 28),
                        onPressed: () {
                          // Đọc chuỗi đánh vần sư phạm (vd: "bờ a ba huyền bà")
                          _docThanhVien(tieng.cachDanhVan);
                        },
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 20),

            // BƯỚC 3 & 4: LUYỆN TẬP & TRÒ CHƠI
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Chuyển sang màn hình Trò chơi ôn tập bài học này
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "🎮 Chơi trò chơi ôn tập bài này",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrangTuVungTrucQuan extends StatelessWidget {
  const TrangTuVungTrucQuan({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Từ Vựng Trực Quan"), backgroundColor: Colors.blueAccent),
      body: const Center(child: Text("Nội dung Từ Vựng theo chủ đề đang cập nhật...", style: TextStyle(fontSize: 16))),
    );
  }
}

class TrangTapDoctho extends StatelessWidget {
  const TrangTapDoctho({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tập Đọc Thơ & Câu"), backgroundColor: Colors.purple),
      body: const Center(child: Text("Nội dung Tập Đọc Thơ đang cập nhật...", style: TextStyle(fontSize: 16))),
    );
  }
}

// TRANG TRÒ CHƠI TIẾNG VIỆT (Ôn tập & Luyện tập)
class TrangTroChoiTiengViet extends StatelessWidget {
  const TrangTroChoiTiengViet({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // Màu nền hồng phấn sáng sủa, vui tươi
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text(
          "Trò Chơi Tiếng Việt",
          style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: GridView.count( // Đã sửa "con:" thành "child:" ở đây
          crossAxisCount: 2, // Hiển thị 2 cột cân đối
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _buildGameCard(
              context,
              title: "1. ĐỐ VUI TIẾNG VIỆT",
              subtitle: "Đố mẹo dân gian, đoán con vật, đồ vật",
              icon: "❓",
              color: Colors.deepOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrangDoVuiNgonNgu()),
                );
              },
            ),
            _buildGameCard(
              context,
              title: "2. ĐIỀN CHỮ CÁI THIẾU",
              subtitle: "Quan sát hình ảnh, hoàn thành từ",
              icon: "🧩",
              color: Colors.pinkAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrangDienChuThieu()),
                );
              },
            ),
            _buildGameCard(
              context,
              title: "3. TRÒ CHƠI Ô CHỮ",
              subtitle: "Giải ô chữ từ vựng vui nhộn",
              icon: "🎯",
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrangTroChoiOCu()),
                );
              },
            ),
            _buildGameCard(
              context,
              title: "4. GHÉP TỪ THÀNH CÂU",
              subtitle: "Sắp xếp xáo trộn thành câu có nghĩa",
              icon: "✨",
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrangGhepTuThanhCau()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Nút quay lại chuẩn
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // Khung thẻ trò chơi
  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CÁC MÀN HÌNH TRÒ CHƠI CON CHI TIẾT (Khung mẫu)
class TrangDoVuiNgonNgu extends StatelessWidget {
  const TrangDoVuiNgonNgu({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đố Vui Tiếng Việt"), backgroundColor: Colors.deepOrange),
      body: const Center(child: Text("Giao diện trò chơi Đố Vui đang phát triển...", style: TextStyle(fontSize: 16))),
    );
  }
}
class TrangDienChuThieu extends StatelessWidget {
  const TrangDienChuThieu({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Điền Chữ Cái Thiếu"), backgroundColor: Colors.pinkAccent),
      body: const Center(child: Text("Giao diện trò chơi Điền chữ đang phát triển...", style: TextStyle(fontSize: 16))),
    );
  }
}
class TrangTroChoiOCu extends StatelessWidget {
  const TrangTroChoiOCu({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trò Chơi Ô Chữ"), backgroundColor: Colors.purple),
      body: const Center(child: Text("Giao diện trò chơi Ô Chữ đang phát triển...", style: TextStyle(fontSize: 16))),
    );
  }
}
class TrangGhepTuThanhCau extends StatelessWidget {
  const TrangGhepTuThanhCau({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ghép Từ Thành Câu"), backgroundColor: Colors.teal),
      body: const Center(child: Text("Giao diện trò chơi Ghép câu đang phát triển...", style: TextStyle(fontSize: 16))),
    );
  }
}

/// TRANG TOÁN HỌC
class TrangToan extends StatelessWidget {
  const TrangToan({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      // ❌ ĐÃ LOẠI BỎ APPBAR ĐỂ TỐI ƯU KHÔNG GIAN
      body: Stack(
        children: [
          // Nội dung chính của trang (Danh sách các môn học)
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 60, 16,
                  16), // Khoảng cách trên để tránh đè lên nút quay lại
              children: [
                // Mục 1: Dạng Cơ Bản & Nền Tảng
                _taoMucToan(
                  context,
                  tieuDeMuc: "1. Dạng Cơ Bản & Nền Tảng",
                  mauSac: Colors.orangeAccent,
                  iconMuc: "🌱",
                  danhSachBai: [
                    {
                      "tieuDe": "Nhận biết mặt số",
                      "moTa": "Nhận diện chữ số qua hình ảnh trực quan",
                      "icon": "🔢",
                      "trangDich": const TrangMenuNhanBietSo(),
                    },
                    {
                      "tieuDe": "Phân biệt hình khối",
                      "moTa": "Nhận biết hình tròn, vuông, tam giác",
                      "icon": "⭐",
                      "trangDich": const TrangHinhKhoi(),
                    },
                    {
                      "tieuDe": "So sánh lớn - nhỏ",
                      "moTa": "Phân biệt kích thước lớn hơn, nhỏ hơn",
                      "icon": "⚖️",
                      "trangDich": const TrangSoSanh(),
                    },
                    {
                      "tieuDe": "Quy luật hình ảnh",
                      "moTa": "Tìm hình tiếp theo hoàn thành chuỗi",
                      "icon": "🧩",
                      "trangDich": const TrangQuyLuat(),
                    },
                    {
                      "tieuDe": "Phép cộng trừ",
                      "moTa": "Thêm bớt số lượng qua hình ảnh",
                      "icon": "➕",
                      "trangDich": const TrangCongTru(),
                    },
                    {
                      "tieuDe": "Tìm điểm khác biệt",
                      "moTa": "Rèn luyện tư duy quan sát",
                      "icon": "🔍",
                      "trangDich": const TrangKhacBiet(),
                    },
                    {
                      "tieuDe": "Bảng cửu chương",
                      "moTa": "Làm quen nhân chia qua thử thách",
                      "icon": "✖️",
                      "trangDich": const TrangBangCuuChuong(),
                    },
                  ],
                ),
                const SizedBox(height: 10),
                // Mục 2: Dạng Nâng Cao
                _taoMucToan(
                  context,
                  tieuDeMuc: "2. DẠNG NÂNG CAO TƯ DUY (5-6 TUỔI)",
                  mauSac: Colors.purpleAccent,
                  iconMuc: "🚀",
                  danhSachBai: [
                    {
                      "tieuDe": "Bảng tính logic", // Tên hiển thị dưới ô
                      "moTa": "Giải mã phép tính theo hàng và cột",
                      "icon": "🔢", // Hoặc icon hình bảng/lưới tùy ý
                      "trangDich": const TrangBangTinhLogic(), // Tên trang chi tiết bạn sẽ xây dựng
                    },
                    {
                      "tieuDe": "Mê cung số học",
                      "moTa": "Tìm đường đi qua các dãy số logic",
                      "icon": "🧭",
                      "trangDich": const TrangMeCungSo(),
                    },
                    {
                      "tieuDe": "Quy luật ẩn",
                      "moTa": "Giải mã chuỗi lặp đa tầng",
                      "icon": "🔮",
                      "trangDich": const TrangQuyLuatAn(),
                    },
                    {
                      "tieuDe": "Cân bằng phép toán",
                      "moTa": "Rèn luyện tư duy định lượng",
                      "icon": "⚖️",
                      "trangDich": const TrangCanBang(),
                    },
                    {
                      "tieuDe": "Giải mã & Tìm số",
                      "moTa": "Giải mã hình ảnh và tìm số thỏa mãn điều kiện",
                      "icon": "🎯",
                      "trangDich": const TrangGiaiMaVaTimSo(), // Tên trang tổng hợp chung của bạn
                    },
                    {
                      "tieuDe": "Kiểm tra 60 câu",
                      "moTa": "Thử sức 3 dạng bài nâng cao",
                      "icon": "🏆",
                      "trangDich": const TrangKiemTraNangCao60Cau(),
                    },
                  ],
                ),
              ],
            ),
          ),
          // Nút quay lại dạng tròn nổi góc trên bên trái
          Positioned(
            top: 12,
            left: 16,
            child: SafeArea(
              child: _nutQuayLaiTron(context),
            ),
          ),
        ],
      ),
    );
  }
  // Widget hiển thị danh sách dạng các ô nhỏ vuốt ngang
  Widget _taoMucToan(
    BuildContext context, {
    required String tieuDeMuc,
    required Color mauSac,
    required String iconMuc,
    required List<Map<String, dynamic>> danhSachBai,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: mauSac, width: 3),
        boxShadow: [
          BoxShadow(
            color: mauSac.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề mục
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: mauSac.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(21),
                topRight: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                Text(iconMuc, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tieuDeMuc,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mauSac.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dãy ô nhỏ vuốt ngang (Dạng danh sách cuộn ngang chứa các ô vuông trực quan)
          SizedBox(
            height: 155, // Chiều cao gọn gàng cho các ô nhỏ
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // Cho phép vuốt ngang
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: danhSachBai.length,
              itemBuilder: (context, index) {
                final bai = danhSachBai[index];
                return Container(
                  width: 130, // Kích thước ô nhỏ vừa vặn
                  margin: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => bai["trangDich"]),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: mauSac.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: mauSac.withOpacity(0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon tượng trưng cho bài học
                          Text(
                            bai["icon"],
                            style: const TextStyle(fontSize: 34),
                          ),
                          const SizedBox(height: 8),
                          // Tên bài học ngắn gọn
                          Text(
                            bai["tieuDe"],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  // Thiết kế nút quay lại hình tròn nổi viền vàng
  Widget _nutQuayLaiTron(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber.shade400, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.brown,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// CÁC TRANG BÀI TẬP CƠ BẢN (GỒM CẢ CŨ ĐƯỢC CHUYỂN XUỐNG)
class TrangMenuNhanBietSo extends StatelessWidget {
  const TrangMenuNhanBietSo({super.key});
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> danhSachDangBaiNhanBiet = [
      {
        "tieuDe": "Đếm số lượng hoa quả",
        "moTa": "Đếm số lượng đồ vật trực quan (🍎, 🍌, 🍊)",
        "icon": "🍎",
        "mauDiemNhan": const Color(0xFFFF6B6B), // Đỏ hồng san hô tinh tế
        "mauNenCard": const Color(0xFFFFF2F2), // Nền hồng pastel siêu nhạt
        "trangDich": const TrangDemHoaQua(),
      },
      {
        "tieuDe": "Nghe âm thanh đoán số",
        "moTa": "Lắng nghe máy đọc số và chọn đúng đáp án 🔊",
        "icon": "🔊",
        "mauDiemNhan": const Color(0xFF3B82F6), // Xanh dương hiện đại
        "mauNenCard":
            const Color(0xFFEFF6FF), // Nền xanh dương pastel siêu nhạt
        "trangDich": const TrangNgheDocSo(),
      },
      {
        "tieuDe": "Tìm số lớn nhất",
        "moTa": "Quan sát các số và chọn số có giá trị lớn nhất",
        "icon": "🦖",
        "mauDiemNhan": const Color(0xFFF59E0B), // Vàng hổ phách ấm áp
        "mauNenCard": const Color(0xFFFFFBEB), // Nền vàng pastel siêu nhạt
        "trangDich": const TrangTimSoLonNhat(),
      },
      {
        "tieuDe": "Điền số còn thiếu trong dãy",
        "moTa": "Tìm chữ số còn thiếu ở vị trí dấu hỏi chấm (?)",
        "icon": "🧩",
        "mauDiemNhan": const Color(0xFF10B981), // Xanh ngọc mượt mà
        "mauNenCard": const Color(0xFFECFDF5), // Nền xanh ngọc pastel siêu nhạt
        "trangDich": const TrangDienSoThieu(),
      },
      {
        "tieuDe": "Sắp xếp thứ tự số",
        "moTa": "Sắp xếp 3 số từ bé đến lớn hoặc lớn đến bé",
        "icon": "🔢",
        "mauDiemNhan": const Color(0xFF8B5CF6), // Tím pastel sang trọng
        "mauNenCard": const Color(0xFFF5F3FF), // Nền tím pastel siêu nhạt
        "trangDich": const TrangSapXepThuTuSo(),
      },
      {
        "tieuDe": "Kiểm Tra Tổng Hợp 50 Câu",
        "moTa": "Thử sức 5 dạng bài nếu bé đã làm tốt các phần trên",
        "icon": "🏆",
        "mauDiemNhan": const Color(0xFFEC4899), // Hồng đậm trẻ trung
        "mauNenCard": const Color(0xFFFDF2F8), // Nền hồng đậm pastel siêu nhạt
        "trangDich": const TrangKiemTraTongHop50Cau(),
      },
    ];
    return Scaffold(
      // Màu nền tổng thể kem sữa ấm áp, thân thiện với bé
      backgroundColor: const Color(0xFFFFFBF5),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 65, 20, 20),
              children: [
                // Tiêu đề trang phong cách hiện đại
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFED7AA), width: 1.2),
                      ),
                      child: const Text("🔢", style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Các Dạng Nhận Biết Số",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Dạng ô nhỏ vuốt ngang giữ nguyên kích thước chính xác của bạn
                SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics:
                        const BouncingScrollPhysics(), // Hiệu ứng kéo nảy mượt mà
                    itemCount: danhSachDangBaiNhanBiet.length,
                    itemBuilder: (context, index) {
                      final bai = danhSachDangBaiNhanBiet[index];
                      final Color mauNhan = bai["mauDiemNhan"];
                      final Color mauNenCard = bai["mauNenCard"];
                      return Container(
                        width: 135,
                        margin: const EdgeInsets.only(right: 14),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => bai["trangDich"]),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Ink(
                              decoration: BoxDecoration(
                                color:
                                    mauNenCard, // Màu nền pastel riêng biệt cho từng card
                                borderRadius: BorderRadius.circular(24),
                                // Viền màu điểm nhấn nhưng rất mờ để tạo độ tinh tế
                                border: Border.all(
                                  color: mauNhan.withOpacity(0.25),
                                  width: 1.2,
                                ),
                                // Đổ bóng mờ mịn có màu theo điểm nhấn tạo chiều sâu
                                boxShadow: [
                                  BoxShadow(
                                    color: mauNhan.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Icon nằm trong vòng tròn nổi bật
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: mauNhan.withOpacity(0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          bai["icon"],
                                          style: const TextStyle(fontSize: 26),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Tiêu đề chữ gọn gàng, thanh thoát
                                    Text(
                                      bai["tieuDe"],
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Nút quay lại bo tròn nổi tinh tế, đồng bộ với thiết kế tổng thể
          Positioned(
            top: 12,
            left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orange,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.brown,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// DẠNG 1: ĐẾM SỐ LƯỢNG HOA QUẢ
class TrangDemHoaQua extends StatefulWidget {
  const TrangDemHoaQua({super.key});
  @override
  State<TrangDemHoaQua> createState() => _TrangDemHoaQuaState();
}
class _TrangDemHoaQuaState extends State<TrangDemHoaQua>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  int soLuong = 3;
  int dapAnDung = 3;
  List<int> danhSachLuaChon = [1, 2, 3];
  String iconVatPham = "🍎";
  String cauDanDat = "Bé hãy đếm xem có bao nhiêu quả táo đỏ mọng nhé!";
  int soLanDienLienTiep = 0;
  bool dangKhoaNut = false;
  // Biến ghi nhớ con số bé làm sai để ép luyện tập liên tục
  int? soCanLuyenTap;
  int soLanDaLuyenDung = 0;
  final int soLanDuyenYeuCau = 3;
  // Biến ghi nhận số mà bé chọn đúng sau khi từng bị sai
  int? soDungSauKhiSai;
  // Controller cho hiệu ứng ngón tay trỏ chỉ từ ngoài vào
  late AnimationController _ngonTayController;
  final List<Map<String, String>> _danhSachKieuDem = [
    {"icon": "🍎", "noiDung": "Bé hãy đếm xem có bao nhiêu quả táo đỏ mọng nhé!"},
  {"icon": "🍏", "noiDung": "Những quả táo xanh giòn ngon, đếm giúp mẹ xem có mấy quả nào!"},
  {"icon": "🍌", "noiDung": "Những quả chuối thơm ngon quá, bé đếm thử xem có mấy quả nào!"},
  {"icon": "🍊", "noiDung": "Bé đếm giúp mẹ xem có bao nhiêu quả cam chín vàng nhé!"},
  {"icon": "🍋", "noiDung": "Quả chanh vàng tươi mát, bé đếm xem có tổng cộng mấy quả đây!"},
  {"icon": "🍐", "noiDung": "Những trái lê ngọt lịm, bé đếm xem có bao nhiêu trái bé ơi!"},
  {"icon": "🍑", "noiDung": "Quả đào tiên thơm phức, đếm số lượng giúp ba mẹ nhé!"},
  {"icon": "🍒", "noiDung": "Những chùm quả anh đào đỏ rực, bé đếm xem có mấy quả nhé!"},
  {"icon": "🍓", "noiDung": "Những trái dâu tây xinh xắn, đếm xem có bao nhiêu trái bé ơi!"},
  {"icon": "🍇", "noiDung": "Chùm nho ngọt lịm, bé đếm số lượng quả giúp nào!"},
  {"icon": "🍉", "noiDung": "Các miếng dưa hấu mát lạnh, bé đếm xem có mấy miếng nhé!"},
  {"icon": "🍈", "noiDung": "Quả dưa gang thơm ngon, bé đếm xem có bao nhiêu quả nào!"},
  {"icon": "🍍", "noiDung": "Bé hãy đếm số lượng quả dứa xuất hiện bên dưới nhé!"},
  {"icon": "🥝", "noiDung": "Những lát kiwi giàu vitamin, bé đếm giúp mẹ nhé!"},
  {"icon": "🥭", "noiDung": "Quả xoài chín vàng óng, đếm xem có bao nhiêu quả nào bé!"},
  {"icon": "🥥", "noiDung": "Những trái dừa tươi giải khát, bé đếm xem có mấy quả nhé!"},
  {"icon": "🍅", "noiDung": "Quả cà chua đỏ mọng, bé đếm xem có tổng cộng mấy quả đây!"},
  {"icon": "🥑", "noiDung": "Những quả bơ sáp béo ngậy, bé đếm giúp ba mẹ nhé!"},
  {"icon": "🍆", "noiDung": "Quả cà tím dài xinh xắn, đếm xem có bao nhiêu quả nào!"},
  {"icon": "🥕", "noiDung": "Những củ cà rốt giòn ngọt, bé đếm xem có mấy củ nhé!"},
  {"icon": "🍬", "noiDung": "Những viên kẹo ngọt ngào, bé đếm xem có bao nhiêu viên kẹo nhé!"},
  {"icon": "🍭", "noiDung": "Kẹo mút nhiều màu sắc quá, bé đếm xem có mấy cây kẹo mút nào!"},
  {"icon": "🍫", "noiDung": "Những thanh sô cô la thơm ngon, bé đếm giúp mẹ nhé!"},
  {"icon": "🍩", "noiDung": "Những chiếc bánh vòng donut hấp dẫn, đếm xem có mấy chiếc nào!"},
  {"icon": "🍪", "noiDung": "Bánh quy giòn rụm thơm phức, bé đếm xem có bao nhiêu cái bánh!"},
  {"icon": "🧁", "noiDung": "Những chiếc bánh cupcake kem tươi xinh xắn, đếm giúp ba mẹ nhé!"},
  {"icon": "🎂", "noiDung": "Những chiếc bánh kem sinh nhật ngọt ngào, đếm xem có mấy chiếc bánh!"},
  {"icon": "⭐", "noiDung": "Những ngôi sao lấp lánh trên trời, bé đếm xem có bao nhiêu ngôi sao!"},
  {"icon": "🎈", "noiDung": "Những quả bóng bay rực rỡ sắc màu, bé đếm xem có mấy quả bóng nhé!"},
  ];
  final List<String> _danhSachCauKhen = [
    "Bé giỏi quá, chính xác rồi!",
    "Tuyệt vời! Bé của ba mẹ siêu quá đi!",
    "Đúng chuẩn luôn! Bé thông minh thế nhỉ!",
    "Hoan hô bé! Lại đúng nữa rồi!",
    "Quá xuất sắc! Bé đếm siêu thật đấy!",
    "Siêu nhân toán học đây rồi! Quá chuẩn em bé ơi!",
    "Bé tài năng thế nhờ, đáp án chính xác tuyệt đối!",
    "Thông minh quá đi mất! Một điểm 10 cho bé!",
    "Trí nhớ và đôi mắt của bé siêu thật đấy!",
    "Không thể chê vào đâu được, chuẩn xác 100 phần trăm!",
    "Cực kỳ chính xác! Bé xứng đáng nhận một ngôi sao lớn!",
  ];
  @override
  void initState() {
    super.initState();
    _ngonTayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _khoiTaoTts();
  }
  @override
  void dispose() {
    _ngonTayController.dispose();
    flutterTts.stop();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.55);
    if (!mounted) return;
    _taoCauHoiMoi();
  }
  Future<void> _noi(String text) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(text);
  }
  void _taoCauHoiMoi() {
    if (!mounted) return;
    setState(() {
      if (soCanLuyenTap != null) {
        soLuong = soCanLuyenTap!;
      } else {
        soLuong = _random.nextInt(5) + 5;
      }
      dapAnDung = soLuong;
      final kieuNgauNhien =
          _danhSachKieuDem[_random.nextInt(_danhSachKieuDem.length)];
      iconVatPham = kieuNgauNhien["icon"]!;
      cauDanDat = kieuNgauNhien["noiDung"]!;
      Set<int> luaChon = {dapAnDung};
      while (luaChon.length < 3) {
        luaChon.add(_random.nextInt(5) + 5);
      }
      danhSachLuaChon = luaChon.toList()..shuffle();
      dangKhoaNut = false;
      soDungSauKhiSai = null;
    });
    _noi(cauDanDat);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text("Đếm Số Lượng Quả"),
        backgroundColor: const ui.Color.fromARGB(148, 64, 255, 255),
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    soCanLuyenTap != null
                        ? "🎯 Đang luyện tập mặt số $soCanLuyenTap ($soLanDaLuyenDung/$soLanDuyenYeuCau lần đúng)"
                        : "🔥 Chuỗi đúng liên tiếp: $soLanDienLienTiep",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: soCanLuyenTap != null
                            ? Colors.redAccent
                            : Colors.deepOrange),
                  ),
                  const SizedBox(height: 1),
                  IconButton(
                    iconSize: 25,
                    color: Colors.orange,
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: () => _noi(cauDanDat),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      cauDanDat,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(
                          soLuong,
                          (index) => Text(iconVatPham,
                              style: const TextStyle(fontSize: 45))),
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text("Chọn con số chính xác:",
                      style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 1),
                  // Sử dụng Stack để nút nổi bật được hiển thị đè lên trên hoàn toàn các nút khác
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hàng nút bình thường ở dưới
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: danhSachLuaChon.map((so) {
                          bool laSoNoiBat = (soDungSauKhiSai == so);
                          return Opacity(
                            // Khi có số nổi bật, làm mờ các số khác đi một chút để tập trung hoàn toàn vào số cần nhớ
                            opacity: (soDungSauKhiSai != null && !laSoNoiBat)
                                ? 0.2
                                : 1.0,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed:
                                    dangKhoaNut ? null : () => _xuLyChonSo(so),
                                child: Text("$so",
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      // Nút được phóng to cực đại, đổi màu rực rỡ đè hẳn lên trên kèm ngón tay chỉ từ ngoài vào
                      if (soDungSauKhiSai != null)
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.5, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value * 2,
                                  child: child,
                                );
                              },
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors
                                      .amber, // Màu vàng cực kỳ rực rỡ và nổi bật
                                  foregroundColor: Colors.black,
                                  elevation: 12,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 36, vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: const BorderSide(
                                        color: Colors.white,
                                        width: 4), // Viền trắng dày sắc nét
                                  ),
                                ),
                                onPressed:
                                    () {}, // Khoá tương tác trong lúc đang đọc
                                child: Text(
                                  "$soDungSauKhiSai",
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors
                                        .deepOrange, // Màu chữ đậm nổi bật trên nền vàng
                                  ),
                                ),
                              ),
                            ),
                            // Ngón tay trỏ nằm ở ngoài khung và thọc/chỉ hướng vào trong
                            Positioned(
                              left: -150,
                              child: AnimatedBuilder(
                                animation: _ngonTayController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                        10 * _ngonTayController.value, 0),
                                    child: const Text(
                                      "👉",
                                      style: TextStyle(fontSize: 40),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // Tách hàm xử lý chọn số cho code gọn gàng
  Future<void> _xuLyChonSo(int so) async {
    if (!mounted) return;
    if (so == dapAnDung) {
      // BÉ CHỌN ĐÚNG:
      bool dangLuyenTap = (soCanLuyenTap != null);
      setState(() {
        dangKhoaNut = true;
        soLanDienLienTiep++;
        if (dangLuyenTap) {
          soDungSauKhiSai =
              so; // Kích hoạt hiển thị nút phóng to rực rỡ đè lên trên
        }
      });
      if (dangLuyenTap) {
        soLanDaLuyenDung++;
        if (soLanDaLuyenDung >= soLanDuyenYeuCau) {
          soCanLuyenTap = null;
          soLanDaLuyenDung = 0;
        }
      }
      flutterTts.setCompletionHandler(() {
        flutterTts.setCompletionHandler(() {});
        if (mounted) {
          _taoCauHoiMoi();
        }
      });
      if (dangLuyenTap) {
        await _noi("Bé hãy ghi nhớ số này nhé  số : $so!");
      } else {
        String cauKhenNgauNhien =
            _danhSachCauKhen[_random.nextInt(_danhSachCauKhen.length)];
        await _noi(cauKhenNgauNhien);
      }
    } else {
      // BÉ CHỌN SAI:
      setState(() {
        soLanDienLienTiep = 0;
        soCanLuyenTap = dapAnDung;
        soLanDaLuyenDung = 0;
        soDungSauKhiSai = null;
      });
      flutterTts.setCompletionHandler(() {
        flutterTts.setCompletionHandler(() {});
      });
      await _noi(
          "Chưa đúng rồi. Bé đếm kỹ lại xem có đúng số $dapAnDung không nhé!");
    }
  }
}

// DẠNG 2: NGHE ÂM THANH ĐOÁN SỐ (CÓ CƠ CHẾ LUYỆN TẬP KHI TRẢ LỜI SAI)
class TrangNgheDocSo extends StatefulWidget {
  const TrangNgheDocSo({super.key});
  @override
  State<TrangNgheDocSo> createState() => _TrangNgheDocSoState();
}
class _TrangNgheDocSoState extends State<TrangNgheDocSo>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  int dapAnDung = 1;
  List<int> danhSachLuaChon = [1, 2, 3];
  int soLanDienLienTiep = 0;
  String cauDanDat = "";
  bool dangKhoaNut = false;
  // Biến ghi nhớ con số bé làm sai để ép luyện tập liên tục
  int? soCanLuyenTap;
  int soLanDaLuyenDung = 0;
  final int soLanDuyenYeuCau = 3;
  // Biến ghi nhận số mà bé chọn đúng sau khi từng bị sai để phóng to nổi bật
  int? soDungSauKhiSai;
  // Controller cho hiệu ứng ngón tay trỏ chỉ từ ngoài vào
  late AnimationController _ngonTayController;
  final List<String> _danhSachCauDan = [
    "Bé thám tử tài ba hãy lắng nghe thật kỹ xem âm thanh vừa phát ra là số mấy nhé!",
    "Chiếc loa kỳ diệu sắp đọc một con số bí mật, bé đoán xem đó là số mấy nào!",
    "Bé hãy căng tai nghe thật kỹ, con số nào đang ẩn giấu trong âm thanh thế nhỉ!",
    "Tai thính mắt tinh lên nào! Nghe âm thanh và tìm ra con số chính xác cho mẹ nhé!",
    "Nào các bé ngoan, chúng mình cùng lắng nghe xem âm thanh đọc vang lên số mấy đây!",
    "Bé hãy lật giở trang sách thính giác và chọn ngay số vừa được đọc lên nhé!",
    "Âm thanh vui nhộn đã vang lên rồi, bé thông minh chọn số tương ứng nào!",
    "Thử tài đôi tai siêu nhân của bé nhé! Nghe kỹ xem đó là số mấy nào!",
    "Loa phát thanh nhỏ nhắn đang gọi tên một con số, bé tìm giúp xem là số mấy nhé!",
    "Lắng nghe giai điệu của các con số, bé chọn ngay đáp án đúng nhất cho ba mẹ nha!",
    "Đố bé biết! Loa đang đọc to rõ con số nào thế nhé? Chọn nhanh kẻo lỡ nào!",
    "Bé hãy lắng đọng tâm hồn, nghe thật kỹ âm thanh vang lên và bấm chọn số nha!",
    "Chuẩn bị tinh thần thép chưa nào? Nghe loa đọc số và chiến đấu thôi bé ơi!",
    "Một, hai, ba, cùng nghe loa bật mí xem số mấy đang trốn ở đây nhé!"
  ];
  final List<String> _danhSachCauKhen = [
    "Bé giỏi quá, chính xác rồi!",
    "Tuyệt vời! Bé của ba mẹ siêu quá đi!",
    "Đúng chuẩn luôn! Bé thông minh thế nhỉ!",
    "Hoan hô bé! Lại đúng nữa rồi!",
    "Quá xuất sắc! Bé nghe siêu thật đấy!",
    "Siêu nhân thính giác đây rồi! Quá chuẩn em bé ơi!",
    "Bé tài năng thế nhờ, đáp án chính xác tuyệt đối!",
    "Thông minh quá đi mất! Một điểm 10 cho bé!",
    "Đôi tai thính nhạy quá! Chúc mừng bé!",
    "Không thể chê vào đâu được, chuẩn xác 100 phần trăm!"
  ];
  @override
  void initState() {
    super.initState();
    _ngonTayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _khoiTaoTts();
  }
  @override
  void dispose() {
    _ngonTayController.dispose();
    flutterTts.stop();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.45);
    if (!mounted) return;
    _taoCauHoiMoi();
  }
  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }
  void _taoCauHoiMoi() {
    if (!mounted) return;
    setState(() {
      if (soCanLuyenTap != null) {
        dapAnDung = soCanLuyenTap!;
      } else {
        dapAnDung = _random.nextInt(5) + 5;
      }
      cauDanDat = _danhSachCauDan[_random.nextInt(_danhSachCauDan.length)];
      Set<int> luaChon = {dapAnDung};
      while (luaChon.length < 3) {
        luaChon.add(_random.nextInt(5) + 5);
      }
      danhSachLuaChon = luaChon.toList()..shuffle();
      dangKhoaNut = false;
      soDungSauKhiSai = null; // Reset trạng thái nút phóng to
    });
    _noi("$cauDanDat. Số đó là: $dapAnDung");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const ui.Color.fromARGB(248, 240, 255, 250),
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text("Nghe Âm Thanh Đoán Số",
            style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        backgroundColor: const ui.Color.fromARGB(148, 64, 255, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              soCanLuyenTap != null
                  ? "🎯 Đang luyện tập nghe số $soCanLuyenTap ($soLanDaLuyenDung/$soLanDuyenYeuCau lần đúng)"
                  : "🔥 Chuỗi đúng liên tiếp: $soLanDienLienTiep",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: soCanLuyenTap != null
                      ? Colors.redAccent
                      : Colors.deepOrange),
            ),
            const SizedBox(height: 0),
            const Text(
              "Bé hãy nghe kỹ âm thanh phát ra nhé 🔊",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 0),
            // Nút bấm nghe lại số thủ công
            IconButton(
              iconSize: 50,
              color: Colors.orange,
              icon: const Icon(Icons.volume_up_rounded),
              onPressed: () => _noi("Số cần tìm là: $dapAnDung"),
            ),
            const SizedBox(height: 0),
            const Text("Chọn con số chính xác:",
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 20),
            // Sử dụng Stack để chứa hàng nút bình thường và nút phóng to đè lên trên khi đúng lúc luyện tập
            Stack(
              alignment: Alignment.center,
              children: [
                // Hàng nút bình thường ở dưới
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: danhSachLuaChon.map((so) {
                    bool laSoNoiBat = (soDungSauKhiSai == so);
                    return Opacity(
                      opacity: (soDungSauKhiSai != null && !laSoNoiBat) ? 0.2 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: dangKhoaNut ? null : () => _xuLyChonSo(so),
                          child: Text("$so",
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Nút được phóng to cực đại, đổi màu rực rỡ đè hẳn lên trên kèm ngón tay chỉ từ ngoài vào khi chọn đúng lúc luyện tập
                if (soDungSauKhiSai != null)
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.5, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value * 2,
                            child: child,
                          );
                        },
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber, // Màu vàng rực rỡ
                            foregroundColor: Colors.black,
                            elevation: 12,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 36, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(
                                  color: Colors.white, width: 4), // Viền trắng dày sắc nét
                            ),
                          ),
                          onPressed: () {}, // Khoá tương tác trong lúc đọc
                          child: Text(
                            "$soDungSauKhiSai",
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ),
                      // Ngón tay trỏ nằm ở ngoài khung và thọc/chỉ hướng vào trong
                      Positioned(
                        left: -150,
                        child: AnimatedBuilder(
                          animation: _ngonTayController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(10 * _ngonTayController.value, 0),
                              child: const Text(
                                "👉",
                                style: TextStyle(fontSize: 40),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // Tách hàm xử lý chọn số cho gọn gàng và chuẩn xác logic
  Future<void> _xuLyChonSo(int so) async {
    if (!mounted) return;
    if (so == dapAnDung) {
      // BÉ CHỌN ĐÚNG:
      bool dangLuyenTap = (soCanLuyenTap != null);
      setState(() {
        dangKhoaNut = true;
        soLanDienLienTiep++;
        if (dangLuyenTap) {
          soDungSauKhiSai = so; // Kích hoạt hiệu ứng phóng to rực rỡ đè lên trên
        }
      });
      if (dangLuyenTap) {
        soLanDaLuyenDung++;
        if (soLanDaLuyenDung >= soLanDuyenYeuCau) {
          soCanLuyenTap = null;
          soLanDaLuyenDung = 0;
        }
      }
      flutterTts.setCompletionHandler(() {
        flutterTts.setCompletionHandler(() {});
        if (mounted) {
          _taoCauHoiMoi();
        }
      });
      if (dangLuyenTap) {
        await _noi("Bé hãy ghi nhớ số này nhé, số: $so!");
      } else {
        String cauKhenNgauNhien =
            _danhSachCauKhen[_random.nextInt(_danhSachCauKhen.length)];
        await _noi(cauKhenNgauNhien);
      }
    } else {
      // BÉ CHỌN SAI:
      setState(() {
        soLanDienLienTiep = 0;
        soCanLuyenTap = dapAnDung; // Kích hoạt ngay chế độ ép luyện tập số đúng
        soLanDaLuyenDung = 0;
        soDungSauKhiSai = null;
        dangKhoaNut = true;
      });
      flutterTts.setCompletionHandler(() {
        flutterTts.setCompletionHandler(() {});
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            flutterTts.setCompletionHandler(() {
              flutterTts.setCompletionHandler(() {});
              if (mounted) {
                setState(() {
                  dangKhoaNut = false;
                });
              }
            });
            _noi("Số cần tìm là: $dapAnDung");
          });
        }
      });
      await _noi("Chưa đúng rồi. Bé nghe lại nhé!");
    }
  }
}

// DẠNG 3: TÌM SỐ LỚN NHẤT (CÓ CƠ CHẾ LUYỆN TẬP KHI TRẢ LỜI SAI)
class TrangTimSoLonNhat extends StatefulWidget {
  const TrangTimSoLonNhat({super.key});
  @override
  State<TrangTimSoLonNhat> createState() => _TrangTimSoLonNhatState();
}class _TrangTimSoLonNhatState extends State<TrangTimSoLonNhat> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late ConfettiController _confettiController;
  List<int> danhSachSo = [3, 7, 5];
  int dapAnDung = 7;
  int soLanDienLienTiep = 0;
  String cauDanDat = "";
  bool dangKhoaNut = false;
  // Biến ghi nhớ bộ số hoặc đáp án đúng cần luyện tập khi bé trả lời sai
  List<int>? danhSachCanLuyenTap;
  int? dapAnCanLuyenTap;
  // Biến đếm số lần bé đã bấm đúng liên tiếp cho phần luyện tập này
  int soLanDaLuyenDung = 0;
  final int soLanDuyenYeuCau =
      3; // Số lần đúng liên tiếp để vượt qua bài tập này
  final List<String> _danhSachCauDan = [
    "Bé thám tử tài ba hãy nhìn các số bên dưới và tìm xem số nào có giá trị lớn nhất nhé!",
    "Trong ba con số xuất hiện, số nào to nhất và có giá trị lớn nhất vậy bé nhỉ?",
    "Đâu là con số lớn nhất trong các số này? Bé hãy so sánh và bấm chọn nhanh hộ ba mẹ nha!",
    "Thử tài đôi mắt tinh anh của bé: Nhìn kỹ các số và tìm ngay số bự nhất nhé!",
    "Nào các bé ngoan, chúng mình cùng so sánh các con số để tìm ra số lớn nhất nào!",
    "Số nào to nhất, bự nhất trong các số này nhỉ? Bé chọn ngay đi nào!",
    "Bé hãy so sánh thật kỹ các con số rồi bấm vào số lớn nhất giúp mẹ nha!",
    "Thử thách so sánh mới cho bé đây: Số nào là số lớn nhất trong đám thế nhỉ?"
  ];
  final List<String> _danhSachCauKhen = [
    "Bé giỏi quá! Số này đứng sau cùng và có giá trị lớn nhất trong dãy số đấy!",
    "Tuyệt vời! Con số này to hơn hẳn các số còn lại, bé tìm quá chuẩn rồi!",
    "Đúng chuẩn luôn! Bé thông minh thế nhỉ, nhìn phát biết ngay số lớn nhất!",
    "Hoan hô bé! Lại đúng nữa rồi! Số này bự nhất nhà luôn đấy!",
    "Quá xuất sắc! Bé tìm số lớn nhất siêu thật đấy!",
    "Siêu nhân toán học đây rồi! Bé biết so sánh số nào lớn hơn cơ đấy!",
    "Bé tài năng thế nhờ! Số này đứng ở vị trí cao nhất nên lớn nhất bé nhé!",
    "Thông minh quá đi mất! Một điểm 10 cho đôi mắt tinh anh của bé!",
    "Đôi mắt tinh quá đi! Bé nhận ra ngay số to nhất trong đám luôn!",
    "Không thể chê vào đâu được! Số này có giá trị lớn nhất, chuẩn xác 100 phần trăm!"
  ];
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _khoiTaoTts();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.48);
    if (!mounted) return;
    _taoCauHoiMoi();
  }

  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }

  void _taoCauHoiMoi() {
    if (!mounted) return;
    setState(() {
      // NẾU ĐANG TRONG CHẾ ĐỘ LUYỆN TẬP: Cố định lại đúng bộ số cũ để bé làm lại
      if (danhSachCanLuyenTap != null) {
        danhSachSo = List.from(danhSachCanLuyenTap!);
      } else {
        Set<int> baSo = {};
        while (baSo.length < 3) {
          baSo.add(_random.nextInt(10) + 1);
        }
        danhSachSo = baSo.toList();
      }
      dapAnDung = danhSachSo.reduce(max);
      cauDanDat = _danhSachCauDan[_random.nextInt(_danhSachCauDan.length)];
      dangKhoaNut = false;
    });
    String docCacSo = danhSachSo.join(", ");
    _noi("$cauDanDat. Các số là: $docCacSo");
  }

  @override
  Widget build(BuildContext context) {
    String docCacSo = danhSachSo.join(", ");
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text("Tìm Số Lớn Nhất"),
        backgroundColor: const ui.Color.fromARGB(169, 64, 255, 245),
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  danhSachCanLuyenTap != null
                      ? "🎯 Đang luyện tập so sánh ($soLanDaLuyenDung/$soLanDuyenYeuCau lần đúng)"
                      : "🔥 Chuỗi đúng liên tiếp: $soLanDienLienTiep",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: danhSachCanLuyenTap != null
                          ? Colors.redAccent
                          : Colors.deepOrange),
                ),
                const SizedBox(height: 15),
                // Nút bấm phát lại đề bài khi bé muốn nghe lại
                IconButton(
                  iconSize: 50,
                  color: Colors.orange,
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: () =>
                      _noi("Bé hãy tìm số lớn nhất trong các số: $docCacSo"),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    cauDanDat,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown),
                  ),
                ),
                const SizedBox(height: 20),
                // Hiển thị các nút số cho bé chọn
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: danhSachSo.map((so) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: dangKhoaNut
                            ? null
                            : () async {
                                if (!mounted) return;
                                if (so == dapAnDung) {
                                  // BÉ CHỌN ĐÚNG:
                                  setState(() {
                                    dangKhoaNut = true;
                                    soLanDienLienTiep++;
                                  });
                                  // Nếu đang luyện tập bài bị sai, tăng tiến độ luyện đúng
                                  if (danhSachCanLuyenTap != null) {
                                    soLanDaLuyenDung++;
                                    // Nếu đã đúng đủ số lần yêu cầu -> Giải phóng, quay về ngẫu nhiên hoàn toàn
                                    if (soLanDaLuyenDung >= soLanDuyenYeuCau) {
                                      danhSachCanLuyenTap = null;
                                      soLanDaLuyenDung = 0;
                                    }
                                  }
                                  // Kích hoạt pháo hoa khi đạt bội số của 5 lần đúng liên tiếp
                                  if (soLanDienLienTiep % 5 == 0) {
                                    _confettiController.play();
                                  }
                                  String cauKhenNgauNhien = _danhSachCauKhen[
                                      _random.nextInt(_danhSachCauKhen.length)];
                                  flutterTts.setCompletionHandler(() {
                                    flutterTts.setCompletionHandler(() {});
                                    if (mounted) {
                                      _taoCauHoiMoi();
                                    }
                                  });
                                  await _noi(cauKhenNgauNhien);
                                } else {
                                  // BÉ CHỌN SAI:
                                  setState(() {
                                    soLanDienLienTiep = 0;
                                    dangKhoaNut = true;
                                    // Ghi nhớ lại bộ số hiện tại để bắt bé làm lại liên tục cho đến khi thuộc
                                    danhSachCanLuyenTap = List.from(danhSachSo);
                                    soLanDaLuyenDung =
                                        0; // Reset lại tiến độ từ đầu
                                  });
                                  flutterTts.setCompletionHandler(() {
                                    flutterTts.setCompletionHandler(() {});
                                    if (mounted) {
                                      Future.delayed(
                                          const Duration(milliseconds: 300),
                                          () {
                                        if (!mounted) return;
                                        flutterTts.setCompletionHandler(() {
                                          flutterTts
                                              .setCompletionHandler(() {});
                                          if (mounted) {
                                            setState(() {
                                              dangKhoaNut = false;
                                            });
                                          }
                                        });
                                        _noi(
                                            "Các số là: $docCacSo. Bé tìm lại số lớn nhất nhé!");
                                      });
                                    }
                                  });
                                  await _noi(
                                      "Chưa đúng rồi. Bé nghe lại các số nhé!");
                                }
                              },
                        child: Text("$so",
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // WIDGET PHÁO HOA ĐẶT Ở LỚP TRÊN CÙNG (STACK)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Pháo hoa bắn hướng xuống dưới
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// DẠNG 4: ĐIỀN SỐ CÒN THIẾU TRONG DÃY (CÓ CƠ CHẾ LUYỆN TẬP KHI TRẢ LỜI SAI)
class TrangDienSoThieu extends StatefulWidget {
  const TrangDienSoThieu({super.key});
  @override
  State<TrangDienSoThieu> createState() => _TrangDienSoThieuState();
}
class _TrangDienSoThieuState extends State<TrangDienSoThieu> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late ConfettiController _confettiController;
  List<int> daySoDayDu = [1, 2, 3];
  int viTriAn = 1;
  int dapAnDung = 2;
  List<int> danhSachLuaChon = [1, 2, 3];
  int soLanDienLienTiep = 0;
  String cauDanDat = "";
  bool dangKhoaNut = false;
  // Biến ghi nhớ trạng thái câu hỏi bị sai để ép luyện tập liên tục
  List<int>? daySoCanLuyenTap;
  int? viTriAnCanLuyenTap;
  // Biến đếm số lần bé đã bấm đúng liên tiếp cho câu hỏi cần luyện tập này
  int soLanDaLuyenDung = 0;
  final int soLanDuyenYeuCau =
      3; // Số lần đúng liên tiếp để vượt qua bài tập này
  final List<String> _danhSachCauDan = [
    "Bé hãy quan sát dãy số liên tiếp và điền số còn thiếu vào chỗ có dấu hỏi chấm nhé!",
    "Số nào đang trốn ở ô có dấu hỏi thế nhỉ? Bé hãy tìm số thích hợp điền vào nào!",
    "Dãy số tăng dần đang thiếu một con số ở giữa, bé thông minh tìm giúp ba mẹ nhé!",
    "Thử tài thám tử nhí: Đâu là con số đúng để điền vào chỗ trống của dãy số này nào!",
    "Nào các bé ngoan, chúng mình cùng suy luận xem số nào đứng ở ô dấu hỏi nhé!",
    "Hãy xem các số đứng trước và sau để tìm ra con số còn thiếu chính xác nhất nhé bé ơi!"
  ];
  final List<String> _danhSachCauKhen = [
    "Bé giỏi quá! Số này nằm ở giữa đúng thứ tự trong dãy số liên tiếp đấy!",
    "Tuyệt vời! Bé điền quá chuẩn, dãy số đã trở nên hoàn chỉnh rồi!",
    "Đúng chuẩn luôn! Bé thông minh thế nhỉ, nhìn quy luật dãy số phát ra ngay đáp án!",
    "Hoan hô bé! Lại đúng nữa rồi! Số này nối tiếp rất chính xác vào chỗ trống!",
    "Quá xuất sắc! Bé tìm số còn thiếu siêu thật đấy!",
    "Siêu nhân toán học đây rồi! Bé biết quy luật đếm số liền kề cơ đấy!",
    "Bé tài năng thế nhờ, điền số chính xác tuyệt đối vào ô trống luôn!",
    "Thông minh quá đi mất! Một điểm 10 cho tư duy dãy số của bé!"
  ];
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _khoiTaoTts();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.45);
    if (!mounted) return;
    _taoCauHoiMoi();
  }

  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }

  void _taoCauHoiMoi() {
    if (!mounted) return;
    setState(() {
      // NẾU ĐANG TRONG CHẾ ĐỘ LUYỆN TẬP: Cố định lại đúng dãy số và vị trí ẩn cũ để bé làm lại
      if (daySoCanLuyenTap != null && viTriAnCanLuyenTap != null) {
        daySoDayDu = List.from(daySoCanLuyenTap!);
        viTriAn = viTriAnCanLuyenTap!;
      } else {
        int batDau = _random.nextInt(10) + 1;
        daySoDayDu = [batDau, batDau + 1, batDau + 2];
        viTriAn = _random
            .nextInt(3); // Giới hạn từ 0 đến 2 tương ứng 3 vị trí trong mảng
      }
      dapAnDung = daySoDayDu[viTriAn];
      Set<int> luaChon = {dapAnDung};
      while (luaChon.length < 4) {
        luaChon.add(_random.nextInt(10) + 1);
      }
      danhSachLuaChon = luaChon.toList()..shuffle();
      cauDanDat = _danhSachCauDan[_random.nextInt(_danhSachCauDan.length)];
      dangKhoaNut = false;
    });
    String moTaDaySo = "";
    for (int i = 0; i < 3; i++) {
      if (i == viTriAn) {
        moTaDaySo += " ô trống,";
      } else {
        moTaDaySo += " số ${daySoDayDu[i]},";
      }
    }
    _noi("$cauDanDat. Dãy số là:$moTaDaySo bé chọn số điền vào chỗ trống nhé!");
  }

  @override
  Widget build(BuildContext context) {
    String moTaDaySoChiTiet = "";
    for (int i = 0; i < 3; i++) {
      if (i == viTriAn) {
        moTaDaySoChiTiet += " dấu hỏi,";
      } else {
        moTaDaySoChiTiet += " ${daySoDayDu[i]},";
      }
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text("Điền Số Còn Thiếu"),
        backgroundColor: const ui.Color.fromARGB(167, 64, 249, 255),
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  daySoCanLuyenTap != null
                      ? "🎯 Đang luyện tập điền số ($soLanDaLuyenDung/$soLanDuyenYeuCau lần đúng)"
                      : "🔥 Chuỗi đúng liên tiếp: $soLanDienLienTiep",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: daySoCanLuyenTap != null
                          ? Colors.redAccent
                          : Colors.deepOrange),
                ),
                const SizedBox(height: 1),
                // Nút bấm phát lại đề bài thủ công khi bé muốn nghe lại
                IconButton(
                  iconSize: 25,
                  color: Colors.orange,
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: () => _noi(
                      "Dãy số gồm có:$moTaDaySoChiTiet bé điền số còn thiếu nhé!"),
                ),
                const SizedBox(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    cauDanDat,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown),
                  ),
                ),
                const SizedBox(height: 1),
                // Hiển thị dãy số có ô chứa dấu hỏi chấm (?)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    bool laViTriAn = (index == viTriAn);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color:
                            laViTriAn ? Colors.orange.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Text(
                        laViTriAn ? "?" : "${daySoDayDu[index]}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: laViTriAn ? Colors.red : Colors.orange,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 25),
                // Các nút lựa chọn đáp án cho bé bấm
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: danhSachLuaChon.map((so) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: dangKhoaNut
                            ? null
                            : () async {
                                if (!mounted) return;
                                if (so == dapAnDung) {
                                  // BÉ CHỌN ĐÚNG:
                                  setState(() {
                                    dangKhoaNut = true;
                                    soLanDienLienTiep++;
                                  });
                                  // Nếu đang trong chế độ luyện tập, tăng tiến độ đúng
                                  if (daySoCanLuyenTap != null) {
                                    soLanDaLuyenDung++;
                                    // Nếu đã trả lời đúng đủ số lần yêu cầu -> Giải phóng, quay về ngẫu nhiên
                                    if (soLanDaLuyenDung >= soLanDuyenYeuCau) {
                                      daySoCanLuyenTap = null;
                                      viTriAnCanLuyenTap = null;
                                      soLanDaLuyenDung = 0;
                                    }
                                  }
                                  // Kích hoạt pháo hoa khi đạt bội số của 5 lần đúng liên tiếp
                                  if (soLanDienLienTiep % 5 == 0) {
                                    _confettiController.play();
                                  }
                                  String cauKhenNgauNhien = _danhSachCauKhen[
                                      _random.nextInt(_danhSachCauKhen.length)];
                                  flutterTts.setCompletionHandler(() {
                                    flutterTts.setCompletionHandler(() {});
                                    if (mounted) {
                                      _taoCauHoiMoi();
                                    }
                                  });
                                  await _noi(cauKhenNgauNhien);
                                } else {
                                  // BÉ CHỌN SAI:
                                  setState(() {
                                    soLanDienLienTiep = 0;
                                    dangKhoaNut = true;
                                    // Ghi nhớ lại dãy số và vị trí ẩn hiện tại để bắt bé làm lại liên tục
                                    daySoCanLuyenTap = List.from(daySoDayDu);
                                    viTriAnCanLuyenTap = viTriAn;
                                    soLanDaLuyenDung =
                                        0; // Reset lại tiến độ từ đầu
                                  });
                                  flutterTts.setCompletionHandler(() {
                                    flutterTts.setCompletionHandler(() {});
                                    if (mounted) {
                                      Future.delayed(
                                          const Duration(milliseconds: 300),
                                          () {
                                        if (!mounted) return;
                                        flutterTts.setCompletionHandler(() {
                                          flutterTts
                                              .setCompletionHandler(() {});
                                          if (mounted) {
                                            setState(() {
                                              dangKhoaNut = false;
                                            });
                                          }
                                        });
                                        _noi(
                                            "Dãy số là:$moTaDaySoChiTiet bé thử lại nhé!");
                                      });
                                    }
                                  });
                                  await _noi(
                                      "Chưa đúng rồi. Bé nghe lại dãy số nhé!");
                                }
                              },
                        child: Text("$so",
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // WIDGET PHÁO HOA ĂN MỪNG ĐẶT Ở LỚP TRÊN CÙNG
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Bắn hướng xuống dưới
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// DẠNG 5: SẮP XẾP THỨ TỰ CÁC SỐ (CƠ CHẾ KÉO THẢ TRỰC QUAN)
class TrangSapXepThuTuSo extends StatefulWidget {
  const TrangSapXepThuTuSo({super.key});
  @override
  State<TrangSapXepThuTuSo> createState() => _TrangSapXepThuTuSoState();
}
class _TrangSapXepThuTuSoState extends State<TrangSapXepThuTuSo> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late ConfettiController _confettiController;
  List<int> danhSachGoc = [2, 5, 1];
  // 3 ô trống ở trên để bé thả số vào (ban đầu có thể mang giá trị null hoặc chứa số)
  List<int?> danhSachOTrong = [null, null, null];
  // Danh sách các số nguồn ở dưới để bé kéo lên
  List<int> danhSachSoNguon = [];
  bool laChieuTangDan = true; // true: Bé đến lớn, false: Lớn đến bé
  int soLanDienLienTiep = 0;
  String cauDanDat = "";
  bool dangKhoaNut = false;
  // Biến ghi nhớ trạng thái câu hỏi khi bé trả lời sai để luyện tập liên tục
  List<int>? danhSachCanLuyenTap;
  bool? chieuTangDanCanLuyenTap;
  int soLanDaLuyenDung = 0;
  final int soLanDuyenYeuCau = 3;
  final List<String> _danhSachCauKhen = [
    "Bé giỏi quá! Sắp xếp thứ tự các số cực kỳ chính xác!",
    "Tuyệt vời! Tư duy sắp xếp của bé siêu thật đấy!",
    "Đúng chuẩn luôn! Các con số đã đứng đúng hàng lối rồi!",
    "Hoan hô bé! Lại đúng nữa rồi! Bé của ba mẹ thông minh thế!",
    "Quá xuất sắc! Nhìn phát biết ngay thứ tự lớn nhỏ luôn!",
    "Siêu nhân toán học đây rồi! Xếp số chuẩn không cần chỉnh!",
  ];
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _khoiTaoTts();
  }
  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.45);
    if (!mounted) return;
    _taoCauHoiMoi();
  }
  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }
  void _taoCauHoiMoi() {
    if (!mounted) return;
    setState(() {
      if (danhSachCanLuyenTap != null && chieuTangDanCanLuyenTap != null) {
        danhSachGoc = List.from(danhSachCanLuyenTap!);
        laChieuTangDan = chieuTangDanCanLuyenTap!;
      } else {
        Set<int> baSo = {};
        while (baSo.length < 3) {
          baSo.add(_random.nextInt(9) + 1); // Phạm vi dưới 10 (1 -> 9)
        }
        danhSachGoc = baSo.toList();
        laChieuTangDan = _random.nextBool();
      }
      // Khởi tạo 3 ô trống ban đầu là trống (null)
      danhSachOTrong = [null, null, null];
      // Khởi tạo danh sách nguồn gồm 3 số đã xáo trộn để bé kéo
      danhSachSoNguon = List.from(danhSachGoc)..shuffle(_random);
      // Đảm bảo danh sách nguồn không vô tình đúng thứ tự ngay từ đầu
      while (_laDungThuTuBanDau()) {
        danhSachSoNguon.shuffle(_random);
      }
      cauDanDat = laChieuTangDan
          ? "Bé hãy kéo các số thả vào ô trống theo thứ tự từ bé đến lớn nhé!"
          : "Bé hãy kéo các số thả vào ô trống theo thứ tự từ lớn đến bé nhé!";
      dangKhoaNut = false;
    });
    _noi("$cauDanDat Các số cho trước là: ${danhSachSoNguon.join(", ")}.");
  }
  bool _laDungThuTuBanDau() {
    List<int> dapAnChuan = List.from(danhSachGoc);
    if (laChieuTangDan) {
      dapAnChuan.sort();
    } else {
      dapAnChuan.sort((a, b) => b.compareTo(a));
    }
    return danhSachSoNguon
        .asMap()
        .entries
        .every((e) => e.value == dapAnChuan[e.key]);
  }
  void _kiemTraKetQuaHoanChinh() {
    // Kiểm tra xem bé đã điền đủ cả 3 ô chưa
    if (danhSachOTrong.contains(null)) return;
    List<int> dapAnChuan = List.from(danhSachGoc);
    if (laChieuTangDan) {
      dapAnChuan.sort();
    } else {
      dapAnChuan.sort((a, b) => b.compareTo(a));
    }
    bool laChinhXac = true;
    for (int i = 0; i < 3; i++) {
      if (danhSachOTrong[i] != dapAnChuan[i]) {
        laChinhXac = false;
        break;
      }
    }
    if (laChinhXac) {
      // BÉ SẮP XẾP ĐÚNG
      setState(() {
        dangKhoaNut = true;
        soLanDienLienTiep++;
      });
      if (danhSachCanLuyenTap != null) {
        soLanDaLuyenDung++;
        if (soLanDaLuyenDung >= soLanDuyenYeuCau) {
          danhSachCanLuyenTap = null;
          chieuTangDanCanLuyenTap = null;
          soLanDaLuyenDung = 0;
        }
      }
      if (soLanDienLienTiep % 5 == 0) {
        _confettiController.play();
      }
      String cauKhenNgauNhien =
          _danhSachCauKhen[_random.nextInt(_danhSachCauKhen.length)];
      flutterTts.setCompletionHandler(() {
        flutterTts.setCompletionHandler(() {});
        if (mounted) _taoCauHoiMoi();
      });
      _noi(cauKhenNgauNhien);
    } else {
      // BÉ SẮP XẾP SAI
      setState(() {
        soLanDienLienTiep = 0;
        dangKhoaNut = true;
        danhSachCanLuyenTap = List.from(danhSachGoc);
        chieuTangDanCanLuyenTap = laChieuTangDan;
        soLanDaLuyenDung = 0;
      });
      flutterTts.setCompletionHandler(() {
        flutterTts.setCompletionHandler(() {});
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            setState(() {
              // Trả lại số về chỗ cũ hoặc làm mới lại bảng kéo thả
              danhSachOTrong = [null, null, null];
              danhSachSoNguon = List.from(danhSachGoc)..shuffle(_random);
              dangKhoaNut = false;
            });
            _noi("Chưa đúng rồi. Bé kéo thả lại nhé!");
          });
        }
      });
      _noi("Chưa chính xác lắm. Bé thử lại nhé!");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text("Sắp Xếp Thứ Tự Số"),
        backgroundColor: const ui.Color.fromARGB(157, 64, 255, 239),
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  danhSachCanLuyenTap != null
                      ? "🎯 Đang luyện tập sắp xếp ($soLanDaLuyenDung/$soLanDuyenYeuCau lần đúng)"
                      : "🔥 Chuỗi đúng liên tiếp: $soLanDienLienTiep",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: danhSachCanLuyenTap != null
                          ? Colors.redAccent
                          : Colors.deepOrange),
                ),
                const SizedBox(height: 0),
                IconButton(
                  iconSize: 40,
                  color: Colors.orange,
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: () => _noi(cauDanDat),
                ),
                const SizedBox(height: 0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    cauDanDat,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown),
                  ),
                ),
                const SizedBox(height: 0),
                const Text("👉 Kéo số thả vào 3 ô trống bên dưới:",
                    style: TextStyle(fontSize: 0, color: Colors.black54)),
                const SizedBox(height: 0),
                // 1. KHU VỰC 3 Ô TRỐNG ĐỂ THẢ SỐ VÀO (TARGET)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DragTarget<int>(
                        onAcceptWithDetails: (details) {
                          setState(() {
                            // Nếu ô đã có số, trả số cũ về danh sách nguồn
                            if (danhSachOTrong[index] != null) {
                              danhSachSoNguon.add(danhSachOTrong[index]!);
                            }
                            // Đặt số mới vào ô
                            danhSachOTrong[index] = details.data;
                            // Xóa số đó khỏi danh sách nguồn ở dưới
                            danhSachSoNguon.remove(details.data);
                          });
                          // Kiểm tra kết quả ngay sau khi thả
                          _kiemTraKetQuaHoanChinh();
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: danhSachOTrong[index] != null
                                  ? Colors.orange.shade100
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: Colors.orange, width: 2),
                            ),
                            child: danhSachOTrong[index] != null
                                ? Text(
                                    "${danhSachOTrong[index]}",
                                    style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange),
                                  )
                                : const Text("?",
                                    style: TextStyle(
                                        fontSize: 24, color: Colors.grey)),
                          );
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 0),
                // 2. KHU VỰC CÁC CỤC SỐ CÓ THỂ KÉO ĐI (DRAGGABLE)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: danhSachSoNguon.map((so) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Draggable<int>(
                        data: so,
                        // Hình ảnh hiển thị khi bé đang kéo ngón tay đi
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text("$so",
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                        // Giao diện của ô số khi đang bị kéo đi (làm mờ đi)
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text("$so",
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                        child: Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Text("$so",
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 0),
                // Nút làm lại nhanh nếu bé muốn reset
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent),
                  onPressed: () {
                    setState(() {
                      danhSachOTrong = [null, null, null];
                      danhSachSoNguon = List.from(danhSachGoc)
                        ..shuffle(_random);
                    });
                    _noi("Đã làm lại, bé kéo thả các số vào ô trống nhé!");
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text("Làm lại từ đầu",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// MỤC KIỂM TRA & CHẤM ĐIỂM TỔNG HỢP 50 CÂU (5 DẠNG BÀI)
class TrangKiemTraTongHop50Cau extends StatefulWidget {
  const TrangKiemTraTongHop50Cau({super.key});
  @override
  State<TrangKiemTraTongHop50Cau> createState() =>
      _TrangKiemTraTongHop50CauState();
}
class _TrangKiemTraTongHop50CauState extends State<TrangKiemTraTongHop50Cau> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late ConfettiController _confettiController;
  // Quản lý các dạng bài (5 dạng, mỗi dạng 10 câu = 50 câu)
  final List<String> danhSachCacDangBai = [
    "dem_hoa_qua",
    "nghe_am_thanh",
    "tim_so_lon",
    "dien_so_thieu",
    "sap_xep_so"
  ];
  int chiSoDangBaiHienTai = 0;
  int cauSoTrongDang = 0; // Từ 0 đến 9 (10 câu mỗi dạng)
  int tongSoCauDaLam = 0;
  final int tongSoCauHoi = 50;
  int soCauDung = 0;
  int soCauSai = 0;
  bool daHoanThanhBaiKiemTra = false;
  bool dangKhoaNut = false;
  // Lưu lịch sử các câu trả lời sai để tổng kết cuối bài trừ điểm
  final List<Map<String, dynamic>> danhSachCauSaiChiTiet = [];
  // Dữ liệu hiển thị cho câu hỏi hiện tại
  String tieuDeDangBai = ""; // Đã sửa lỗi chính tả ở đây
  String noiDungCauHoi = "";
  String iconTraiCayHienTai = "🍎"; // Biến lưu icon đang hiển thị
  List<int> danhSachLuaChon = [];
  int dapAnDungSo = 0;
  // Biến riêng cho dạng Sắp xếp số (kéo thả)
  List<int> danhSachGocSapXep = [];
  List<int?> danhSachOTrong = [null, null, null];
  List<int> danhSachSoNguon = [];
  bool laChieuTangDan = true;
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _khoiTaoTts();
  }
  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.52);
    if (!mounted) return;
    _taoCauHoiMoi();
  }
  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }
  void _taoCauHoiMoi() {
    if (chiSoDangBaiHienTai >= danhSachCacDangBai.length) {
      setState(() {
        daHoanThanhBaiKiemTra = true;
        dangKhoaNut = true;
      });
      if (soCauDung >= 40) {
        _confettiController.play();
        _noi(
            "Xuất sắc quá! Bé đã vượt qua toàn bộ 50 câu hỏi với điểm số cực kỳ cao!");
      } else {
        _noi(
            "Bé đã hoàn thành 50 câu hỏi. Cùng xem lại kết quả và điểm số nhé!");
      }
      return;
    }
    String dangHienTai = danhSachCacDangBai[chiSoDangBaiHienTai];
    // 5 câu đầu (cauSoTrongDang < 5): 3 lựa chọn (Độ khó 1)
    // 5 câu sau (cauSoTrongDang >= 5): 4 lựa chọn (Độ khó 2 - Tăng dần)
    int soLuongLuaChon = (cauSoTrongDang < 5) ? 3 : 4;
    setState(() {
      dangKhoaNut = false;
      if (dangHienTai == "dem_hoa_qua") {
        // Danh sách các loại trái cây và biểu tượng để thay đổi liên tục
        List<Map<String, String>> danhSachLoaiTraiCay = [
          {"ten": "quả táo", "icon": "🍎"},
          {"ten": "quả chuối", "icon": "🍌"},
          {"ten": "quả cam", "icon": "🍊"},
          {"ten": "quả dâu tây", "icon": "🍓"},
          {"ten": "quả dưa hấu", "icon": "🍉"},
          {"ten": "quả nho", "icon": "🍇"},
          {"ten": "quả đào", "icon": "🍑"},
          {"ten": "quả lê", "icon": "🍐"},
        ];
        // Chọn ngẫu nhiên một loại trái cây cho câu hỏi này
        var traiCayChon =
            danhSachLoaiTraiCay[_random.nextInt(danhSachLoaiTraiCay.length)];
        String tenQua = traiCayChon["ten"]!;
        String iconQua = traiCayChon["icon"]!;
        tieuDeDangBai =
            "Phần 1: Đếm số lượng hoa quả (${cauSoTrongDang + 1}/10)";
        int soLuong = _random.nextInt(8) + 2; // Từ 2 đến 9
        dapAnDungSo = soLuong;
        // Biến tấu đa dạng câu hỏi thay vì lặp một câu nhàm chán
        List<String> mauCauHoi = [
          "Có bao nhiêu $tenQua trong giỏ thế bé?",
          "Bé đếm xem có tất cả mấy $tenQua nhé!",
          "Đố bé biết có bao nhiêu $tenQua xuất hiện?",
        ];
        noiDungCauHoi = mauCauHoi[_random.nextInt(mauCauHoi.length)];
        // Lưu icon của loại quả để hiển thị ra màn hình giao diện
        // (Ba nhớ khai báo thêm biến `iconTraiCayHienTai = iconQua;` ở đầu class State nhé)
        iconTraiCayHienTai = iconQua;
        Set<int> luaChon = {dapAnDungSo};
        while (luaChon.length < soLuongLuaChon) {
          luaChon.add(_random.nextInt(9) + 1);
        }
        danhSachLuaChon = luaChon.toList()..shuffle();
      } else if (dangHienTai == "nghe_am_thanh") {
        tieuDeDangBai =
            "Phần 2: Nghe âm thanh đoán số (${cauSoTrongDang + 1}/10)";
        dapAnDungSo = _random.nextInt(9) + 1;
        noiDungCauHoi = "Lắng nghe máy đọc và chọn số vừa đọc nhé!";
        Set<int> luaChon = {dapAnDungSo};
        while (luaChon.length < soLuongLuaChon) {
          luaChon.add(_random.nextInt(9) + 1);
        }
        danhSachLuaChon = luaChon.toList()..shuffle();
        _noi("Bé hãy tìm số: $dapAnDungSo");
      } else if (dangHienTai == "tim_so_lon") {
        tieuDeDangBai = "Phần 3: Tìm số lớn nhất (${cauSoTrongDang + 1}/10)";
        Set<int> baSo = {};
        int soLuongSo = (soLuongLuaChon == 3) ? 3 : 4;
        while (baSo.length < soLuongSo) {
          baSo.add(_random.nextInt(9) + 1);
        }
        List<int> temp = baSo.toList();
        dapAnDungSo = temp.reduce(max);
        noiDungCauHoi = "Số nào lớn nhất trong các số sau: ${temp.join(', ')}?";
        danhSachLuaChon = temp..shuffle();
      } else if (dangHienTai == "dien_so_thieu") {
        tieuDeDangBai = "Phần 4: Điền số còn thiếu (${cauSoTrongDang + 1}/10)";
        int batDau = _random.nextInt(5) + 1;
        List<int> daySo = [batDau, batDau + 1, batDau + 2, batDau + 3];
        int doDaiDay = (soLuongLuaChon == 3) ? 3 : 4;
        int viTriAn = _random.nextInt(doDaiDay);
        dapAnDungSo = daySo[viTriAn];
        String moTa = "";
        for (int i = 0; i < doDaiDay; i++) {
          if (i == viTriAn)
            moTa += " ?,";
          else
            moTa += " ${daySo[i]},";
        }
        noiDungCauHoi = "Điền số còn thiếu vào dãy số:$moTa";
        Set<int> luaChon = {dapAnDungSo};
        while (luaChon.length < soLuongLuaChon) {
          luaChon.add(_random.nextInt(9) + 1);
        }
        danhSachLuaChon = luaChon.toList()..shuffle();
      } else if (dangHienTai == "sap_xep_so") {
        tieuDeDangBai = "Phần 5: Kéo thả sắp xếp số (${cauSoTrongDang + 1}/10)";
        Set<int> baSo = {};
        while (baSo.length < 3) {
          baSo.add(_random.nextInt(9) + 1);
        }
        danhSachGocSapXep = baSo.toList();
        laChieuTangDan = _random.nextBool();
        danhSachOTrong = [null, null, null];
        danhSachSoNguon = List.from(danhSachGocSapXep)..shuffle(_random);
        noiDungCauHoi = laChieuTangDan
            ? "Kéo thả các số theo thứ tự từ BÉ đến LỚN:"
            : "Kéo thả các số theo thứ tự từ LỚN đến BÉ:";
      }
    });
    _noi(noiDungCauHoi);
  }
  void _xuLyKetQuaCauHoi(bool laDung, String chiTietCauHoi) {
    setState(() {
      dangKhoaNut = true;
      tongSoCauDaLam++;
      if (laDung) {
        soCauDung++;
        _noi("Chính xác!");
      } else {
        soCauSai++;
        danhSachCauSaiChiTiet.add({
          "cau": chiTietCauHoi,
        });
        _noi("Chưa đúng rồi!");
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        cauSoTrongDang++;
        if (cauSoTrongDang >= 10) {
          cauSoTrongDang = 0;
          chiSoDangBaiHienTai++;
        }
      });
      _taoCauHoiMoi();
    });
  }

  void _kiemTraKieuKeoThaSapXep() {
    if (danhSachOTrong.contains(null)) return;
    List<int> dapAnChuan = List.from(danhSachGocSapXep);
    if (laChieuTangDan) {
      dapAnChuan.sort();
    } else {
      dapAnChuan.sort((a, b) => b.compareTo(a));
    }
    bool laChinhXac = true;
    for (int i = 0; i < 3; i++) {
      if (danhSachOTrong[i] != dapAnChuan[i]) {
        laChinhXac = false;
        break;
      }
    }
    _xuLyKetQuaCauHoi(laChinhXac,
        "Sắp xếp số ${danhSachGocSapXep.join(', ')} (${laChieuTangDan ? 'bé đến lớn' : 'lớn đến bé'})");
  }

  @override
  Widget build(BuildContext context) {
    String dangHienTai = chiSoDangBaiHienTai < danhSachCacDangBai.length
        ? danhSachCacDangBai[chiSoDangBaiHienTai]
        : "";
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text("Kiểm Tra 50 Câu (${tongSoCauDaLam + 1}/$tongSoCauHoi)"),
        backgroundColor: const ui.Color.fromARGB(150, 64, 233, 255),
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          daHoanThanhBaiKiemTra
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🎉 HOÀN THÀNH 50 CÂU HỎI 🎉",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange)),
                      const SizedBox(height: 15),
                      Text("Số câu đúng: $soCauDung / 50",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      Text("Số câu sai: $soCauSai / 50",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      const SizedBox(height: 5),
                      Text(
                          "Tổng điểm thực tế: ${max(0, (soCauDung * 2) - soCauSai)} / 100 điểm",
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple)),
                      const SizedBox(height: 15),
                      danhSachCauSaiChiTiet.isNotEmpty
                          ? Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                      "📝 Các nội dung bé làm sai cần ôn tập:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red)),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: danhSachCauSaiChiTiet.length,
                                      itemBuilder: (context, index) {
                                        var item = danhSachCauSaiChiTiet[index];
                                        return Card(
                                          child: ListTile(
                                            title: Text(item["cau"],
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Text(
                              "🌟 Siêu nhân toán học! Đạt điểm tuyệt đối 100/100!",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12)),
                        onPressed: () {
                          setState(() {
                            chiSoDangBaiHienTai = 0;
                            cauSoTrongDang = 0;
                            tongSoCauDaLam = 0;
                            soCauDung = 0;
                            soCauSai = 0;
                            daHoanThanhBaiKiemTra = false;
                            danhSachCauSaiChiTiet.clear();
                          });
                          _taoCauHoiMoi();
                        },
                        child: const Text("Làm lại bài kiểm tra từ đầu",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        value: (tongSoCauDaLam + 1) / tongSoCauHoi,
                        backgroundColor: Colors.orange.shade100,
                        color: Colors.deepOrange,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 15),
                      Text(tieuDeDangBai,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 32,
                            color: Colors.orange,
                            icon: const Icon(Icons.volume_up_rounded),
                            onPressed: () => _noi(noiDungCauHoi),
                          ),
                          Flexible(
                            child: Text(
                              noiDungCauHoi,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (dangHienTai == "dem_hoa_qua") ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: List.generate(
                              dapAnDungSo,
                              (_) => Text(iconTraiCayHienTai,
                                  style: const TextStyle(fontSize: 28))),
                        ),
                        const SizedBox(height: 30),
                        _buildNutLuaChon(),
                      ] else if (dangHienTai == "nghe_am_thanh") ...[
                        const Icon(Icons.hearing,
                            size: 60, color: Colors.orangeAccent),
                        const SizedBox(height: 30),
                        _buildNutLuaChon(),
                      ] else if (dangHienTai == "tim_so_lon" ||
                          dangHienTai == "dien_so_thieu") ...[
                        const SizedBox(height: 20),
                        _buildNutLuaChon(),
                      ] else if (dangHienTai == "sap_xep_so") ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: DragTarget<int>(
                                onAcceptWithDetails: (details) {
                                  setState(() {
                                    if (danhSachOTrong[index] != null) {
                                      danhSachSoNguon
                                          .add(danhSachOTrong[index]!);
                                    }
                                    danhSachOTrong[index] = details.data;
                                    danhSachSoNguon.remove(details.data);
                                  });
                                  _kiemTraKieuKeoThaSapXep();
                                },
                                builder:
                                    (context, candidateData, rejectedData) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: danhSachOTrong[index] != null
                                          ? Colors.orange.shade100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.orange, width: 2),
                                    ),
                                    child: danhSachOTrong[index] != null
                                        ? Text("${danhSachOTrong[index]}",
                                            style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepOrange))
                                        : const Text("?",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.grey)),
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: danhSachSoNguon.map((so) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Draggable<int>(
                                data: so,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: Colors.deepOrange,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Text("$so",
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: Colors.orangeAccent,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Text("$so",
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                ),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 3,
                                          offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: Text("$so",
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNutLuaChon() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: danhSachLuaChon.map((so) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: dangKhoaNut
              ? null
              : () {
                  bool laDung = (so == dapAnDungSo);
                  _xuLyKetQuaCauHoi(
                      laDung, "$noiDungCauHoi (Đáp án đúng: $dapAnDungSo)");
                },
          child: Text("$so",
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        );
      }).toList(),
    );
  }
}

// TRANG HÌNH KHỐI
class TrangHinhKhoi extends StatefulWidget {
  const TrangHinhKhoi({super.key});
  @override
  State<TrangHinhKhoi> createState() => _TrangHinhKhoiState();
}
class _TrangHinhKhoiState extends State<TrangHinhKhoi>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  late AnimationController _nhayController;
  late Animation<double> _nhayAnimation;
  late Animation<double> _chiTayAnimation;
  // Danh sách hình khối chuẩn xác biểu tượng
  final List<Map<String, dynamic>> danhSachHinhKhoi = [
    {"ten": "Hình Tròn", "icon": "🔵", "mau": Colors.blue, "moTa": "Hình tròn, tròn vo như quả bóng"},
    {"ten": "Hình Vuông", "icon": "🟥", "mau": Colors.red, "moTa": "Hình vuông có bốn cạnh bằng nhau"},
    {"ten": "Hình Chữ Nhật", "icon": "▬", "mau": Colors.deepOrange, "moTa": "Hình chữ nhật có hai cạnh dài và hai cạnh ngắn"},
    {"ten": "Hình Tam Giác", "icon": "🔺", "mau": Colors.green, "moTa": "Hình tam giác có ba cạnh và ba góc"},
    {"ten": "Hình Thoi", "icon": "🔶", "mau": Colors.amber, "moTa": "Hình thoi có bốn cạnh bằng nhau và các góc đối diện bằng nhau"},
    {"ten": "Hình Bình Hành", "icon": "▱", "mau": Colors.teal, "moTa": "Hình bình hành có các cạnh đối song song và bằng nhau"},
    {"ten": "Hình Thang", "icon": "⏢", "mau": Colors.indigo, "moTa": "Hình thang có hai cạnh đáy song song với nhau"},
    {"ten": "Ngôi Sao", "icon": "⭐", "mau": Colors.amberAccent, "moTa": "Ngôi sao lấp lánh có năm cánh"},
    {"ten": "Trái Tim", "icon": "❤️", "mau": Colors.pink, "moTa": "Hình trái tim tượng trưng cho tình yêu thương"},
    {"ten": "Hộp Chữ Nhật", "icon": "📦", "mau": Colors.blueGrey, "moTa": "Hình hộp chữ nhật có chiều dài, chiều rộng và chiều cao"},
    {"ten": "Hình Cầu", "icon": "🔮", "mau": Colors.purple, "moTa": "Hình cầu tròn lăn được mọi hướng như quả bóng"},
    {"ten": "Hình Trụ", "icon": "🛢️", "mau": Colors.brown, "moTa": "Hình trụ có hai mặt đáy là hình tròn bằng nhau"}
  ];
  @override
  void initState() {
    super.initState();
    _nhayController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _nhayAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
    _chiTayAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _nhayController, curve: Curves.easeInOut),
    );
    _khoiTaoTts();
  }
  @override
  void dispose() {
    flutterTts.stop();
    _nhayController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.45);
    if (!mounted) return;
    _noi("Bé hãy chạm vào các hình khối để khám phá nhé!");
  }
  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }
  // Hàm hiển thị Popup chi tiết phóng to chuẩn như Bảng Chữ Cái
  Future<void> _hienThiChiTiet(Map<String, dynamic> data) async {
    await flutterTts.stop();
    setState(() {
      _currentWordStart = 0;
      _currentWordEnd = 0;
    });
    String tenHinh = data["ten"]!;
    String icon = data["icon"]!;
    Color mauSac = data["mau"] as Color;
    String fullText = data["moTa"]!;
    bool hasPopped = false;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Center(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              flutterTts.setProgressHandler((text, start, end, word) {
                if (mounted) {
                  setDialogState(() {
                    _currentWordStart = start;
                    _currentWordEnd = end;
                  });
                }
              });
              flutterTts.setCompletionHandler(() {
                if (!hasPopped && mounted) {
                  hasPopped = true;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop();
                    }
                  });
                }
              });
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: mauSac, width: 3),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hàng chứa ngón tay chỉ và tên hình khối nhảy múa
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _chiTayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(_chiTayAnimation.value, 0),
                                child: const Text("👉",
                                    style: TextStyle(fontSize: 26)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedBuilder(
                              animation: _nhayAnimation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, _nhayAnimation.value),
                                child: Text(
                                  tenHinh,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: mauSac,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Biểu tượng icon hình khối phóng to nhảy múa
                        AnimatedBuilder(
                          animation: _nhayAnimation,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, _nhayAnimation.value),
                            child: Text(icon,
                                style: const TextStyle(fontSize: 65)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Đoạn mô tả có hiệu ứng đọc Highlight từng từ
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildHighlightedText(fullText),
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    await flutterTts.speak(fullText);
  }
  List<TextSpan> _buildHighlightedText(String text) {
    List<TextSpan> spans = [];
    if (_currentWordStart >= 0 &&
        _currentWordEnd <= text.length &&
        _currentWordStart < _currentWordEnd) {
      spans.add(TextSpan(text: text.substring(0, _currentWordStart)));
      spans.add(TextSpan(
        text: text.substring(_currentWordStart, _currentWordEnd),
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: text.substring(_currentWordEnd)));
    } else {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }
  // Nút quay lại chuẩn hình tròn viền cam có bóng đổ
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF0),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text("Tất Cả Hình Khối Toán Học",
            style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        backgroundColor: const ui.Color.fromARGB(200, 64, 255, 255),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const Text(
              "Bé hãy chạm vào hình bất kỳ để khám phá nhé! 👇",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                ),
                itemCount: danhSachHinhKhoi.length,
                itemBuilder: (context, index) {
                  final hinh = danhSachHinhKhoi[index];
                  return GestureDetector(
                    onTap: () => _hienThiChiTiet(hinh),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: hinh["mau"], width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(hinh["icon"],
                              style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              hinh["ten"],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: hinh["mau"],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//TRANG SO SÁNH
class TrangSoSanh extends StatefulWidget {
  const TrangSoSanh({super.key});
  @override
  State<TrangSoSanh> createState() => _TrangSoSanhState();
}
class _TrangSoSanhState extends State<TrangSoSanh> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late ConfettiController _confettiController;
  int soLanDienLienTiep = 0;
  bool dangKhoaNut = false;
  Map<String, dynamic>? cauHoiHienTai;
  // Giữ nguyên toàn bộ 100% danh sách câu hỏi của bạn
  final List<Map<String, dynamic>> danhSachCapSoSanh = [
    {"cauHoi": "Con vật nào TO HƠN?", "docCauHoi": "Bé hãy tìm xem con vật nào to lớn hơn nhé!", "vat1": {"icon": "🐘", "ten": "Con voi", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🐜", "ten": "Con kiến", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Con vật nào NHỎ HƠN?", "docCauHoi": "Bé ơi, con vật nào nhỏ hơn nhỉ?", "vat1": {"icon": "🐁", "ten": "Con chuột", "kichThuoc": 45, "laDapAnDung": true}, "vat2": {"icon": "🐄", "ten": "Con bò", "kichThuoc": 90, "laDapAnDung": false}},
{"cauHoi": "Con vật nào CAO HƠN?", "docCauHoi": "Đố bé tìm ra con vật có cổ cao ngất ngưởng nhé!", "vat1": {"icon": "🦒", "ten": "Hươu cao cổ", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🐖", "ten": "Con heo", "kichThuoc": 45, "laDapAnDung": false}},
{"cauHoi": "Con vật nào NẶNG HƠN?", "docCauHoi": "Bé chọn xem loài vật nào nặng hơn nha!", "vat1": {"icon": "🐋", "ten": "Cá voi xanh khổng lồ", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🐟", "ten": "Con cá nhỏ", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Loài cây nào CAO HƠN?", "docCauHoi": "Bé hãy tìm xem cây nào cao to hơn nhé!", "vat1": {"icon": "🌴", "ten": "Cây dừa", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🌷", "ten": "Bông hoa", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Cái cây nào THẤP HƠN?", "docCauHoi": "Bé tìm cây mầm nhỏ nhắn thấp hơn nào!", "vat1": {"icon": "🌱", "ten": "Cây non", "kichThuoc": 40, "laDapAnDung": true}, "vat2": {"icon": "🌲", "ten": "Cây thông lớn", "kichThuoc": 90, "laDapAnDung": false}},
{"cauHoi": "Ngọn núi nào TO LỚN HƠN?", "docCauHoi": "Ngọn núi nào lớn hơn bé iu ơi?", "vat1": {"icon": "🌋", "ten": "Núi lửa", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "⛰️", "ten": "Hòn đá nhỏ", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Phương tiện nào CHẠY NHANH HƠN?", "docCauHoi": "Chiếc xe nào phóng vù vù nhanh hơn nhỉ?", "vat1": {"icon": "🚄", "ten": "Tàu siêu tốc", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🚲", "ten": "Xe đạp", "kichThuoc": 45, "laDapAnDung": false}},
{"cauHoi": "Phương tiện nào TO HƠN?", "docCauHoi": "Đố bé tìm ra phương tiện to lớn khổng lồ nhé!", "vat1": {"icon": "✈️", "ten": "Máy bay", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🛴", "ten": "Xe trượt scooter", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Phương tiện nào LỚN HƠN?", "docCauHoi": "chiếc xe tải chở hàng hay xe con to hơn nào bé ơi!", "vat1": {"icon": "🚛", "ten": "Xe tải bự", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🚕", "ten": "Xe taxi", "kichThuoc": 45, "laDapAnDung": false}},
{"cauHoi": "Ngôi nhà nào TO HƠN?", "docCauHoi": "Ngôi nhà nào to lớn nguy nga hơn bé ơi?", "vat1": {"icon": "🏰", "ten": "Lâu đài hoàng gia", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "⛺", "ten": "Cái lều vải", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Món quà nào TO HƠN?", "docCauHoi": "Bé hãy chọn hộp quà to bự nhé!", "vat1": {"icon": "🎁", "ten": "Hộp quà to", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🍬", "ten": "Viên kẹo ngọt", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Cái bút nào DÀI HƠN?", "docCauHoi": "Đố bé tìm ra đò vật dài hơn nào!", "vat1": {"icon": "📏", "ten": "Thước kẻ", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🖍️", "ten": "Bút màu ngắn", "kichThuoc": 45, "laDapAnDung": false}},
{"cauHoi": "Chiếc balo nào TO HƠN?", "docCauHoi": "Cái cặp sách đi hay cái ví to hơn bé nhỉ?", "vat1": {"icon": "🎒", "ten": "Balo đi học", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "👛", "ten": "Cái ví nhỏ", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Quyển sách nào DÀY HƠN?", "docCauHoi": "Bé hãy tìm chồng sách dày hơn nhé!", "vat1": {"icon": "📚", "ten": "Chồng sách dày", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "📖", "ten": "Quyển vở mỏng", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Quả nào TO HƠN?", "docCauHoi": "Quả trái cây nào to lớn hơn bé ơi?", "vat1": {"icon": "🍉", "ten": "Quả dưa hấu", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🍓", "ten": "Quả dâu tây", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Quả nào TO HƠN?", "docCauHoi": "Bé so sánh xem quả nào to hơn nha!", "vat1": {"icon": "🍍", "ten": "Quả dứa vàng", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🍒", "ten": "Quả cherry", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Cái bánh nào TO HƠN?", "docCauHoi": "Đố bé biết Chiếc bánh to hơn nằm ở đâu nhỉ?", "vat1": {"icon": "🎂", "ten": "Bánh sinh nhật bự", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🧁", "ten": "Bánh cupcake nhỏ", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Vật thể nào TO LỚN HƠN?", "docCauHoi": "Mặt trời hay ngôi sao to hơn bé ơi?", "vat1": {"icon": "☀️", "ten": "Mặt trời", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "⭐", "ten": "Ngôi sao", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Cái nào TO HƠN?", "docCauHoi": "Đám mây mưa bự chảng hay bông hoa tuyết cái nào to hơn nhỉ?", "vat1": {"icon": "☁️", "ten": "Đám mây", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "❄️", "ten": "Bông tuyết", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Củ quả nào TO HƠN?", "docCauHoi": "Bé tìm giúp ba mẹ xem quả gì lớn hơn nhé?", "vat1": {"icon": "🎃", "ten": "Quả bí ngô", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🥕", "ten": "Củ cà rốt", "kichThuoc": 45, "laDapAnDung": false}},
{"cauHoi": "Đồ dùng nào TO HƠN?", "docCauHoi": "Bé xem chiếc tủ quần áo to bự hay cái ghế to hơn nhé!", "vat1": {"icon": "🗄️", "ten": "Tủ đựng đồ", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🪑", "ten": "Cái ghế", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ dùng nào DÀI HƠN?", "docCauHoi": "bé giúp cô đoán xem Cái giường ngủ dài hay chiếc gối ôm dài hơn?", "vat1": {"icon": "🛏️", "ten": "Giường ngủ", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🛌", "ten": "Gối nhỏ", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Thiết bị nào TO HƠN?", "docCauHoi": "Chiếc ti vi hay cái điện thoại to hơn bé ơi?", "vat1": {"icon": "📺", "ten": "Ti vi màn hình lớn", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "📱", "ten": "Điện thoại", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Nhạc cụ nào TO HƠN?", "docCauHoi": "Đàn piano to lớn hay chiếc kèn harmonica to hơn bé nhỉ?", "vat1": {"icon": "🎹", "ten": "Đàn piano", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🎵", "ten": "Nốt nhạc / Kèn nhỏ", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ vật nào NẶNG HƠN?", "docCauHoi": "Chiếc khóa cửa bằng sắt hay chiếc chìa khóa nặng hơn bé nhỉ?", "vat1": {"icon": "🔒", "ten": "Ổ khóa to", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🔑", "ten": "Chìa khóa", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Vật dụng nào TO HƠN?", "docCauHoi": "Chiếc gương soi toàn thân hay cái lược chải tóc to hơn nào con ơi?", "vat1": {"icon": "🪞", "ten": "Gương soi", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "梳", "ten": "Cái lược", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ dùng nào TO HƠN?", "docCauHoi": "Bồn tắm nước to bự hay cục xà phòng thơm to hơn?", "vat1": {"icon": "🛁", "ten": "Bồn tắm", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🧼", "ten": "Xà phòng", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Cây nến nào CAO HƠN?", "docCauHoi": "Bé tìm xem cây nến nào dài cao hơn nào!", "vat1": {"icon": "🕯️", "ten": "Cây nến dài", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🕯️", "ten": "Đoạn nến ngắn", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ vật nào TO HƠN?", "docCauHoi": "Chiếc dù che mưa to lớn hay chiếc mũ che nắng to hơn nào bé ơi?", "vat1": {"icon": "☂️", "ten": "Chiếc ô", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🧢", "ten": "Cái mũ", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Trang phục nào DÀI HƠN?", "docCauHoi": "Chiếc áo khoác ấm áp dài hay đôi găng tay dài hơn bé iu ơi?", "vat1": {"icon": "🧥", "ten": "Áo khoác", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🧤", "ten": "Găng tay", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Trang phục nào TO HƠN?", "docCauHoi": "Chiếc quần dài hay đôi vớ (tất) to hơn nào?", "vat1": {"icon": "👖", "ten": "Quần dài", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🧦", "ten": "Đôi tất", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ vật nào TO HƠN?", "docCauHoi": "Đó con Chiếc vali đựng quần áo du lịch hay cái túi xách tay to hơn nhỉ?", "vat1": {"icon": "🧳", "ten": "Vali du lịch", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "👜", "ten": "Túi xách", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ vật nào NẶNG HƠN?", "docCauHoi": "Cục tạ tập gym nặng ký hay quả bóng tennis nặng hơn con nhỉ?", "vat1": {"icon": "🏋️", "ten": "Cục tạ", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🎾", "ten": "Quả bóng tennis", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ dùng nào TO HƠN?", "docCauHoi": "Cái nồi nấu ăn to bự hay cái muỗng (thìa) to hơn con ơi?", "vat1": {"icon": "🍲", "ten": "Cái nồi", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🥄", "ten": "Cái muỗng", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ dùng nào TO HƠN?", "docCauHoi": "Cái chảo chiên thức ăn hay chiếc nĩa (dĩa) nhỏ hơn nào?", "vat1": {"icon": "🍳", "ten": "Cái chảo", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🍴", "ten": "Cái nĩa", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Thức ăn nào TO HƠN?", "docCauHoi": "Ổ bánh mì dài thơm ngon hay chiếc kẹo mút dài hơn nhỉ?", "vat1": {"icon": "🥖", "ten": "Bánh mì dài", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🍭", "ten": "Kẹo mút", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ vật nào TO HƠN?", "docCauHoi": "Thùng rác lớn hay cuộn giấy vệ sinh lớn hơn bé ơi?", "vat1": {"icon": "🗑️", "ten": "Thùng rác", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🧻", "ten": "Cuộn giấy", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Con vật nào TO LỚN HƠN?", "docCauHoi": "Bé xem chú trâu hay chú gà trống  con nào nhỏ hơn nhỉ!", "vat1": {"icon": "🐃", "ten": "Con trâu", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🐓", "ten": "Gà trống", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Vật thể nào TO LỚN HƠN?", "docCauHoi": "Hành tinh Trái Đất to lớn hay chiếc kính lúp to hơn nào cục cưng ơi?", "vat1": {"icon": "🌍", "ten": "Trái Đất", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🔍", "ten": "Kính lúp", "kichThuoc": 40, "laDapAnDung": false}},
{"cauHoi": "Đồ chơi nào TO HƠN?", "docCauHoi": "Con gấu bông ôm ngủ to hay mảnh Rubi to hơn nhỉ?", "vat1": {"icon": "🧸", "ten": "Gấu bông", "kichThuoc": 90, "laDapAnDung": true}, "vat2": {"icon": "🧩", "ten": "Khối Rubik", "kichThuoc": 40, "laDapAnDung": false}
    },
  ];
  final List<String> _danhSachCauKhen = [
    "Woa, bé chọn nhanh và chuẩn xác quá đi!",
    "Đỉnh quá em bé ơi! Một câu trả lời xuất sắc!",
    "Chính xác hoàn toàn! Bé thật là tinh mắt!",
    "Bé yêu siêu thật đấy, thưởng cho bé một tràng vỗ tay nào!",
    "Quá đỉnh! Tri thức nhí đây rồi, tiếp tục phát huy nhé!",
    "Chuẩn không cần chỉnh! Bé thông minh quá đi mất!",
    "Bé quan sát cực kỳ tinh tế luôn, tuyệt vời!",
    "Lại đúng nữa rồi! Bé nhà mình giỏi thế cơ chứ!"
  ];
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _khoiTaoTts();
  }
  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.52);
    if (!mounted) return;
    _taoCauHoiMoi();
  }
  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }
  void _taoCauHoiMoi() {
    if (!mounted) return;
    var mauNgauNhien =
        danhSachCapSoSanh[_random.nextInt(danhSachCapSoSanh.length)];
    // Tạo bản sao để tránh bị ghi đè vị trí trong mảng gốc
    Map<String, dynamic> cauHoiMoi = {
      "cauHoi": mauNgauNhien["cauHoi"],
      "docCauHoi": mauNgauNhien["docCauHoi"],
      "vat1": Map<String, dynamic>.from(mauNgauNhien["vat1"]),
      "vat2": Map<String, dynamic>.from(mauNgauNhien["vat2"]),
    };
    // Hoán đổi vị trí hiển thị ngẫu nhiên (trái / phải)
    if (_random.nextBool()) {
      var temp = cauHoiMoi["vat1"];
      cauHoiMoi["vat1"] = cauHoiMoi["vat2"];
      cauHoiMoi["vat2"] = temp;
    }
    setState(() {
      cauHoiHienTai = cauHoiMoi;
      dangKhoaNut = false;
    });
    _noi(cauHoiMoi["docCauHoi"]);
  }
  void _xuLyChon(bool laDapAnDung, String tenVat) async {
    if (!mounted || dangKhoaNut) return;
    if (laDapAnDung) {
      // ĐÚNG
      setState(() {
        dangKhoaNut = true;
        soLanDienLienTiep++;
      });
      if (soLanDienLienTiep % 5 == 0) {
        _confettiController.play();
      }
      String cauKhen =
          _danhSachCauKhen[_random.nextInt(_danhSachCauKhen.length)];
      await _noi(cauKhen);
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) {
        _taoCauHoiMoi();
      }
    } else {
      // SAI
      setState(() {
        soLanDienLienTiep = 0;
        dangKhoaNut = true;
      });
      // Đọc câu thông báo sai
      await _noi("Chưa đúng rồi. Đây là $tenVat mà, bé thử lại nhé!");
      // Đợi một khoảng thời gian ngắn để hết câu nói rồi mở khóa nút ngay (không gọi lại _taoCauHoiMoi hay đọc lại đề)
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          dangKhoaNut = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (cauHoiHienTai == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8DC),
        body: Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent)),
      );
    }
    var vat1 = cauHoiHienTai!["vat1"];
    var vat2 = cauHoiHienTai!["vat2"];
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text("So Sánh Lớn - Nhỏ"),
        backgroundColor: const ui.Color.fromARGB(179, 64, 233, 255),
        // Tích hợp nút quay lại hình tròn viền cam theo yêu cầu
        leading: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 25),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Text(
                    "🔥 Chuỗi đúng liên tiếp: $soLanDienLienTiep",
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange),
                  ),
                ),
                const SizedBox(height: 0),
                IconButton(
                  iconSize: 30,
                  color: Colors.orange,
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: () => _noi(cauHoiHienTai!["docCauHoi"]),
                ),
                const SizedBox(height: 0),
                Text(
                  cauHoiHienTai!["cauHoi"],
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Vật 1
                    GestureDetector(
                      onTap: dangKhoaNut
                          ? null
                          : () => _xuLyChon(vat1["laDapAnDung"], vat1["ten"]),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.orangeAccent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          vat1["icon"],
                          style: TextStyle(
                              fontSize: (vat1["kichThuoc"] as int).toDouble()),
                        ),
                      ),
                    ),
                    // Vật 2
                    GestureDetector(
                      onTap: dangKhoaNut
                          ? null
                          : () => _xuLyChon(vat2["laDapAnDung"], vat2["ten"]),
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.orangeAccent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          vat2["icon"],
                          style: TextStyle(
                              fontSize: (vat2["kichThuoc"] as int).toDouble()),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//TRANG QUY LUẬT
class TrangQuyLuat extends StatefulWidget {
  const TrangQuyLuat({super.key});
  @override
  State<TrangQuyLuat> createState() => _TrangQuyLuatState();
}
class _TrangQuyLuatState extends State<TrangQuyLuat> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late ConfettiController _confettiController;
  int soLanDienLienTiep = 0;
  bool dangKhoaNut = false;
  late Map<String, dynamic> cauHoiHienTai;
  // Kho tàng quy luật phong phú, đa dạng chủ đề cho bé
  final List<Map<String, dynamic>> danhSachQuyLuat = [
    // Chuỗi 1
    {
      "chuoi": "🍎 🍌 🍎 🍌  ❓",
      "docCauHoi": "Táo, chuối, táo, chuối. Đố bé hình tiếp theo là quả gì?",
      "dapAnDung": "🍎",
      "tenDapAn": "quả táo",
      "danhSachLuaChon": ["🍎", "🍇", "🍊"]
    },
    // Chuỗi 2
    {
      "chuoi": "🔴 🟦 🔴 🟦  ❓",
      "docCauHoi":
          "Hình tròn đỏ, hình vuông xanh, tròn đỏ, vuông xanh. Tiếp theo là hình gì nào?",
      "dapAnDung": "🔴",
      "tenDapAn": "hình tròn đỏ",
      "danhSachLuaChon": ["🟦", "🔴", "⭐"]
    },
    // Chuỗi 3
    {
      "chuoi": "⭐ ⭐ 🌙 ⭐ ⭐  ❓",
      "docCauHoi":
          "hai Ngôi sao, mặt trăng, hai ngôi sao. Tiếp theo là hình gì bé nhỉ?",
      "dapAnDung": "🌙",
      "tenDapAn": "mặt trăng",
      "danhSachLuaChon": ["⭐", "🌙", "☀️"]
    },
    // Chuỗi 4
    {
      "chuoi": "🐶 🐱 🐶 🐱  ❓",
      "docCauHoi": "Con cún, con mèo, cún, mèo. Đố bé con gì tiếp theo?",
      "dapAnDung": "🐶",
      "tenDapAn": "chú cún",
      "danhSachLuaChon": ["🐱", "🐶", "🐰"]
    },
    // Chuỗi 5
    {
      "chuoi": "🚗 🚲 🚗 🚲  ❓",
      "docCauHoi": "Ô tô, xe đạp, ô tô, xe đạp. Tiếp theo là xe gì nào?",
      "dapAnDung": "🚗",
      "tenDapAn": "ô tô",
      "danhSachLuaChon": ["🚲", "🚗", "✈️"]
    },
    // Chuỗi 6
    {
      "chuoi": "🟢 🟡 🔴 🟢 🟡  ❓",
      "docCauHoi": "Xanh lá, vàng, đỏ. Xanh lá, vàng. Tiếp theo màu gì bé ơi?",
      "dapAnDung": "🔴",
      "tenDapAn": "màu đỏ",
      "danhSachLuaChon": ["🟢", "🔴", "🟡"]
    },
    // Chuỗi 7
    {
      "chuoi": "🌸 🌺 🌸 🌺  ❓",
      "docCauHoi":
          "Hoa hồng, hoa râm bụt, hoa hồng, hoa râm bụt. Tiếp theo là hoa gì?",
      "dapAnDung": "🌸",
      "tenDapAn": "bông hoa hồng",
      "danhSachLuaChon": ["🌺", "🌸", "🌻"]
    },
    // Chuỗi 8
    {
      "chuoi": "🍉 🍊 🍉 🍊  ❓",
      "docCauHoi": "Dưa hấu, quả cam, dưa hấu, cam. Hình tiếp theo là gì nào?",
      "dapAnDung": "🍉",
      "tenDapAn": "quả dưa hấu",
      "danhSachLuaChon": ["🍊", "🍉", "🍓"]
    },
    {
      "chuoi": "🐱 🐱 🐶 🐱 🐱  ❓",
      "docCauHoi": "Hai mèo, một cún. Hai mèo. Tiếp theo là con vật gì bé nhỉ?",
      "dapAnDung": "🐶",
      "tenDapAn": "chú cún",
      "danhSachLuaChon": ["🐱", "🐶", "🐰"]
    },
    {
      "chuoi": "☀️ ☁️ 🌧️ ☀️ ☁️  ❓",
      "docCauHoi":
          "Mặt trời, đám mây, mưa. Mặt trời, đám mây. Tiếp theo thời tiết gì nào?",
      "dapAnDung": "🌧️",
      "tenDapAn": "trời mưa",
      "danhSachLuaChon": ["☀️", "☁️", "🌧️"]
    },
    {
      "chuoi": "⚽ 🏀 ⚽ 🏀  ❓",
      "docCauHoi":
          "Quả bóng đá, bóng rổ, bóng đá, bóng rổ. Đố bé quả gì tiếp theo?",
      "dapAnDung": "⚽",
      "tenDapAn": "quả bóng đá",
      "danhSachLuaChon": ["🏀", "⚽", "🎾"]
    },
    {
      "chuoi": "🐟 🐠 🐟 🐠  ❓",
      "docCauHoi":
          "Cá xanh, cá vàng, cá xanh, cá vàng. Tiếp theo con cá gì bé ơi?",
      "dapAnDung": "🐟",
      "tenDapAn": "con cá xanh",
      "danhSachLuaChon": ["🐠", "🐟", "🐳"]
    },
    {
      "chuoi": "🍎 🍎 🍌 🍎 🍎  ❓",
      "docCauHoi":
          "Hai quả táo, một quả chuối. Hai quả táo. Tiếp theo quả gì nào?",
      "dapAnDung": "🍌",
      "tenDapAn": "quả chuối",
      "danhSachLuaChon": ["🍎", "🍌", "🍇"]
    },
    {
      "chuoi": "🦋 🐝 🦋 🐝  ❓",
      "docCauHoi":
          "Con bướm, con ong, con bướm, con ong. Hình tiếp theo là gì?",
      "dapAnDung": "🦋",
      "tenDapAn": "con bướm",
      "danhSachLuaChon": ["🐝", "🦋", "🐞"]
    },
    {
      "chuoi": "🟢 🟢 🔴 🟢 🟢  ❓",
      "docCauHoi":
          "Hai hình tròn xanh, một hình đỏ. Hai xanh. Tiếp theo màu gì?",
      "dapAnDung": "🔴",
      "tenDapAn": "hình tròn đỏ",
      "danhSachLuaChon": ["🟢", "🔴", "🟡"]
    },
    {
      "chuoi": "🚀 🛸 🚀 🛸  ❓",
      "docCauHoi":
          "Tên lửa, đĩa bay, tên lửa, đĩa bay. Tiếp theo bay tới đâu nhỉ?",
      "dapAnDung": "🚀",
      "tenDapAn": "tên lửa",
      "danhSachLuaChon": ["🛸", "🚀", "⭐"]
    },
    {
      "chuoi": "🍓 🍓 🍋 🍓 🍓  ❓",
      "docCauHoi":
          "Hai dâu tây, một quả chanh vàng. Hai dâu tây. Tiếp theo quả gì?",
      "dapAnDung": "🍋",
      "tenDapAn": "quả chanh",
      "danhSachLuaChon": ["🍓", "🍋", "🍉"]
    },
    {
      "chuoi": "⭐ 💖 ⭐ 💖  ❓",
      "docCauHoi":
          "Ngôi sao, trái tim, ngôi sao, trái tim. Tiếp theo hình gì bé ơi?",
      "dapAnDung": "⭐",
      "tenDapAn": "ngôi sao",
      "danhSachLuaChon": ["💖", "⭐", "🔵"]
    },
    {
      "chuoi": "⭐ 🌙 🌙 ⭐ 🌙 🌙  ❓",
      "docCauHoi":
          "Một ngôi sao, hai mặt trăng. Một ngôi sao, hai mặt trăng. Tiếp theo là hình gì nào?",
      "dapAnDung": "⭐",
      "tenDapAn": "ngôi sao",
      "danhSachLuaChon": ["⭐", "🌙", "☀️"]
    },
    {
      "chuoi": "🍎 🍌 🍇 🍎 🍌  ❓",
      "docCauHoi":
          "Táo, chuối, nho. Lại đến táo, chuối. Đố bé quả tiếp theo là gì?",
      "dapAnDung": "🍇",
      "tenDapAn": "quả nho",
      "danhSachLuaChon": ["🍎", "🍌", "🍇"]
    },
    {
      "chuoi": "🔴 🔴 🔵 🔵 🟢 🟢  ❓",
      "docCauHoi":
          "Hai hình đỏ, hai hình xanh dương, hai hình xanh lá. Tiếp theo cặp hình màu gì bé nhỉ?",
      "dapAnDung": "🔴",
      "tenDapAn": "hình tròn đỏ",
      "danhSachLuaChon": ["🔴", "🔵", "🟢"]
    },
    {
      "chuoi": "🐱 🐶 🐰 🐱 🐶  ❓",
      "docCauHoi":
          "Mèo, cún, thỏ. Quay lại mèo, cún. Tiếp theo là con vật gì nào?",
      "dapAnDung": "🐰",
      "tenDapAn": "con thỏ",
      "danhSachLuaChon": ["🐱", "🐰", "🐶"]
    },
    {
      "chuoi": "🚗 🚗 🚲 🚗 🚗  ❓",
      "docCauHoi":
          "Hai ô tô, một xe đạp. Hai ô tô. Đố bé chiếc xe tiếp theo là gì?",
      "dapAnDung": "🚲",
      "tenDapAn": "xe đạp",
      "danhSachLuaChon": ["🚗", "🚲", "✈️"]
    },
    {
      "chuoi": "⭐ ⭐ ⭐ 🌙 ⭐ ⭐ ⭐  ❓",
      "docCauHoi":
          "Ba ngôi sao, một mặt trăng. Ba ngôi sao. Hình tiếp theo là gì bé ơi?",
      "dapAnDung": "🌙",
      "tenDapAn": "mặt trăng",
      "danhSachLuaChon": ["⭐", "🌙", "☀️"]
    },
    {
      "chuoi": "🟢 🟡 🔴 🔵 🟢 🟡  ❓",
      "docCauHoi":
          "Xanh lá, vàng, đỏ, xanh dương. Lại đến xanh lá, vàng. Tiếp theo màu gì?",
      "dapAnDung": "🔴",
      "tenDapAn": "màu đỏ",
      "danhSachLuaChon": ["🔴", "🟢", "🔵"]
    },
    {
      "chuoi": "🍦 🍦 🎂 🍦 🍦  ❓",
      "docCauHoi":
          "Hai cây kem, một cái bánh sinh nhật. Hai cây kem. Tiếp theo là món gì nào?",
      "dapAnDung": "🎂",
      "tenDapAn": "bánh sinh nhật",
      "danhSachLuaChon": ["🍦", "🎂", "🍬"]
    },
    {
      "chuoi": "🌸 🌺 🌻 🌸 🌺  ❓",
      "docCauHoi":
          "Hoa đào, hoa râm bụt, hoa hướng dương. Lại đến hoa đào, hoa râm bụt. Tiếp theo hoa gì bé nhỉ?",
      "dapAnDung": "🌻",
      "tenDapAn": "hoa hướng dương",
      "danhSachLuaChon": ["🌸", "🌺", "🌻"]
    },
    {
      "chuoi": "☀️ ☁️ ☀️ ☁️  ❓",
      "docCauHoi":
          "Mặt trời, đám mây. Mặt trời, đám mây. Đố bé thời tiết tiếp theo là gì nào?",
      "dapAnDung": "☀️",
      "tenDapAn": "mặt trời",
      "danhSachLuaChon": ["☀️", "☁️", "🌧️"]
    },
  ];
  final List<String> _danhSachCauKhen = [
    "Qúa đỉnh em bé ơi! Bé tìm ra quy luật chính xác tuyệt đối!",
    "Woa, bé thông minh quá! Hoan hô bé yêu!",
    "Đúng chuẩn luôn! Bé tư duy siêu thật đấy!",
    "Bé tinh mắt quá đi, thưởng cho bé một tràng pháo tay nào!",
    "Xuất sắc! Lại thêm một điểm 10 tròn xoe cho bé!",
  ];
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    // Khởi tạo sẵn một câu hỏi đầu tiên (phòng trường hợp danh sách không trống)
    if (danhSachQuyLuat.isNotEmpty) {
      cauHoiHienTai = danhSachQuyLuat[_random.nextInt(danhSachQuyLuat.length)];
    }
    _khoiTaoTts();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.52);
    if (!mounted) return;
    _taoCauHoiMoi();
  }
  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }
  void _taoCauHoiMoi() {
    if (!mounted) return;
    setState(() {
      cauHoiHienTai = danhSachQuyLuat[_random.nextInt(danhSachQuyLuat.length)];
      // Xáo trộn vị trí các nút lựa chọn để tăng độ thử thách
      (cauHoiHienTai["danhSachLuaChon"] as List).shuffle();
      dangKhoaNut = false;
    });
    _noi(cauHoiHienTai["docCauHoi"]);
  }
  void _xuLyChon(String luaChon, String dapAnDung) async {
    if (!mounted) return;
    // Khóa nút ngay khi người dùng bấm chọn để tránh bấm đúp
    setState(() {
      dangKhoaNut = true;
    });
    if (luaChon == dapAnDung) {
      // ĐÚNG
      setState(() {
        soLanDienLienTiep++;
      });
      if (soLanDienLienTiep % 5 == 0) {
        _confettiController.play();
      }
      String cauKhen =
          _danhSachCauKhen[_random.nextInt(_danhSachCauKhen.length)];
      // Đợi đọc xong câu khen thì chuyển sang câu hỏi mới
      flutterTts.setCompletionHandler(() {
        flutterTts.setCompletionHandler(() {});
        if (mounted) _taoCauHoiMoi();
      });
      await _noi(cauKhen);
    } else {
      // SAI
      setState(() {
        soLanDienLienTiep = 0;
      });
      // Sau khi đọc xong câu thông báo sai, mở khóa nút ngay lập tức để bé chọn lại
      flutterTts.setCompletionHandler(() {
        flutterTts.setCompletionHandler(() {});
        if (mounted) {
          setState(() => dangKhoaNut = false);
        }
      });
      await _noi(
          "Chưa đúng rồi bé ơi. Bé quan sát kỹ lại chuỗi rồi thử lại nhé!");
    }
  }
  @override
  Widget build(BuildContext context) {
    String chuoiHienThi = cauHoiHienTai["chuoi"] ?? "";
    String dapAnDung = cauHoiHienTai["dapAnDung"] ?? "";
    List danhSachLuaChon = cauHoiHienTai["danhSachLuaChon"] ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text("Quy Luật Hình Ảnh"),
        backgroundColor: const ui.Color.fromARGB(171, 64, 255, 245),
        // Đưa nút quay lại có viền tròn vào leading của AppBar
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding:
                  EdgeInsets.zero, // Bỏ padding mặc định để icon nằm chính giữa
              icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Nội dung chính của màn hình
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Text(
                    "🔥 Chuỗi đúng liên tiếp: $soLanDienLienTiep",
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange),
                  ),
                ),
                const SizedBox(height: 1),
                IconButton(
                  iconSize: 30,
                  color: Colors.orange,
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: () => _noi(cauHoiHienTai["docCauHoi"]),
                ),
                const SizedBox(height: 1),
                const Text(
                  "Tìm hình tiếp theo cho chuỗi quy luật:",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 1),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.lightBlue, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Text(
                    chuoiHienThi,
                    style: const TextStyle(fontSize: 27),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: danhSachLuaChon.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        onPressed: dangKhoaNut
                            ? null
                            : () => _xuLyChon(item, dapAnDung),
                        child: Text(item, style: const TextStyle(fontSize: 27)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // HIỆU ỨNG PHÁO HOA
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 35,
              gravity: 0.2,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// PHÉP CỘNG TRỪ TRỰC QUAN
class TrangCongTru extends StatefulWidget {
  const TrangCongTru({super.key});
  @override
  State<TrangCongTru> createState() => _TrangCongTruState();
}
class _TrangCongTruState extends State<TrangCongTru> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late String cauHoiMoTa;
  late String chuoiHienThi;
  // ✅ MỚI (An toàn tuyệt đối)
  int dapAnDung = 1;
  List<int> danhSachLuaChon = [1, 2, 3];
  late String goiYSai;
  late String goiYDung;
  String _thongBaoTrangThai =
      ""; // Dòng thông báo hướng dẫn trực tiếp khi bé chọn sai
  // Biến quản lý thứ tự câu hỏi ngẫu nhiên, chống trùng lặp
  final List<int> _danhSachChiSoChuaDung = [];
  int _currentIndex = -1;
  // Kho câu hỏi phong phú về Phép Cộng & Phép Trừ trực quan
  final List<Map<String, dynamic>> _khoCongTru = [
    // PHÉP CỘNG CƠ BẢN (THÊM ĐỒ VẬT)
    {"moTa": "Có 2 chú mèo, thêm 1 chú mèo là mấy?", "chuoi": "🐱 🐱  +  🐱  =  ?", "dapAn": 3, "luaChon": [3, 4], "sai": "Bé đếm lại tổng số chú mèo trên màn hình nhé!", "dung": "2 cộng 1 bằng 3 hoàn toàn chính xác!"},
{"moTa": "Có 3 quả táo, thêm 2 quả táo là mấy?", "chuoi": "🍎 🍎 🍎  +  🍎 🍎  =  ?", "dapAn": 5, "luaChon": [4, 5], "sai": "Gợi ý: Lấy 3 quả thêm 2 quả nữa là 5 bé nhé!", "dung": "Quá thông minh! 3 cộng 2 bằng 5 quả táo!"},
{"moTa": "Có 4 chú cún, thêm 1 chú cún là mấy?", "chuoi": "🐶 🐶 🐶 🐶  +  🐶  =  ?", "dapAn": 5, "luaChon": [5, 6], "sai": "Gợi ý: Đếm tiếp thêm 1 chú cún từ số 4 nào!", "dung": "Xuất sắc! 4 cộng 1 bằng 5 chú cún!"},
{"moTa": "Có 1 quả bóng, thêm 3 quả bóng là mấy?", "chuoi": "⚽  +  ⚽ ⚽ ⚽  =  ?", "dapAn": 4, "luaChon": [3, 4], "sai": "Gợi ý: 1 cộng thêm 3 đơn vị nữa nhé bé!", "dung": "Tuyệt đỉnh! 1 cộng 3 bằng 4 quả bóng!"},
{"moTa": "Có 2 bông hoa, thêm 2 bông hoa là mấy?", "chuoi": "🌸 🌸  +  🌸 🌸  =  ?", "dapAn": 4, "luaChon": [4, 5], "sai": "Gợi ý: 2 hoa thêm 2 hoa nữa là mấy nào?", "dung": "Quá siêu phàm! 2 cộng 2 bằng 4 bông hoa!"},
{"moTa": "Có 3 ngôi sao, thêm 3 ngôi sao là mấy?", "chuoi": "⭐ ⭐ ⭐  +  ⭐ ⭐ ⭐  =  ?", "dapAn": 6, "luaChon": [5, 6], "sai": "Gợi ý: Đếm tổng số ngôi sao xuất hiện nhé!", "dung": "Chính xác tuyệt đối! 3 cộng 3 bằng 6!"},
{"moTa": "Có 5 viên kẹo, thêm 1 viên kẹo là mấy?", "chuoi": "🍬 🍬 🍬 🍬 🍬  +  🍬  =  ?", "dapAn": 6, "luaChon": [6, 7], "sai": "Gợi ý: Số liền sau số 5 là số mấy nào?", "dung": "Hoan hô bé! 5 cộng 1 bằng 6 viên kẹo!"},
{"moTa": "Có 4 quả bóng bàn, thêm 2 quả là mấy?", "chuoi": "🎾 🎾 🎾 🎾  +  🎾 🎾  =  ?", "dapAn": 6, "luaChon": [5, 6], "sai": "Gợi ý: 4 thêm 2 bước tiến nữa là mấy?", "dung": "Tuyệt vời! 4 cộng 2 bằng 6!"},
{"moTa": "Có 6 chiếc xe, thêm 2 chiếc xe là mấy?", "chuoi": "🚗 🚗 🚗 🚗 🚗 🚗  +  🚗 🚗  =  ?", "dapAn": 8, "luaChon": [7, 8], "sai": "Gợi ý: Đếm gộp tất cả các chiếc xe lại nào!", "dung": "Quá đỉnh chóp! 6 cộng 2 bằng 8 chiếc xe!"},
{"moTa": "Có 5 chú cá, thêm 3 chú cá là mấy?", "chuoi": "🐠 🐠 🐠 🐠 🐠  +  🐠 🐠 🐠  =  ?", "dapAn": 8, "luaChon": [8, 9], "sai": "Gợi ý: 5 cộng thêm 3 đơn vị nữa nhé bé!", "dung": "Xuất sắc! 5 cộng 3 bằng 8 chú cá!"},
{"moTa": "Có 1 quả chuối, thêm 2 quả chuối là mấy?", "chuoi": "🍌  +  🍌 🍌  =  ?", "dapAn": 3, "luaChon": [3, 4], "sai": "Bé đếm lại tổng số quả chuối trên màn hình nhé!", "dung": "1 cộng 2 bằng 3 quả chuối chính xác!"},
{"moTa": "Có 2 chú thỏ, thêm 1 chú thỏ là mấy?", "chuoi": "🐰 🐰  +  🐰  =  ?", "dapAn": 3, "luaChon": [2, 3], "sai": "Gợi ý: 2 chú thỏ thêm 1 chú thỏ nữa là mấy nào?", "dung": "Giỏi quá! 2 cộng 1 bằng 3 chú thỏ!"},
{"moTa": "Có 3 chiếc lá, thêm 1 chiếc lá là mấy?", "chuoi": "🍃 🍃 🍃  +  🍃  =  ?", "dapAn": 4, "luaChon": [4, 5], "sai": "Gợi ý: Đếm tiếp số 3 thêm 1 bước là số mấy?", "dung": "Đúng rồi! 3 cộng 1 bằng 4 chiếc lá!"},
{"moTa": "Có 2 quả dâu, thêm 2 quả dâu là mấy?", "chuoi": "🍓 🍓  +  🍓 🍓  =  ?", "dapAn": 4, "luaChon": [4, 5], "sai": "Gợi ý: 2 quả dâu gộp với 2 quả dâu là mấy nhỉ?", "dung": "Quá xuất sắc! 2 cộng 2 bằng 4 quả dâu!"},
{"moTa": "Có 1 chiếc mũ, thêm 3 chiếc mũ là mấy?", "chuoi": "🧢  +  🧢 🧢 🧢  =  ?", "dapAn": 4, "luaChon": [3, 4], "sai": "Gợi ý: 1 thêm 3 đơn vị nữa là mấy bé ơi?", "dung": "Tuyệt vời! 1 cộng 3 bằng 4 chiếc mũ!"},
{"moTa": "Có 4 quả bóng bay, thêm 1 quả là mấy?", "chuoi": "🎈 🎈 🎈 🎈  +  🎈  =  ?", "dapAn": 5, "luaChon": [5, 6], "sai": "Gợi ý: Số liền sau số 4 là số mấy nào?", "dung": "Chính xác! 4 cộng 1 bằng 5 quả bóng bay!"},
{"moTa": "Có 3 viên kẹo mút, thêm 2 viên là mấy?", "chuoi": "🍭 🍭 🍭  +  🍭 🍭  =  ?", "dapAn": 5, "luaChon": [4, 5], "sai": "Gợi ý: 3 thêm 2 bước đếm nữa nhé bé!", "dung": "Giỏi lắm! 3 cộng 2 bằng 5 viên kẹo mút!"},
{"moTa": "Có 2 bông hoa hướng dương, thêm 3 bông là mấy?", "chuoi": "🌻 🌻  +  🌻 🌻 🌻  =  ?", "dapAn": 5, "luaChon": [5, 6], "sai": "Gợi ý: Đếm gộp tất cả số hoa lại nào!", "dung": "Hoan hô bé! 2 cộng 3 bằng 5 bông hoa!"},
{"moTa": "Có 4 cái bút chì, thêm 2 cái là mấy?", "chuoi": "✏️ ✏️ ✏️ ✏️  +  ✏️ ✏️  =  ?", "dapAn": 6, "luaChon": [5, 6], "sai": "Gợi ý: 4 cộng thêm 2 đơn vị là mấy nhỉ?", "dung": "Quá đỉnh! 4 cộng 2 bằng 6 cái bút chì!"},
{"moTa": "Có 3 chiếc bánh, thêm 3 chiếc bánh là mấy?", "chuoi": "🧁 🧁 🧁  +  🧁 🧁 🧁  =  ?", "dapAn": 6, "luaChon": [6, 7], "sai": "Gợi ý: 3 cái thêm 3 cái nữa bằng mấy nào?", "dung": "Tuyệt đỉnh! 3 cộng 3 bằng 6 chiếc bánh!"},
{"moTa": "Có 5 quả cam, thêm 2 quả cam là mấy?", "chuoi": "🍊 🍊 🍊 🍊 🍊  +  🍊 🍊  =  ?", "dapAn": 7, "luaChon": [6, 7], "sai": "Gợi ý: Đếm tiếp từ số 5 thêm 2 bước nữa nhé!", "dung": "Chính xác tuyệt đối! 5 cộng 2 bằng 7 quả cam!"},
{"moTa": "Có 4 quả dưa hấu, thêm 3 quả là mấy?", "chuoi": "🍉 🍉 🍉 🍉  +  🍉 🍉 🍉  =  ?", "dapAn": 7, "luaChon": [7, 8], "sai": "Gợi ý: 4 quả thêm 3 quả nữa là mấy bé ơi?", "dung": "Xuất sắc! 4 cộng 3 bằng 7 quả dưa hấu!"},
{"moTa": "Có 6 chiếc ô tô nhỏ, thêm 1 chiếc là mấy?", "chuoi": "🚗 🚗 🚗 🚗 🚗 🚗  +  🚗  =  ?", "dapAn": 7, "luaChon": [7, 8], "sai": "Gợi ý: Số liền sau số 6 là số mấy nào?", "dung": "Quá siêu! 6 cộng 1 bằng 7 chiếc xe!"},
{"moTa": "Có 5 quả bóng rổ, thêm 3 quả là mấy?", "chuoi": "🏀 🏀 🏀 🏀 🏀  +  🏀 🏀 🏀  =  ?", "dapAn": 8, "luaChon": [7, 8], "sai": "Gợi ý: 5 thêm 3 đơn vị nữa là mấy nhỉ?", "dung": "Thông minh quá! 5 cộng 3 bằng 8 quả bóng!"},
{"moTa": "Có 4 con chim, thêm 4 con chim là mấy?", "chuoi": "🐦 🐦 🐦 🐦  +  🐦 🐦 🐦 🐦  =  ?", "dapAn": 8, "luaChon": [8, 9], "sai": "Gợi ý: Gộp 4 con với 4 con lại với nhau nào!", "dung": "Đúng rồi! 4 cộng 4 bằng 8 chú chim!"},
{"moTa": "Có 7 ngôi sao, thêm 1 ngôi sao là mấy?", "chuoi": "⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐  +  ⭐  =  ?", "dapAn": 8, "luaChon": [7, 8], "sai": "Gợi ý: Đếm tiếp số 7 thêm 1 bước là ra nhé!", "dung": "Xuất sắc! 7 cộng 1 bằng 8 ngôi sao!"},
{"moTa": "Có 6 chú khủng long, thêm 2 chú là mấy?", "chuoi": "🦖 🦖 🦖 🦖 🦖 🦖  +  🦖 🦖  =  ?", "dapAn": 8, "luaChon": [8, 9], "sai": "Gợi ý: 6 cộng thêm 2 bước tiến nữa nào!", "dung": "Tuyệt vời! 6 cộng 2 bằng 8 chú khủng long!"},
{"moTa": "Có 5 chú ong vàng, thêm 4 chú là mấy?", "chuoi": "🐝 🐝 🐝 🐝 🐝  +  🐝 🐝 🐝 🐝  =  ?", "dapAn": 9, "luaChon": [8, 9], "sai": "Gợi ý: 5 thêm 4 đơn vị là mấy bé nhỉ?", "dung": "Quá giỏi! 5 cộng 4 bằng 9 chú ong!"},
{"moTa": "Có 7 quả lê, thêm 2 quả lê là mấy?", "chuoi": "🍐 🍐 🍐 🍐 🍐 🍐 🍐  +  🍐 🍐  =  ?", "dapAn": 9, "luaChon": [9, 10], "sai": "Gợi ý: Đếm tiếp từ số 7 thêm 2 bước nữa nhé!", "dung": "Chính xác! 7 cộng 2 bằng 9 quả lê!"},
{"moTa": "Có 6 quả bóng bàn, thêm 3 quả là mấy?", "chuoi": "🎾 🎾 🎾 🎾 🎾 🎾  +  🎾 🎾 🎾  =  ?", "dapAn": 9, "luaChon": [8, 9], "sai": "Gợi ý: 6 thêm 3 đơn vị nữa là mấy nào?", "dung": "Siêu nhân! 6 cộng 3 bằng 9 quả bóng bàn!"},
{"moTa": "Có 5 quả táo đỏ, thêm 5 quả là mấy?", "chuoi": "🍎 🍎 🍎 🍎 🍎  +  🍎 🍎 🍎 🍎 🍎  =  ?", "dapAn": 10, "luaChon": [9, 10], "sai": "Gợi ý: 5 ngón tay thêm 5 ngón tay là mấy nào?", "dung": "Quá đỉnh chóp! 5 cộng 5 bằng 10 quả táo!"},
{"moTa": "Có 7 chú cún con, thêm 3 chú là mấy?", "chuoi": "🐶 🐶 🐶 🐶 🐶 🐶 🐶  +  🐶 🐶 🐶  =  ?", "dapAn": 10, "luaChon": [9, 10], "sai": "Gợi ý: Đếm tiếp từ số 7 thêm 3 bước nhé bé!", "dung": "Xuất sắc! 7 cộng 3 bằng 10 chú cún!"},
{"moTa": "Có 8 quả bóng đá, thêm 2 quả là mấy?", "chuoi": "⚽ ⚽ ⚽ ⚽ ⚽ ⚽ ⚽ ⚽  +  ⚽ ⚽  =  ?", "dapAn": 10, "luaChon": [9, 10], "sai": "Gợi ý: Số liền sau số 9 là số mấy nhỉ?", "dung": "Quá siêu phàm! 8 cộng 2 bằng 10 quả bóng!"},
{"moTa": "Có 4 chú mèo, thêm 6 chú mèo là mấy?", "chuoi": "🐱 🐱 🐱 🐱  +  🐱 🐱 🐱 🐱 🐱 🐱  =  ?", "dapAn": 10, "luaChon": [10, 11], "sai": "Gợi ý: 4 thêm 6 đơn vị nữa là số lớn nhất có 1 chữ số đấy!", "dung": "Chính xác tuyệt đối! 4 cộng 6 bằng 10 chú mèo!"},
{"moTa": "Có 6 viên kẹo trái cây, thêm 4 viên là mấy?", "chuoi": "🍬 🍬 🍬 🍬 🍬 🍬  +  🍬 🍬 🍬 🍬  =  ?", "dapAn": 10, "luaChon": [9, 10], "sai": "Gợi ý: 6 thêm 4 bước đếm nữa nào bé ơi!", "dung": "Hoan hô bé! 6 cộng 4 bằng 10 viên kẹo!"},
{"moTa": "Có 8 bông hoa hồng, thêm 1 bông là mấy?", "chuoi": "🌸 🌸 🌸 🌸 🌸 🌸 🌸 🌸  +  🌸  =  ?", "dapAn": 9, "luaChon": [8, 9], "sai": "Gợi ý: Đếm tiếp số 8 thêm 1 bước nhé!", "dung": "Giỏi quá! 8 cộng 1 bằng 9 bông hoa!"},
{"moTa": "Có 3 chú cá heo, thêm 5 chú là mấy?", "chuoi": "🐬 🐬 🐬  +  🐬 🐬 🐬 🐬 🐬  =  ?", "dapAn": 8, "luaChon": [7, 8], "sai": "Gợi ý: 3 thêm 5 đơn vị là mấy nào?", "dung": "Đúng rồi! 3 cộng 5 bằng 8 chú cá heo!"},
{"moTa": "Có 9 chiếc lá xanh, thêm 1 chiếc là mấy?", "chuoi": "🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃  +  🍃  =  ?", "dapAn": 10, "luaChon": [9, 10], "sai": "Gợi ý: 9 thêm 1 là số tròn chục đầu tiên!", "dung": "Xuất sắc! 9 cộng 1 bằng 10 chiếc lá!"},
{"moTa": "Có 2 chiếc máy bay, thêm 6 chiếc là mấy?", "chuoi": "✈️ ✈️  +  ✈️ ✈️ ✈️ ✈️ ✈️ ✈️  =  ?", "dapAn": 8, "luaChon": [7, 8], "sai": "Gợi ý: 2 cộng thêm 6 bước nữa nhé bé!", "dung": "Tuyệt đỉnh! 2 cộng 6 bằng 8 chiếc máy bay!"},
{"moTa": "Có 5 quả dâu tây, thêm 4 quả là mấy?", "chuoi": "🍓 🍓 🍓 🍓 🍓  +  🍓 🍓 🍓 🍓  =  ?", "dapAn": 9, "luaChon": [8, 9], "sai": "Gợi ý: Đếm gộp 5 và 4 lại với nhau nào!", "dung": "Quá thông minh! 5 cộng 4 bằng 9 quả dâu tây!"},
{"moTa": "Có 4 quả táo, ăn mất 1 quả còn lại mấy?", "chuoi": "🍎 🍎 🍎 🍎  ➖  🍎 (ăn)  =  ?", "dapAn": 3, "luaChon": [2, 3], "sai": "Gợi ý: 4 bớt đi 1 quả thì còn lại bao nhiêu?", "dung": "Đúng rồi! 4 trừ 1 còn lại 3 quả táo!"},
{"moTa": "Có 5 chiếc kẹo, cho đi 2 chiếc còn mấy?", "chuoi": "🍬 🍬 🍬 🍬 🍬  ➖  🍬 🍬 (cho)  =  ?", "dapAn": 3, "luaChon": [3, 4], "sai": "Gợi ý: Lấy 5 bớt đi 2 viên kẹo nhé!", "dung": "Quá thông minh! 5 trừ 2 bằng 3 viên kẹo!"},
{"moTa": "Có 3 chú chim, bay đi 1 chú còn mấy?", "chuoi": "🐦 🐦 🐦  ➖  🐦 (bay)  =  ?", "dapAn": 2, "luaChon": [1, 2], "sai": "Gợi ý: 3 chú chim bay mất 1 chú thì còn mấy?", "dung": "Tuyệt đỉnh! 3 trừ 1 còn lại 2 chú chim!"},
{"moTa": "Có 4 bông hoa, héo mất 2 bông còn mấy?", "chuoi": "🌻 🌻 🌻 🌻  ➖  🌻 🌻 (héo)  =  ?", "dapAn": 2, "luaChon": [2, 3], "sai": "Gợi ý: 4 bớt đi 2 bông hoa nhé bé!", "dung": "Chính xác! 4 trừ 2 còn lại 2 bông hoa!"},
{"moTa": "Có 6 quả bóng, làm vỡ 2 quả còn mấy?", "chuoi": "⚽ ⚽ ⚽ ⚽ ⚽ ⚽  ➖  ⚽ ⚽ (vỡ)  =  ?", "dapAn": 4, "luaChon": [4, 5], "sai": "Gợi ý: Lấy 6 trừ đi 2 quả bóng bị vỡ nào!", "dung": "Quá xuất sắc! 6 trừ 2 bằng 4 quả bóng!"},
{"moTa": "Có 5 chú vịt, nhảy xuống nước 3 chú còn mấy?", "chuoi": "🦆 🦆 🦆 🦆 🦆  ➖  🦆 🦆 🦆 (xuống nước)  =  ?", "dapAn": 2, "luaChon": [2, 3], "sai": "Gợi ý: 5 bớt đi 3 chú vịt ở trên bờ nhé!", "dung": "Tuyệt vời! 5 trừ 3 còn lại 2 chú vịt!"},
{"moTa": "Có 7 chiếc sao, vụt tắt 2 chiếc còn mấy?", "chuoi": "⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐  ➖  ⭐ ⭐ (tắt)  =  ?", "dapAn": 5, "luaChon": [4, 5], "sai": "Gợi ý: 7 bớt đi 2 ngôi sao chiếu sáng!", "dung": "Quá thông minh! 7 trừ 2 bằng 5 ngôi sao!"},
{"moTa": "Có 6 chiếc bánh, bé ăn 3 chiếc còn mấy?", "chuoi": "🍰 🍰 🍰 🍰 🍰 🍰  ➖  🍰 🍰 🍰 (ăn)  =  ?", "dapAn": 3, "luaChon": [3, 4], "sai": "Gợi ý: Lấy 6 bớt đi 3 chiếc bánh đã ăn nhé!", "dung": "Chính xác tuyệt đối! 6 trừ 3 bằng 3 chiếc bánh!"},
{"moTa": "Có 8 quả bóng bay, bị tuột mất 3 quả còn mấy?", "chuoi": "🎈 🎈 🎈 🎈 🎈 🎈 🎈 🎈  ➖  🎈 🎈 🎈 (tuột)  =  ?", "dapAn": 5, "luaChon": [5, 6], "sai": "Gợi ý: 8 bớt đi 3 quả bay mất nào bé!", "dung": "Xuất sắc! 8 trừ 3 còn lại 5 quả bóng bay!"},
{"moTa": "Có 9 chú cún, chạy đi 4 chú còn mấy?", "chuoi": "🐶 🐶 🐶 🐶 🐶 🐶 🐶 🐶 🐶  ➖  🐶 🐶 🐶 🐶 (chạy)  =  ?", "dapAn": 5, "luaChon": [4, 5], "sai": "Gợi ý: Lấy 9 trừ đi 4 chú cún chạy đi nhé!", "dung": "Quá đỉnh chóp! 9 trừ 4 bằng 5 chú cún!"},
{"moTa": "Có 5 quả cam, thêm 4 quả cam là mấy?", "chuoi": "🍊 🍊 🍊 🍊 🍊  +  🍊 🍊 🍊 🍊  =  ?", "dapAn": 9, "luaChon": [8, 9], "sai": "Gợi ý: 5 cộng thêm 4 đơn vị nữa nhé bé!", "dung": "Tuyệt đỉnh! 5 cộng 4 bằng 9 quả cam!"},
{"moTa": "Có 6 quả dâu tây, thêm 3 quả là mấy?", "chuoi": "🍓 🍓 🍓 🍓 🍓 🍓  +  🍓 🍓 🍓  =  ?", "dapAn": 9, "luaChon": [9, 10], "sai": "Gợi ý: 6 cộng thêm 3 bước đếm tiến nữa nào!", "dung": "Quá thông minh! 6 cộng 3 bằng 9 quả dâu!"},
{"moTa": "Có 7 chú gà, thêm 2 chú gà là mấy?", "chuoi": "🐔 🐔 🐔 🐔 🐔 🐔 🐔  +  🐔 🐔  =  ?", "dapAn": 9, "luaChon": [8, 9], "sai": "Gợi ý: Đếm tiếp 2 số nữa từ số 7 nhé!", "dung": "Xuất sắc! 7 cộng 2 bằng 9 chú gà!"},
{"moTa": "Có 4 quả lê, thêm 5 quả lê là mấy?", "chuoi": "🍐 🍐 🍐 🍐  +  🍐 🍐 🍐 🍐 🍐  =  ?", "dapAn": 9, "luaChon": [9, 10], "sai": "Gợi ý: 4 cộng thêm 5 đơn vị tổng cộng là mấy?", "dung": "Tuyệt vời! 4 cộng 5 bằng 9 quả lê!"},
{"moTa": "Có 5 chú khỉ, thêm 5 chú khỉ là mấy?", "chuoi": "🐵 🐵 🐵 🐵 🐵  +  🐵 🐵 🐵 🐵 🐵  =  ?", "dapAn": 10, "luaChon": [9, 10], "sai": "Gợi ý: 5 cộng 5 là số chẵn tròn chục quen thuộc!", "dung": "Quá đỉnh! 5 cộng 5 bằng 10 chú khỉ!"},
{"moTa": "Có 8 quả chuối, ăn mất 3 quả còn mấy?", "chuoi": "🍌 🍌 🍌 🍌 🍌 🍌 🍌 🍌  ➖  🍌 🍌 🍌 (ăn)  =  ?", "dapAn": 5, "luaChon": [5, 6], "sai": "Gợi ý: Lấy 8 bớt đi 3 quả chuối nhé!", "dung": "Chính xác tuyệt đối! 8 trừ 3 bằng 5 quả chuối!"},
{"moTa": "Có 9 chiếc lá, rụng mất 4 chiếc còn mấy?", "chuoi": "🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃  ➖  🍃 🍃 🍃 🍃 (rụng)  =  ?", "dapAn": 5, "luaChon": [5, 6], "sai": "Gợi ý: 9 bớt đi 4 chiếc lá rơi rụng nào!", "dung": "Tuyệt đỉnh! 9 trừ 4 còn lại 5 chiếc lá!"},
{"moTa": "Có 10 quả bóng, xì hơi 3 quả còn mấy?", "chuoi": "⚽ ⚽ ⚽ ⚽ ⚽ ⚽ ⚽ ⚽ ⚽ ⚽  ➖  ⚽ ⚽ ⚽ (xì hơi)  =  ?", "dapAn": 7, "luaChon": [6, 7], "sai": "Gợi ý: Lấy 10 trừ đi 3 quả bóng bị xì hơi nhé!", "dung": "Quá xuất sắc! 10 trừ 3 bằng 7 quả bóng!"},
{"moTa": "Có 7 bông hoa, héo mất 4 bông còn mấy?", "chuoi": "🌸 🌸 🌸 🌸 🌸 🌸 🌸  ➖  🌸 🌸 🌸 🌸 (héo)  =  ?", "dapAn": 3, "luaChon": [3, 4], "sai": "Gợi ý: 7 bớt đi 4 bông hoa không tươi nữa!", "dung": "Hoan hô bé! 7 trừ 4 còn lại 3 bông hoa!"},
{"moTa": "Có 10 viên bi, làm mất 5 viên còn mấy?", "chuoi": "🔵 🔵 🔵 🔵 🔵 🔵 🔵 🔵 🔵 🔵  ➖  🔵 🔵 🔵 🔵 🔵 (mất)  =  ?", "dapAn": 5, "luaChon": [5, 6], "sai": "Gợi ý: Một nửa của 10 là mấy nhỉ bé?", "dung": "Tuyệt vời! 10 trừ 5 bằng 5 viên bi hoàn hảo!"},
{"moTa": "Có 6 chú ếch, nhảy xuống ao 2 chú còn mấy?", "chuoi": "🐸 🐸 🐸 🐸 🐸 🐸  ➖  🐸 🐸 (nhảy)  =  ?", "dapAn": 4, "luaChon": [3, 4], "sai": "Gợi ý: Lấy 6 chú ếch bớt đi 2 chú nhảy xuống ao nhé!", "dung": "Giỏi quá! 6 trừ 2 còn lại 4 chú ếch!"},
{"moTa": "Có 7 chiếc kẹo dẻo, bé ăn 3 chiếc còn mấy?", "chuoi": "🍬 🍬 🍬 🍬 🍬 🍬 🍬  ➖  🍬 🍬 🍬 (ăn)  =  ?", "dapAn": 4, "luaChon": [4, 5], "sai": "Gợi ý: 7 bớt đi 3 viên kẹo đã ăn nào bé!", "dung": "Chính xác! 7 trừ 3 còn lại 4 viên kẹo!"},
{"moTa": "Có 8 quả bóng bay, bay đi 2 quả còn mấy?", "chuoi": "🎈 🎈 🎈 🎈 🎈 🎈 🎈 🎈  ➖  🎈 🎈 (bay)  =  ?", "dapAn": 6, "luaChon": [5, 6], "sai": "Gợi ý: 8 bớt đi 2 quả bay lên trời nhé!", "dung": "Xuất sắc! 8 trừ 2 bằng 6 quả bóng bay!"},
{"moTa": "Có 6 chiếc bút chì, gãy mất 1 chiếc còn mấy?", "chuoi": "✏️ ✏️ ✏️ ✏️ ✏️ ✏️  ➖  ✏️ (gãy)  =  ?", "dapAn": 5, "luaChon": [4, 5], "sai": "Gợi ý: Số liền trước số 6 là số mấy nào?", "dung": "Quá siêu! 6 trừ 1 còn lại 5 cái bút chì!"},
{"moTa": "Có 9 ngôi sao trên trời, mây che mất 3 ngôi còn mấy?", "chuoi": "⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐  ➖  ⭐ ⭐ ⭐ (che)  =  ?", "dapAn": 6, "luaChon": [6, 7], "sai": "Gợi ý: Lấy 9 bớt đi 3 ngôi sao bị che khuất nhé!", "dung": "Tuyệt vời! 9 trừ 3 bằng 6 ngôi sao!"},
{"moTa": "Có 7 con cá bơi lội, bơi đi mất 3 con còn mấy?", "chuoi": "🐠 🐠 🐠 🐠 🐠 🐠 🐠  ➖  🐠 🐠 🐠 (bơi đi)  =  ?", "dapAn": 4, "luaChon": [3, 4], "sai": "Gợi ý: 7 bớt đi 3 chú cá bơi đi xa nào!", "dung": "Thông minh quá! 7 trừ 3 còn 4 chú cá!"},
{"moTa": "Có 8 chiếc xe ô tô, chạy đi 4 chiếc còn mấy?", "chuoi": "🚗 🚗 🚗 🚗 🚗 🚗 🚗 🚗  ➖  🚗 🚗 🚗 🚗 (chạy)  =  ?", "dapAn": 4, "luaChon": [4, 5], "sai": "Gợi ý: Một nửa của 8 là mấy nhỉ bé ơi?", "dung": "Hoan hô bé! 8 trừ 4 bằng 4 chiếc xe!"},
{"moTa": "Có 6 bông hoa hướng dương, cắm vào bình 4 bông còn mấy?", "chuoi": "🌻 🌻 🌻 🌻 🌻 🌻  ➖  🌻 🌻 🌻 🌻 (cắm bình)  =  ?", "dapAn": 2, "luaChon": [2, 3], "sai": "Gợi ý: Lấy 6 trừ đi 4 bông hoa đã hái nhé!", "dung": "Chính xác tuyệt đối! 6 trừ 4 còn 2 bông hoa!"},
{"moTa": "Có 9 quả dâu tây, bé tặng mẹ 5 quả còn mấy?", "chuoi": "🍓 🍓 🍓 🍓 🍓 🍓 🍓 🍓 🍓  ➖  🍓 🍓 🍓 🍓 🍓 (tặng)  =  ?", "dapAn": 4, "luaChon": [4, 5], "sai": "Gợi ý: 9 bớt đi 5 quả dâu mang tặng nào!", "dung": "Quá đỉnh! 9 trừ 5 còn lại 4 quả dâu!"},
{"moTa": "Có 8 chiếc áo khoác, cất đi 3 chiếc còn mấy?", "chuoi": "🧥 🧥 🧥 🧥 🧥 🧥 🧥 🧥  ➖  🧥 🧥 🧥 (cất)  =  ?", "dapAn": 5, "luaChon": [4, 5], "sai": "Gợi ý: 8 bớt đi 3 chiếc áo khoác nhé bé!", "dung": "Tuyệt đỉnh! 8 trừ 3 bằng 5 chiếc áo!"},
{"moTa": "Có 10 quả trứng, nở thành gà con 4 quả còn mấy?", "chuoi": "🥚 🥚 🥚 🥚 🥚 🥚 🥚 🥚 🥚 🥚  ➖  🥚 🥚 🥚 🥚 (nở)  =  ?", "dapAn": 6, "luaChon": [5, 6], "sai": "Gợi ý: Lấy 10 trừ đi 4 quả trứng đã nở thành gà!", "dung": "Xuất sắc! 10 trừ 4 còn lại 6 quả trứng!"},
{"moTa": "Có 10 cái bánh quy, bé ăn mất 4 cái còn mấy?", "chuoi": "🍪 🍪 🍪 🍪 🍪 🍪 🍪 🍪 🍪 🍪  ➖  🍪 🍪 🍪 🍪 (ăn)  =  ?", "dapAn": 6, "luaChon": [6, 7], "sai": "Gợi ý: 10 bớt đi 4 chiếc bánh quy ngon tuyệt nhé!", "dung": "Quá thông minh! 10 trừ 4 bằng 6 chiếc bánh!"},
{"moTa": "Có 9 chú thỏ trắng, nhảy vào hang 6 chú còn mấy?", "chuoi": "🐰 🐰 🐰 🐰 🐰 🐰 🐰 🐰 🐰  ➖  🐰 🐰 🐰 🐰 🐰 🐰 (vào hang)  =  ?", "dapAn": 3, "luaChon": [3, 4], "sai": "Gợi ý: 9 bớt đi 6 chú thỏ đã trốn vào hang!", "dung": "Giỏi lắm! 9 trừ 6 còn lại 3 chú thỏ!"},
{"moTa": "Có 10 chú chim sẻ, bay đi 7 chú còn mấy?", "chuoi": "🐦 🐦 🐦 🐦 🐦 🐦 🐦 🐦 🐦 🐦  ➖  🐦 🐦 🐦 🐦 🐦 🐦 🐦 (bay)  =  ?", "dapAn": 3, "luaChon": [2, 3], "sai": "Gợi ý: 10 bớt đi 7 chú chim bay đi mất nhé!", "dung": "Đúng rồi! 10 trừ 7 còn lại 3 chú chim!"},
{"moTa": "Có 9 quả bóng đá, bị xì hơi 5 quả còn mấy?", "chuoi": "⚽ ⚽ ⚽ ⚽ ⚽ ⚽ ⚽ ⚽ ⚽  ➖  ⚽ ⚽ ⚽ ⚽ ⚽ (xì hơi)  =  ?", "dapAn": 4, "luaChon": [4, 5], "sai": "Gợi ý: Lấy 9 trừ đi 5 quả bóng không căng nữa!", "dung": "Quá siêu! 9 trừ 5 còn lại 4 quả bóng!"},
{"moTa": "Có 10 chiếc kẹo mút, cho bạn 6 chiếc còn mấy?", "chuoi": "🍭 🍭 🍭 🍭 🍭 🍭 🍭 🍭 🍭 🍭  ➖  🍭 🍭 🍭 🍭 🍭 🍭 (cho)  =  ?", "dapAn": 4, "luaChon": [3, 4], "sai": "Gợi ý: 10 bớt đi 6 chiếc kẹo đã mang cho bạn!", "dung": "Tuyệt vời! 10 trừ 6 còn lại 4 viên kẹo!"},
{"moTa": "Có 8 quả chuối chín, khỉ con ăn 5 quả còn mấy?", "chuoi": "🍌 🍌 🍌 🍌 🍌 🍌 🍌 🍌  ➖  🍌 🍌 🍌 🍌 🍌 (ăn)  =  ?", "dapAn": 3, "luaChon": [3, 4], "sai": "Gợi ý: Lấy 8 bớt đi 5 quả chuối khỉ đã ăn nào!", "dung": "Chính xác tuyệt đối! 8 trừ 5 bằng 3 quả chuối!"},
{"moTa": "Có 10 chiếc lá vàng, gió thổi bay 8 chiếc còn mấy?", "chuoi": "🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃  ➖  🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 (bay)  =  ?", "dapAn": 2, "luaChon": [2, 3], "sai": "Gợi ý: 10 trừ đi 8 chiếc lá bị gió cuốn đi nhé!", "dung": "Xuất sắc! 10 trừ 8 còn lại 2 chiếc lá!"},
{"moTa": "Có 9 viên bi màu xanh, làm mất 6 viên còn mấy?", "chuoi": "🔵 🔵 🔵 🔵 🔵 🔵 🔵 🔵 🔵  ➖  🔵 🔵 🔵 🔵 🔵 🔵 (mất)  =  ?", "dapAn": 3, "luaChon": [3, 4], "sai": "Gợi ý: 9 bớt đi 6 viên bi không còn nữa!", "dung": "Quá đỉnh chóp! 9 trừ 6 bằng 3 viên bi!"},
{"moTa": "Có 10 bông hoa cúc, héo úa mất 5 bông còn mấy?", "chuoi": "🌼 🌼 🌼 🌼 🌼 🌼 🌼 🌼 🌼 🌼  ➖  🌼 🌼 🌼 🌼 🌼 (héo)  =  ?", "dapAn": 5, "luaChon": [5, 6], "sai": "Gợi ý: Một nửa của 10 bông hoa là mấy nào bé?", "dung": "Hoan hô bé! 10 trừ 5 còn lại 5 bông hoa tươi!"},
{"moTa": "Có 2 chú mèo, thêm 1 chú mèo là mấy?", "chuoi": "2 (🐱🐱) + 1 (🐱) = ?", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Bé đếm gộp tất cả các chú mèo lại nhé!", "dung": "Chính xác! 2 cộng 1 bằng 3 chú mèo!"},
{"moTa": "Có 3 quả táo, thêm 2 quả táo là mấy?", "chuoi": "3 (🍎🍎🍎) + 2 (🍎🍎) = ?", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: 3 quả thêm 2 quả nữa là mấy nào bé?", "dung": "Giỏi quá! 3 cộng 2 bằng 5 quả táo!"},
{"moTa": "Có 4 chú cún, thêm 1 chú cún là mấy?", "chuoi": "4 (🐶🐶🐶🐶) + 1 (🐶) = ?", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Đếm tiếp thêm 1 chú cún từ số 4 nhé!", "dung": "Tuyệt vời! 4 cộng 1 bằng 5 chú cún!"},
{"moTa": "Có 1 quả bóng, thêm 3 quả bóng là mấy?", "chuoi": "1 (⚽) + 3 (⚽⚽⚽) = ?", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: 1 thêm 3 đơn vị nữa là mấy nào?", "dung": "Đúng rồi! 1 cộng 3 bằng 4 quả bóng!"},
{"moTa": "Có 2 bông hoa, thêm 2 bông hoa là mấy?", "chuoi": "2 (🌸🌸) + 2 (🌸🌸) = ?", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Hai bông hoa thêm hai bông hoa là mấy nhỉ?", "dung": "Xuất sắc! 2 cộng 2 bằng 4 bông hoa!"},
{"moTa": "Có 5 viên kẹo, thêm 2 viên kẹo là mấy?", "chuoi": "5 (🍬🍬🍬🍬🍬) + 2 (🍬🍬) = ?", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Lấy 5 đếm tiến thêm 2 bước nữa nào!", "dung": "Quá thông minh! 5 cộng 2 bằng 7 viên kẹo!"},
{"moTa": "Có 4 quả dưa hấu, thêm 3 quả là mấy?", "chuoi": "4 (🍉🍉🍉🍉) + 3 (🍉🍉🍉) = ?", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: 4 quả thêm 3 quả nữa là mấy bé ơi?", "dung": "Hoan hô bé! 4 cộng 3 bằng 7 quả dưa hấu!"},
{"moTa": "Có 6 chiếc xe, thêm 2 chiếc xe là mấy?", "chuoi": "6 (🚗🚗🚗🚗🚗🚗) + 2 (🚗🚗) = ?", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Đếm gộp tất cả các chiếc xe lại nào!", "dung": "Quá đỉnh! 6 cộng 2 bằng 8 chiếc xe!"},
{"moTa": "Có 5 quả chuối, thêm 4 quả chuối là mấy?", "chuoi": "5 (🍌🍌🍌🍌🍌) + 4 (🍌🍌🍌🍌) = ?", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: 5 cộng thêm 4 đơn vị nữa nhé bé!", "dung": "Tuyệt đỉnh! 5 cộng 4 bằng 9 quả chuối!"},
{"moTa": "Có 5 chú ếch, thêm 5 chú ếch là mấy?", "chuoi": "5 (🐸🐸🐸🐸🐸) + 5 (🐸🐸🐸🐸🐸) = ?", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: 5 ngón tay thêm 5 ngón tay là số tròn chục nào?", "dung": "Chính xác tuyệt đối! 5 cộng 5 bằng 10 chú ếch!"},
{"moTa": "Có 4 quả táo, ăn mất 1 quả còn lại mấy?", "chuoi": "4 (🍎🍎🍎🍎) - 1 (🍎) = ?", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: 4 bớt đi 1 quả thì còn lại bao nhiêu?", "dung": "Đúng rồi! 4 trừ 1 còn lại 3 quả táo!"},
{"moTa": "Có 5 chiếc kẹo, cho đi 2 chiếc còn mấy?", "chuoi": "5 (🍬🍬🍬🍬🍬) - 2 (🍬🍬) = ?", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Lấy 5 bớt đi 2 viên kẹo nhé!", "dung": "Quá thông minh! 5 trừ 2 bằng 3 viên kẹo!"},
{"moTa": "Có 3 chú chim, bay đi 1 chú còn mấy?", "chuoi": "3 (🐦🐦🐦) - 1 (🐦) = ?", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: 3 chú chim bay mất 1 chú thì còn mấy?", "dung": "Tuyệt đỉnh! 3 trừ 1 còn lại 2 chú chim!"},
{"moTa": "Có 4 bông hoa, héo mất 2 bông còn mấy?", "chuoi": "4 (🌻🌻🌻🌻) - 2 (🌻🌻) = ?", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: 4 bớt đi 2 bông hoa nhé bé!", "dung": "Chính xác! 4 trừ 2 còn lại 2 bông hoa!"},
{"moTa": "Có 6 quả bóng, làm vỡ 2 quả còn mấy?", "chuoi": "6 (⚽⚽⚽⚽⚽⚽) - 2 (⚽⚽) = ?", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Lấy 6 trừ đi 2 quả bóng bị vỡ nào!", "dung": "Quá xuất sắc! 6 trừ 2 bằng 4 quả bóng!"},
{"moTa": "Có 6 viên kẹo, bé ăn 3 viên còn mấy?", "chuoi": "6 (🍰🍰🍰🍰🍰🍰) - 3 (🍰🍰🍰) = ?", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Lấy 6 bớt đi 3 chiếc bánh đã ăn nhé!", "dung": "Chính xác tuyệt đối! 6 trừ 3 bằng 3 chiếc bánh!"},
{"moTa": "Có 8 quả bóng bay, bay đi 2 quả còn mấy?", "chuoi": "8 (🎈🎈🎈🎈🎈🎈🎈🎈) - 2 (🎈🎈) = ?", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: 8 bớt đi 2 quả bay lên trời nhé!", "dung": "Xuất sắc! 8 trừ 2 bằng 6 quả bóng bay!"},
{"moTa": "Có 9 chú cún, chạy đi 4 chú còn mấy?", "chuoi": "9 (🐶🐶🐶🐶🐶🐶🐶🐶🐶) - 4 (🐶🐶🐶🐶) = ?", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Lấy 9 trừ đi 4 chú cún chạy đi nhé!", "dung": "Quá đỉnh chóp! 9 trừ 4 bằng 5 chú cún!"},
{"moTa": "Có 8 quả chuối, khỉ con ăn 3 quả còn mấy?", "chuoi": "8 (🍌🍌🍌🍌🍌🍌🍌🍌) - 3 (🍌🍌🍌) = ?", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Lấy 8 bớt đi 3 quả chuối nhé!", "dung": "Tuyệt vời! 8 trừ 3 bằng 5 quả chuối!"},
{"moTa": "Có 10 cái bánh quy, bé ăn mất 4 cái còn mấy?", "chuoi": "10 (🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪) - 4 (🍪🍪🍪🍪) = ?", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: con có 10 cái bánh cho đi 4 chiếc cái nhé!", "dung": "Quá thông minh! 10 trừ 4 bằng 6 chiếc bánh!"}
  ];
  @override
  void initState() {
    super.initState();
    // Cài đặt trực tiếp không dùng await
    flutterTts.setLanguage("vi-VN");
    flutterTts.setSpeechRate(0.5);
    // Khởi tạo ngay lập tức dữ liệu để các biến late có giá trị trước khi build()
    _taiLaiDanhSachNgauNhien();
    // Gán trực tiếp giá trị cho các biến late (không dùng setState ở đây)
    if (_danhSachChiSoChuaDung.isNotEmpty) {
      _currentIndex = _danhSachChiSoChuaDung.removeAt(0);
      final item = _khoCongTru[_currentIndex];
      cauHoiMoTa = item["moTa"];
      chuoiHienThi = item["chuoi"];
      dapAnDung = item["dapAn"];
      danhSachLuaChon = List<int>.from(item["luaChon"]);
      goiYSai = item["sai"];
      goiYDung = item["dung"];
      _thongBaoTrangThai = "";
    }
    // Đọc âm thanh sau khi khởi tạo xong
    flutterTts.speak(cauHoiMoTa);
  }
  // Hàm _taoThuThachMoi dùng khi chuyển câu hỏi tiếp theo (giữ nguyên setState ở đây vì lúc này widget đã build xong xuôi)
  void _taoThuThachMoi() {
    if (_danhSachChiSoChuaDung.isEmpty) {
      _taiLaiDanhSachNgauNhien();
    }
    _currentIndex = _danhSachChiSoChuaDung.removeAt(0);
    final item = _khoCongTru[_currentIndex];
    setState(() {
      cauHoiMoTa = item["moTa"];
      chuoiHienThi = item["chuoi"];
      dapAnDung = item["dapAn"];
      danhSachLuaChon = List<int>.from(item["luaChon"]);
      goiYSai = item["sai"];
      goiYDung = item["dung"];
      _thongBaoTrangThai = "";
    });
    flutterTts.speak(cauHoiMoTa);
  }
  void _taiLaiDanhSachNgauNhien() {
    _danhSachChiSoChuaDung.clear();
    for (int i = 0; i < _khoCongTru.length; i++) {
      _danhSachChiSoChuaDung.add(i);
    }
    _danhSachChiSoChuaDung.shuffle(_random);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFA),
      appBar: AppBar(
        title: const Text("Phép Cộng Trừ Trực Quan"),
        backgroundColor: const ui.Color.fromARGB(141, 64, 255, 207),
        // 👇 Đã thêm nút quay lại tròn viền vàng vào đây
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF5C4033), // Màu nâu
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cauHoiMoTa,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orangeAccent, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.orange.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Text(
                  chuoiHienThi,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 5),
              // Hiển thị gợi ý trực tiếp ngay trên giao diện khi bé chọn sai
              if (_thongBaoTrangThai.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    _thongBaoTrangThai,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Text("Bé hãy chọn đáp án đúng bên dưới:",
                  style: TextStyle(fontSize:0, color: Colors.black54)),
              const SizedBox(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: danhSachLuaChon.map((so) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (so == dapAnDung) {
                          flutterTts.speak(goiYDung);
                          _hienThongBaoDung(
                              context, "🎉 Bé giỏi quá!", goiYDung);
                        } else {
                          flutterTts.speak(goiYSai);
                          // Khi sai: không hiện popup, đọc giọng đọc và hiện text gợi ý ngay trên màn hình để bé tự chọn lại
                          setState(() {
                            _thongBaoTrangThai = goiYSai;
                          });
                        }
                      },
                      child: Text("$so",
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 0),
              TextButton.icon(
                onPressed: () => flutterTts.speak(cauHoiMoTa),
                icon: const Icon(Icons.volume_up, color: Colors.deepOrange),
                label: const Text("Nghe lại câu hỏi",
                    style: TextStyle(color: Colors.deepOrange, fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Chỉ bật hộp thoại popup khi bé trả lời ĐÚNG để khen ngợi và tự chuyển câu sau 3.5 giây
  void _hienThongBaoDung(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (Navigator.canPop(c)) {
            Navigator.pop(c);
            _taoThuThachMoi();
          }
        });
        return AlertDialog(
          title: Text(title),
          content: Text(msg, style: const TextStyle(fontSize: 14)),
        );
      },
    );
  }
}

//TRANG KHÁC BIỆT
class TrangKhacBiet extends StatefulWidget {
  const TrangKhacBiet({super.key});
  @override
  State<TrangKhacBiet> createState() => _TrangKhacBietState();
}
class _TrangKhacBietState extends State<TrangKhacBiet> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  String cauHoiMoTa = "Đang chuẩn bị câu hỏi...";
  List<Map<String, dynamic>> danhSachLuaChon = [];
  String _thongBaoTrangThai = "";
  final List<int> _danhSachChiSoChuaDung = [];
  int _currentIndex = -1;
  final List<Map<String, dynamic>> _khoKhacBiet = [
    // CHỦ ĐỀ 1: ĐỘNG VẬT & PHƯƠNG TIỆN
    {
      "moTa": "Hình nào khác biệt so với nhóm còn lại?",
      "luaChon": [
        {
          "icon": "🐶",
          "dung": false,
          "thongBao": "Đây là chú chó quen thuộc, hãy tìm hình khác loại nhé!"
        },
        {
          "icon": "🐶",
          "dung": false,
          "thongBao": "Đây là chú chó quen thuộc, hãy tìm hình khác loại nhé!"
        },
        {
          "icon": "🚗",
          "dung": true,
          "thongBao": "Ô tô là phương tiện giao thông, không phải con vật!"
        },
      ]
    },
    {
      "moTa": "Tìm hình không cùng nhóm động vật nào bé ơi!",
      "luaChon": [
        {
          "icon": "🐱",
          "dung": false,
          "thongBao": "Chú mèo ở trong nhóm động vật đấy, thử lại nhé!"
        },
        {
          "icon": "✈️",
          "dung": true,
          "thongBao": "Máy bay lượn trên bầu trời, không phải con vật!"
        },
        {
          "icon": "🐱",
          "dung": false,
          "thongBao": "Chú mèo ở trong nhóm động vật đấy, thử lại nhé!"
        },
      ]
    },
    {
      "moTa": "Hình nào là đồ vật chứ không phải con vật?",
      "luaChon": [
        {
          "icon": "🐰",
          "dung": false,
          "thongBao": "Chú thỏ là động vật đáng yêu, chọn hình khác nhé!"
        },
        {
          "icon": "⚽",
          "dung": true,
          "thongBao": "Quả bóng là đồ chơi, khác biệt hoàn toàn!"
        },
        {
          "icon": "🐰",
          "dung": false,
          "thongBao": "Chú thỏ là động vật đáng yêu, chọn hình khác nhé!"
        },
      ]
    },
    {
      "moTa": "Đâu là hình chiếc tàu thủy lạc loài?",
      "luaChon": [
        {
          "icon": "🐟",
          "dung": false,
          "thongBao": "Con cá sống dưới nước, không phải tàu thuyền!"
        },
        {
          "icon": "🚢",
          "dung": true,
          "thongBao": "Tàu thủy là phương tiện đi trên biển!"
        },
        {
          "icon": "🐟",
          "dung": false,
          "thongBao": "Con cá sống dưới nước, không phải tàu thuyền!"
        },
      ]
    },
    {
      "moTa": "Hình nào khác biệt trong các phương tiện?",
      "luaChon": [
        {
          "icon": "🚲",
          "dung": false,
          "thongBao": "Xe đạp có bánh xe di chuyển trên đường đấy!"
        },
        {
          "icon": "🐘",
          "dung": true,
          "thongBao": "Con voi to lớn là động vật rừng xanh!"
        },
        {
          "icon": "🚲",
          "dung": false,
          "thongBao": "Xe đạp có bánh xe di chuyển trên đường đấy!"
        },
      ]
    },

    // CHỦ ĐỀ 2: TRÁI CÂY & ĐỒ ĂN
    {
      "moTa": "Trái cây nào khác loại với phần còn lại?",
      "luaChon": [
        {
          "icon": "🍎",
          "dung": false,
          "thongBao": "Quả táo là trái cây ngọt ngào quen thuộc!"
        },
        {
          "icon": "🏀",
          "dung": true,
          "thongBao": "Quả bóng rổ là đồ chơi thể thao, không ăn được!"
        },
        {
          "icon": "🍎",
          "dung": false,
          "thongBao": "Quả táo là trái cây ngọt ngào quen thuộc!"
        },
      ]
    },
    {
      "moTa": "Tìm món ăn hoặc vật dụng không phải trái cây!",
      "luaChon": [
        {
          "icon": "🍌",
          "dung": false,
          "thongBao": "Quả chuối thơm ngon bổ dưỡng thuộc nhóm hoa quả!"
        },
        {
          "icon": "🍌",
          "dung": false,
          "thongBao": "Quả chuối thơm ngon bổ dưỡng thuộc nhóm hoa quả!"
        },
        {
          "icon": "👕",
          "dung": true,
          "thongBao": "Chiếc áo mặc trên người, không phải trái cây!"
        },
      ]
    },
    {
      "moTa": "Đâu là hình chiếc kẹo ngọt lạc loài?",
      "luaChon": [
        {
          "icon": "🍓",
          "dung": false,
          "thongBao": "Quả dâu tây là trái cây tươi mát tự nhiên!"
        },
        {
          "icon": "🍓",
          "dung": false,
          "thongBao": "Quả dâu tây là trái cây tươi mát tự nhiên!"
        },
        {
          "icon": "🍬",
          "dung": true,
          "thongBao": "Viên kẹo ngọt là đồ ăn vặt chế biến!"
        },
      ]
    },
    {
      "moTa": "Hình nào không phải là rau củ quả?",
      "luaChon": [
        {
          "icon": "🥕",
          "dung": false,
          "thongBao": "Củ cà rốt tươi ngon thuộc nhóm rau củ!"
        },
        {
          "icon": "📱",
          "dung": true,
          "thongBao": "Điện thoại là thiết bị điện tử thông minh!"
        },
        {
          "icon": "🥕",
          "dung": false,
          "thongBao": "Củ cà rốt tươi ngon thuộc nhóm rau củ!"
        },
      ]
    },
    {
      "moTa": "Tìm vật thể không phải quả dưa hấu!",
      "luaChon": [
        {
          "icon": "🍉",
          "dung": false,
          "thongBao": "Quả dưa hấu mát lạnh mùa hè!"
        },
        {
          "icon": "🎒",
          "dung": true,
          "thongBao": "Chiếc cặp sách dùng để đi học!"
        },
        {
          "icon": "🍉",
          "dung": false,
          "thongBao": "Quả dưa hấu mát lạnh mùa hè!"
        },
      ]
    },

    // CHỦ ĐỀ 3: ĐỒ DÙNG HỌC TẬP & GIA ĐÌNH
    {
      "moTa": "Đồ vật nào khác biệt so với nhóm dụng cụ học tập?",
      "luaChon": [
        {
          "icon": "📖",
          "dung": false,
          "thongBao": "Quyển sách dùng để đọc chữ học bài!"
        },
        {
          "icon": "⚽",
          "dung": true,
          "thongBao": "Quả bóng đá dùng để đá sân thể thao!"
        },
        {
          "icon": "📖",
          "dung": false,
          "thongBao": "Quyển sách dùng để đọc chữ học bài!"
        },
      ]
    },
    {
      "moTa": "Tìm hình chiếc bút chì lạc loài nào!",
      "luaChon": [
        {
          "icon": "✏️",
          "dung": false,
          "thongBao": "Cái bút chì dùng để viết vẽ hằng ngày!"
        },
        {
          "icon": "🐔",
          "dung": true,
          "thongBao": "Con gà là động vật sống ở nông trại!"
        },
        {
          "icon": "✏️",
          "dung": false,
          "thongBao": "Cái bút chì dùng để viết vẽ hằng ngày!"
        },
      ]
    },
    {
      "moTa": "Hình nào không phải là đồ dùng học tập?",
      "luaChon": [
        {"icon": "🧹", "dung": true, "thongBao": "Cây chổi dùng để quyét nhà!"},
        {
          "icon": "📐",
          "dung": false,
          "thongBao": "Cục tẩy giúp xóa sạch nét vẽ sai!"
        },
        {
          "icon": "📐",
          "dung": false,
          "thongBao": "Cục tẩy giúp xóa sạch nét vẽ sai!"
        },
      ]
    },
    {
      "moTa": "Đâu là vật dụng không thuộc phòng học?",
      "luaChon": [
        {
          "icon": "🎒",
          "dung": false,
          "thongBao": "Cái cặp sách đựng sách vở của bé!"
        },
        {
          "icon": "🎒",
          "dung": false,
          "thongBao": "Cái cặp sách đựng sách vở của bé!"
        },
        {
          "icon": "🍦",
          "dung": true,
          "thongBao": "Cây kem mát lạnh ăn vào mùa hè!"
        },
      ]
    },
    // CHỦ ĐỀ 4: THIÊN NHIÊN & THỜI TIẾT
    {
      "moTa": "Hình nào khác biệt trong các hiện tượng tự nhiên?",
      "luaChon": [
        {
          "icon": "⭐",
          "dung": false,
          "thongBao": "Ngôi sao lấp lánh trên bầu trời đêm!"
        },
        {
          "icon": "🌂",
          "dung": true,
          "thongBao": "Chiếc ô che mưa khi trời bão giông!"
        },
        {
          "icon": "⭐",
          "dung": false,
          "thongBao": "Ngôi sao lấp lánh trên bầu trời đêm!"
        },
      ]
    },
    {
      "moTa": "Tìm hình bông hoa lạc loài nào bé yêu!",
      "luaChon": [
        {
          "icon": "🌸",
          "dung": false,
          "thongBao": "Bông hoa tươi thắm nở trong vườn!"
        },
        {
          "icon": "👟",
          "dung": true,
          "thongBao": "Chiếc giày dùng để đi chân cho ấm!"
        },
        {
          "icon": "🌸",
          "dung": false,
          "thongBao": "Bông hoa tươi thắm nở trong vườn!"
        },
      ]
    },
    {
      "moTa": "Hình nào không phải cây cối thiên nhiên?",
      "luaChon": [
        {
          "icon": "🌳",
          "dung": false,
          "thongBao": "Cây xanh tỏa bóng mát cho em!"
        },
        {
          "icon": "🕒",
          "dung": true,
          "thongBao": "Đồng hồ treo tường báo thời gian!"
        },
        {
          "icon": "🌳",
          "dung": false,
          "thongBao": "Cây xanh tỏa bóng mát cho em!"
        },
      ]
    },
    {
      "moTa": "Đâu là hình chú ong chăm chỉ khác biệt?",
      "luaChon": [
        {
          "icon": "🐝",
          "dung": false,
          "thongBao": "Chú ong nhỏ bay lượn hút mật hoa!"
        },
        {
          "icon": "🪑",
          "dung": true,
          "thongBao": "Cái ghế ngồi học bài của bé!"
        },
        {
          "icon": "🐝",
          "dung": false,
          "thongBao": "Chú ong nhỏ bay lượn hút mật hoa!"
        },
      ]
    },

    // CHỦ ĐỀ 5: ĐẢO VỊ TRÍ & TƯ DUY NÂNG CAO
    {
      "moTa": "Hình nào khác biệt (đứng ở vị trí khác)?",
      "luaChon": [
        {
          "icon": "⚽",
          "dung": true,
          "thongBao": "Quả bóng đá nằm lệch nhóm con vật!"
        },
        {
          "icon": "🐵",
          "dung": false,
          "thongBao": "Đây là chú khỉ đáng yêu trong nhóm!"
        },
        {
          "icon": "🐵",
          "dung": false,
          "thongBao": "Đây là chú khỉ đáng yêu trong nhóm!"
        },
      ]
    },
    {
      "moTa": "Tìm hình trái tim lạc loài nằm bên trái!",
      "luaChon": [
        {
          "icon": "💖",
          "dung": true,
          "thongBao": "Trái tim yêu thương nằm ở ô đầu tiên!"
        },
        {
          "icon": "⭐",
          "dung": false,
          "thongBao": "Ngôi sao vàng tỏa sáng rực rỡ!"
        },
        {
          "icon": "⭐",
          "dung": false,
          "thongBao": "Ngôi sao vàng tỏa sáng rực rỡ!"
        },
      ]
    },
    {
      "moTa": "Hình nào khác biệt ở giữa nhóm?",
      "luaChon": [
        {
          "icon": "🎈",
          "dung": false,
          "thongBao": "Quả bóng bay nhiều màu sắc vui nhộn!"
        },
        {
          "icon": "🦆",
          "dung": true,
          "thongBao": "Con vịt kêu cạp cạp nằm giữa!"
        },
        {
          "icon": "🎈",
          "dung": false,
          "thongBao": "Quả bóng bay nhiều màu sắc vui nhộn!"
        },
      ]
    },
    {
      "moTa": "Đâu là chiếc áo khác biệt so với nhóm quần áo?",
      "luaChon": [
        {"icon": "👕", "dung": false, "thongBao": "Cái áo mặc giữ ấm cơ thể!"},
        {
          "icon": "🚲",
          "dung": true,
          "thongBao": "Chiếc xe đạp không phải trang phục!"
        },
        {"icon": "👕", "dung": false, "thongBao": "Cái áo mặc giữ ấm cơ thể!"},
      ]
    },
    {
      "moTa": "Hình nào không cùng nhóm con vật với các bạn còn lại?",
      "luaChon": [
        {
          "icon": "🐷",
          "dung": false,
          "thongBao": "Chú lợn hồng ở trong nông trại đấy, tìm hình khác nhé!"
        },
        {
          "icon": "☂️",
          "dung": true,
          "thongBao": "Chiếc ô che mưa là đồ dùng, không phải động vật!"
        },
        {
          "icon": "🐷",
          "dung": false,
          "thongBao": "Chú lợn hồng ở trong nông trại đấy, tìm hình khác nhé!"
        }
      ]
    },
    {
      "moTa": "Đâu là chú cá khác biệt so với nhóm đồ vật?",
      "luaChon": [
        {
          "icon": "🥛",
          "dung": false,
          "thongBao": "Cái ly uống nước để ở bàn, chọn hình khác nào!"
        },
        {
          "icon": "🐟",
          "dung": true,
          "thongBao": "Chú cá bơi lội dưới nước, không phải đồ dùng!"
        },
        {
          "icon": "🥛",
          "dung": false,
          "thongBao": "Cái ly uống nước để ở bàn, chọn hình khác nào!"
        }
      ]
    },
    {
      "moTa": "Tìm hình chú gà con lạc loài nào bé ơi!",
      "luaChon": [
        {
          "icon": "⛑️",
          "dung": false,
          "thongBao":
              "Chiếc mũ bảo hiểm đội trên đầu khi đi xe không phải con vật!"
        },
        {
          "icon": "🐥",
          "dung": true,
          "thongBao": "Chú gà con là động vật có lông vàng đáng yêu!"
        },
        {
          "icon": "⛑️",
          "dung": false,
          "thongBao":
              "Chiếc mũ bảo hiểm đội trên đầu khi đi xe không phải con vật!"
        }
      ]
    },
    {
      "moTa": "Hình nào không phải là phương tiện giao thông?",
      "luaChon": [
        {
          "icon": "✈️",
          "dung": false,
          "thongBao": "Máy bay chở khách bay trên mây xanh!"
        },
        {
          "icon": "🐼",
          "dung": true,
          "thongBao": "Chú gấu trúc to lớn là động vật rừng xanh!"
        },
        {
          "icon": "✈️",
          "dung": false,
          "thongBao": "Máy bay chở khách bay trên mây xanh!"
        }
      ]
    },
    {
      "moTa": "Đâu là chiếc thuyền buồm lạc lõng giữa các con vật?",
      "luaChon": [
        {
          "icon": "🦀",
          "dung": false,
          "thongBao": "Chú cua nhỏ bò lổm ngổm trên bãi cát!"
        },
        {
          "icon": "⛵",
          "dung": true,
          "thongBao": "Thuyền buồm đi trên biển lớn!"
        },
        {
          "icon": "🦀",
          "dung": false,
          "thongBao": "Chú cua nhỏ bò lổm ngổm trên bãi cát!"
        }
      ]
    },
    {
      "moTa": "Món ăn nào khác loại với các loại quả?",
      "luaChon": [
        {
          "icon": "🍊",
          "dung": false,
          "thongBao": "Quả cam mọng nước giàu vitamin C!"
        },
        {
          "icon": "🔑",
          "dung": true,
          "thongBao": "Chiếc chìa khóa dùng để mở cửa nhà!"
        },
        {
          "icon": "🍊",
          "dung": false,
          "thongBao": "Quả cam mọng nước giàu vitamin C!"
        }
      ]
    },
    {
      "moTa": "tìm hình khác biệt ở 3 hình trên nào con!",
      "luaChon": [
        {
          "icon": "🍐",
          "dung": false,
          "thongBao": "Quả lê ngọt mát thuộc nhóm trái cây!"
        },
        {
          "icon": "🎂",
          "dung": true,
          "thongBao": "Bánh kem là món ngọt mừng sinh nhật!"
        },
        {
          "icon": "🍐",
          "dung": false,
          "thongBao": "Quả lê ngọt mát thuộc nhóm trái cây!"
        }
      ]
    },
    {
      "moTa": "Trái cây nào đứng cạnh chiếc đồng hồ lạc loài?",
      "luaChon": [
        {
          "icon": "🍍",
          "dung": false,
          "thongBao": "Quả dứa (thơm) có vỏ gai thơm ngon!"
        },
        {
          "icon": "⏰",
          "dung": true,
          "thongBao": "Đồng hồ treo tường báo thức giờ giấc!"
        },
        {
          "icon": "🍍",
          "dung": false,
          "thongBao": "Quả dứa (thơm) có vỏ gai thơm ngon!"
        }
      ]
    },
    {
      "moTa": "Đâu là đồ vật khác biệt so với rau củ?",
      "luaChon": [
        {
          "icon": "🍠",
          "dung": false,
          "thongBao": "Củ khoai lang ngọt bùi nằm dưới đất!"
        },
        {
          "icon": "🧋",
          "dung": true,
          "thongBao": "Ly trà sữa trân châu là thức uống giải khát!"
        },
        {
          "icon": "🍠",
          "dung": false,
          "thongBao": "Củ khoai lang ngọt bùi nằm dưới đất!"
        }
      ]
    },
    {
      "moTa": "Hình nào không phải là đồ ăn thức uống?",
      "luaChon": [
        {
          "icon": "🌽",
          "dung": false,
          "thongBao": "Bắp ngô ngọt luộc chín thơm lừng!"
        },
        {
          "icon": "🪮",
          "dung": true,
          "thongBao": "Chiếc lược để chải tóc mượt mà!"
        },
        {
          "icon": "🌽",
          "dung": false,
          "thongBao": "Bắp ngô ngọt luộc chín thơm lừng!"
        }
      ]
    },
    {
      "moTa": "Dụng cụ học tập nào khác biệt với chiếc giường?",
      "luaChon": [
        {
          "icon": "🖊️",
          "dung": false,
          "thongBao": "Cái bút mực để bé tập viết chữ đẹp!"
        },
        {
          "icon": "🛏️",
          "dung": true,
          "thongBao": "Giường ngủ để bé nằm mơ màng ban đêm!"
        },
        {
          "icon": "🖊️",
          "dung": false,
          "thongBao": "Cái bút mực để bé tập viết chữ đẹp!"
        }
      ]
    },
    {
      "moTa": "Tìm hình cái kéo cắt giấy lạc loài nào!",
      "luaChon": [
        {
          "icon": "🚪",
          "dung": true,
          "thongBao": "Cái tủ quần áo to lớn để cất đồ!"
        },
        {
          "icon": "✂️",
          "dung": false,
          "thongBao": "Cái kéo thủ công giúp cắt thủ công khéo léo!"
        },
        {
          "icon": "✂️",
          "dung": false,
          "thongBao": "Cái kéo thủ công giúp cắt thủ công khéo léo!"
        }
      ]
    },
    {
      "moTa": "Hình nào không phải đồ dùng trong phòng học?",
      "luaChon": [
        {
          "icon": "📏",
          "dung": false,
          "thongBao": "Thước kẻ giúp vẽ đường thẳng tắp!"
        },
        {
          "icon": "🚽",
          "dung": true,
          "thongBao": "Bồn cầu vệ sinh đặt trong phòng tắm!"
        },
        {
          "icon": "📏",
          "dung": false,
          "thongBao": "Thước kẻ giúp vẽ đường thẳng tắp!"
        }
      ]
    },
    {
      "moTa": "Đâu là chiếc áo thun lạc loài giữa các cặp sách?",
      "luaChon": [
        {
          "icon": "🎒",
          "dung": false,
          "thongBao": "Cái cặp sách đồng hành cùng bé đến trường!"
        },
        {
          "icon": "👕",
          "dung": true,
          "thongBao": "Áo thun mặc trên người giữ cơ thể sạch sẽ!"
        },
        {
          "icon": "🎒",
          "dung": false,
          "thongBao": "Cái cặp sách đồng hành cùng bé đến trường!"
        }
      ]
    },
    {
      "moTa": "Đồ vật nào khác biệt trong các dụng cụ viết?",
      "luaChon": [
        {
          "icon": "🎨",
          "dung": false,
          "thongBao": "Hộp bút màu tô điểm tranh vẽ sinh động!"
        },
        {
          "icon": "🍳",
          "dung": true,
          "thongBao": "Cái chảo chống dính nấu ăn trong bếp!"
        },
        {
          "icon": "🎨",
          "dung": false,
          "thongBao": "Hộp bút màu tô điểm tranh vẽ sinh động!"
        }
      ]
    },
    {
      "moTa": "Hiện tượng tự nhiên nào khác biệt với chiếc bóng đèn?",
      "luaChon": [
        {
          "icon": "🌙",
          "dung": false,
          "thongBao": "Mặt trăng sáng soi ban đêm dịu dàng!"
        },
        {
          "icon": "💡",
          "dung": true,
          "thongBao": "Bóng đèn điện thắp sáng trong nhà!"
        },
        {
          "icon": "🌙",
          "dung": false,
          "thongBao": "Mặt trăng sáng soi ban đêm dịu dàng!"
        }
      ]
    },
    {
      "moTa": "Tìm bông hoa hướng dương lạc loài bên chiếc dép!",
      "luaChon": [
        {
          "icon": "🩴",
          "dung": true,
          "thongBao": "Chiếc dép lê đi trong nhà tiện lợi!"
        },
        {
          "icon": "🌻",
          "dung": false,
          "thongBao": "Bông hoa rực rỡ dưới nắng vàng!"
        },
        {
          "icon": "🌻",
          "dung": false,
          "thongBao": "Bông hoa rực rỡ dưới nắng vàng!"
        }
      ]
    },
    {
      "moTa": "Hình nào không thuộc về bầu trời tự nhiên?",
      "luaChon": [
        {
          "icon": "☁️",
          "dung": false,
          "thongBao": "Đám mây trắng bồng bềnh trôi lững lờ!"
        },
        {
          "icon": "🔨",
          "dung": true,
          "thongBao": "Chiếc búa đinh là dụng cụ sửa chữa!"
        },
        {
          "icon": "☁️",
          "dung": false,
          "thongBao": "Đám mây trắng bồng bềnh trôi lững lờ!"
        }
      ]
    },
    {
      "moTa": "Đâu là chú bướm xinh xắn khác biệt với chiếc nhẫn?",
      "luaChon": [
        {
          "icon": "💍",
          "dung": true,
          "thongBao": "Chiếc nhẫn trang sức lấp lánh trên tay!"
        },
        {
          "icon": "🦋",
          "dung": false,
          "thongBao": "Chú bướm rập rờn vờn bên khóm lá!"
        },
        {
          "icon": "🦋",
          "dung": false,
          "thongBao": "Chú bướm rập rờn vờn bên khóm lá!"
        }
      ]
    },
    {
      "moTa": "Cây cối thiên nhiên nào khác biệt với ô tô?",
      "luaChon": [
        {
          "icon": "🌲",
          "dung": false,
          "thongBao": "Cây thông xanh rờn mùa giáng sinh!"
        },
        {
          "icon": "🚙",
          "dung": true,
          "thongBao": "Xe ô tô chạy bằng động cơ xăng dầu!"
        },
        {
          "icon": "🌲",
          "dung": false,
          "thongBao": "Cây thông xanh rờn mùa giáng sinh!"
        }
      ]
    },
    {
      "moTa": "Tìm hình quả bóng rổ nằm lệch ở ô đầu tiên nào!",
      "luaChon": [
        {
          "icon": "🏀",
          "dung": true,
          "thongBao": "Quả bóng rổ tròn xoe nằm ở vị trí đầu tiên!"
        },
        {
          "icon": "🐵",
          "dung": false,
          "thongBao": "Chú khỉ tinh nghịch chuyền cành cây!"
        },
        {
          "icon": "🐵",
          "dung": false,
          "thongBao": "Chú khỉ tinh nghịch chuyền cành cây!"
        }
      ]
    },
    {
      "moTa": "Hình chiếc máy bay nằm ở giữa có gì khác biệt?",
      "luaChon": [
        {
          "icon": "🦆",
          "dung": false,
          "thongBao": "Chú vịt kêu cạp cạp bơi dưới hồ nước!"
        },
        {
          "icon": "✈️",
          "dung": true,
          "thongBao": "Máy bay cất cánh trên cao, không phải động vật!"
        },
        {
          "icon": "🦆",
          "dung": false,
          "thongBao": "Chú vịt kêu cạp cạp bơi dưới hồ nước!"
        }
      ]
    },
    {
      "moTa": "Tìm hình chiếc giày thể thao khác biệt nằm ở cuối!",
      "luaChon": [
        {
          "icon": "🍎",
          "dung": false,
          "thongBao": "Quả táo đỏ ngon lành bổ dưỡng!"
        },
        {
          "icon": "🍎",
          "dung": false,
          "thongBao": "Quả táo đỏ ngon lành bổ dưỡng!"
        },
        {
          "icon": "👟",
          "dung": true,
          "thongBao": "Chiếc giày thể thao nằm ở ô cuối cùng!"
        }
      ]
    },
    {
      "moTa": "Hình nào là chiếc điện thoại khác biệt nằm ở giữa?",
      "luaChon": [
        {
          "icon": "📖",
          "dung": false,
          "thongBao": "Quyển sách giáo khoa mở trang tri thức!"
        },
        {
          "icon": "📱",
          "dung": true,
          "thongBao": "Điện thoại thông minh nằm ngay chính giữa!"
        },
        {
          "icon": "📖",
          "dung": false,
          "thongBao": "Quyển sách giáo khoa mở trang tri thức!"
        }
      ]
    },
    {
      "moTa": "Đâu là chiếc áo sơ mi lạc loài nằm ở vị trí đầu?",
      "luaChon": [
        {
          "icon": "👔",
          "dung": true,
          "thongBao": "Áo sơ mi lịch sự nằm ở ô đầu tiên!"
        },
        {
          "icon": "🧹",
          "dung": false,
          "thongBao": "Cục tẩy trắng phau xóa sạch nét chì!"
        },
        {
          "icon": "🧹",
          "dung": false,
          "thongBao": "Cục tẩy trắng phau xóa sạch nét chì!"
        }
      ]
    },
    {
      "moTa": "Tìm hình ngôi sao lấp lánh khác biệt nằm ở cuối!",
      "luaChon": [
        {
          "icon": "🌹",
          "dung": false,
          "thongBao": "Bông hoa hồng nhung đỏ thắm thơm ngát!"
        },
        {
          "icon": "🌹",
          "dung": false,
          "thongBao": "Bông hoa hồng nhung đỏ thắm thơm ngát!"
        },
        {
          "icon": "🌟",
          "dung": true,
          "thongBao": "Ngôi sao tỏa sáng nằm ở ô cuối cùng!"
        }
      ]
    },
    {
      "moTa": "Hình nào là chiếc đồng hồ cát nằm ở giữa khác lạ?",
      "luaChon": [
        {
          "icon": "🐶",
          "dung": false,
          "thongBao": "Chú cún vàng vẫy đuôi mừng chủ về!"
        },
        {
          "icon": "⏳",
          "dung": true,
          "thongBao": "Đồng hồ cát đo thời gian nằm ở giữa!"
        },
        {
          "icon": "🐶",
          "dung": false,
          "thongBao": "Chú cún vàng vẫy đuôi mừng chủ về!"
        }
      ]
    },
    {
      "moTa": "Đâu là chiếc bánh quy tròn ngon nằm ở đầu tiên?",
      "luaChon": [
        {
          "icon": "🍪",
          "dung": true,
          "thongBao": "Chiếc bánh quy giòn rụm nằm ở đầu tiên!"
        },
        {
          "icon": "🍓",
          "dung": false,
          "thongBao": "Quả dâu tây đỏ mọng tươi ngon!"
        },
        {
          "icon": "🍓",
          "dung": false,
          "thongBao": "Quả dâu tây đỏ mọng tươi ngon!"
        }
      ]
    },
    {
      "moTa": "Tìm hình quả bóng bàn khác biệt nằm ở giữa!",
      "luaChon": [
        {
          "icon": "✏️",
          "dung": false,
          "thongBao": "Cái bút chì nhọn đầu vẽ tranh đẹp!"
        },
        {
          "icon": "🏓",
          "dung": true,
          "thongBao": "Quả bóng bàn nhỏ xinh nằm ở chính giữa!"
        },
        {
          "icon": "✏️",
          "dung": false,
          "thongBao": "Cái bút chì nhọn đầu vẽ tranh đẹp!"
        }
      ]
    },
    {
      "moTa": "Hình nào là chiếc ô che mưa nằm ở cuối hàng?",
      "luaChon": [
        {
          "icon": "🐰",
          "dung": false,
          "thongBao": "Chú thỏ trắng ăn cà rốt chăm chỉ!"
        },
        {
          "icon": "🐰",
          "dung": false,
          "thongBao": "Chú thỏ trắng ăn cà rốt chăm chỉ!"
        },
        {
          "icon": "☂️",
          "dung": true,
          "thongBao": "Chiếc ô che mưa nằm ở ô cuối cùng!"
        }
      ]
    }
  ];
  @override
  void initState() {
    super.initState();
    _khoiTaoTtsVaCauHoi();
  }
  Future<void> _khoiTaoTtsVaCauHoi() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.5);
    _taiLaiDanhSachNgauNhien();
    _taoThuThachMoi();
  }
  void _taiLaiDanhSachNgauNhien() {
    _danhSachChiSoChuaDung.clear();
    for (int i = 0; i < _khoKhacBiet.length; i++) {
      _danhSachChiSoChuaDung.add(i);
    }
    _danhSachChiSoChuaDung.shuffle(_random);
  }
  void _taoThuThachMoi() {
    if (_danhSachChiSoChuaDung.isEmpty) {
      _taiLaiDanhSachNgauNhien();
    }
    _currentIndex = _danhSachChiSoChuaDung.removeAt(0);
    final item = _khoKhacBiet[_currentIndex];
    List<Map<String, dynamic>> luaChonXaoTron =
        List<Map<String, dynamic>>.from(item["luaChon"]);
    luaChonXaoTron.shuffle(_random);
    setState(() {
      cauHoiMoTa = item["moTa"];
      danhSachLuaChon = luaChonXaoTron;
      _thongBaoTrangThai = "";
    });
    flutterTts.speak(cauHoiMoTa);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cauHoiMoTa,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_thongBaoTrangThai.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(
                          _thongBaoTrangThai,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: danhSachLuaChon.map((item) {
                        bool isDung = item["dung"];
                        String icon = item["icon"];
                        String thongBao = item["thongBao"];

                        return GestureDetector(
                          onTap: () {
                            flutterTts.speak(thongBao);
                            setState(() {
                              _thongBaoTrangThai = thongBao;
                            });

                            if (isDung) {
                              _hienThongBaoDung(
                                  context, "🎉 Quá tinh mắt!", thongBao);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.orangeAccent, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.orange.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Text(icon,
                                style: const TextStyle(fontSize: 50)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    TextButton.icon(
                      onPressed: () => flutterTts.speak(cauHoiMoTa),
                      icon:
                          const Icon(Icons.volume_up, color: Colors.deepOrange),
                      label: const Text("Nghe lại câu hỏi",
                          style: TextStyle(
                              color: Colors.deepOrange, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Nút quay lại nổi bo tròn viền vàng đồng bộ
          Positioned(
            top: 12,
            left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    flutterTts.stop();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber.shade400,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _hienThongBaoDung(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (Navigator.canPop(c)) {
            Navigator.pop(c);
            _taoThuThachMoi();
          }
        });
        return AlertDialog(
          title: Text(title),
          content: Text(msg, style: const TextStyle(fontSize: 14)),
        );
      },
    );
  }
}

//TRANG BẢNG CỬU CHƯƠNG
class KaraokeLine {
  final String bieuThuc;
  final String textDoc;
  KaraokeLine({required this.bieuThuc, required this.textDoc});
}
final Map<int, List<KaraokeLine>> duLieuBangCuuChuong = {
  2: List.generate(
      10,
      (i) => KaraokeLine(
          bieuThuc: "2 x ${i + 1} = ${2 * (i + 1)}",
          textDoc: "Hai nhân ${i + 1} bằng ${2 * (i + 1)}")),
  3: List.generate(
      10,
      (i) => KaraokeLine(
          bieuThuc: "3 x ${i + 1} = ${3 * (i + 1)}",
          textDoc: "Ba nhân ${i + 1} bằng ${3 * (i + 1)}")),
  4: List.generate(
      10,
      (i) => KaraokeLine(
          bieuThuc: "4 x ${i + 1} = ${4 * (i + 1)}",
          textDoc: "Bốn nhân ${i + 1} bằng ${4 * (i + 1)}")),
  5: List.generate(
      10,
      (i) => KaraokeLine(
          bieuThuc: "5 x ${i + 1} = ${5 * (i + 1)}",
          textDoc: "Năm nhân ${i + 1} bằng ${5 * (i + 1)}")),
  6: List.generate(
      10,
      (i) => KaraokeLine(
          bieuThuc: "6 x ${i + 1} = ${6 * (i + 1)}",
          textDoc: "Sáu nhân ${i + 1} bằng ${6 * (i + 1)}")),
  7: List.generate(
      10,
      (i) => KaraokeLine(
          bieuThuc: "7 x ${i + 1} = ${7 * (i + 1)}",
          textDoc: "Bảy nhân ${i + 1} bằng ${7 * (i + 1)}")),
  8: List.generate(
      10,
      (i) => KaraokeLine(
          bieuThuc: "8 x ${i + 1} = ${8 * (i + 1)}",
          textDoc: "Tám nhân ${i + 1} bằng ${8 * (i + 1)}")),
  9: List.generate(
      10,
      (i) => KaraokeLine(
          bieuThuc: "9 x ${i + 1} = ${9 * (i + 1)}",
          textDoc: "Chín nhân ${i + 1} bằng ${9 * (i + 1)}")),
};
class TrangBangCuuChuong extends StatefulWidget {
  const TrangBangCuuChuong({Key? key}) : super(key: key);
  @override
  State<TrangBangCuuChuong> createState() => _TrangBangCuuChuongState();
}
class _TrangBangCuuChuongState extends State<TrangBangCuuChuong> {
  final FlutterTts _flutterTts = FlutterTts();
  int? _bangHienTai = 3;
  int _dongDangDoc = -1;
  bool _dangDoc = false;
  Completer<void>? _completerDocXong;
  @override
  void initState() {
    super.initState();
    _caiDatTts();
  }
  void _caiDatTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.55);
    await _flutterTts.setVolume(1.0);
    _flutterTts.setCompletionHandler(() {
      if (_completerDocXong != null && !_completerDocXong!.isCompleted) {
        _completerDocXong!.complete();
      }
    });
    _flutterTts.setErrorHandler((msg) {
      if (_completerDocXong != null && !_completerDocXong!.isCompleted) {
        _completerDocXong!.complete();
      }
    });
  }
  Future<void> _docCau(String text) async {
    _completerDocXong = Completer<void>();
    await _flutterTts.speak(text);
    await _completerDocXong?.future;
  }
  Future<void> _batDauDocTatCa() async {
    _dungDoc();
    setState(() {
      _dangDoc = true;
    });
    for (int soBang = 2; soBang <= 9; soBang++) {
      if (!mounted || !_dangDoc) break;
      setState(() {
        _bangHienTai = soBang;
        _dongDangDoc = -1;
      });
      await _docCau("Bảng nhân $soBang");
      if (!mounted || !_dangDoc) break;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || !_dangDoc) break;
      List<KaraokeLine> danhSach = duLieuBangCuuChuong[soBang]!;
      for (int i = 0; i < danhSach.length; i++) {
        if (!mounted || !_dangDoc) break;
        setState(() {
          _dongDangDoc = i;
        });
        await _docCau(danhSach[i].textDoc);
        if (!mounted || !_dangDoc) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (!mounted || !_dangDoc) break;
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    if (mounted && _dangDoc) {
      _dungDoc();
    }
  }

  void _dungDoc() {
    _flutterTts.stop();
    if (_completerDocXong != null && !_completerDocXong!.isCompleted) {
      _completerDocXong!.complete();
    }
    if (mounted) {
      setState(() {
        _dongDangDoc = -1;
        _dangDoc = false;
      });
    }
  }

  @override
  void dispose() {
    _dungDoc();
    super.dispose();
  }

  Widget _buildItemDong(int index, List<KaraokeLine> danhSach) {
    final line = danhSach[index];
    bool dangActive = index == _dongDangDoc;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dangActive ? Colors.amber.shade100 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dangActive ? Colors.red.shade300 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Text(
        line.bieuThuc,
        style: TextStyle(
          fontSize: dangActive ? 21 : 18,
          fontWeight: dangActive ? FontWeight.bold : FontWeight.w600,
          color: dangActive ? Colors.red.shade700 : Colors.black87,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final List<Color> mauCacBang = [
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.amber.shade700,
      Colors.green,
      Colors.teal,
      Colors.blueAccent,
      Colors.indigoAccent,
      Colors.purpleAccent
    ];
    List<KaraokeLine>? danhSachHienTai =
        _bangHienTai != null ? duLieuBangCuuChuong[_bangHienTai!] : null;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 65, 20, 20),
              child: Column(
                children: [
                  // 1. THANH CHỌN BẢNG CAPSULE
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        int soBang = index + 2;
                        bool dangChon = _bangHienTai == soBang;
                        Color mauChuDao = mauCacBang[index % mauCacBang.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  dangChon ? mauChuDao : Colors.white,
                              foregroundColor:
                                  dangChon ? Colors.white : Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                    color: dangChon
                                        ? Colors.transparent
                                        : Colors.grey.shade300),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () {
                              _dungDoc();
                              setState(() {
                                _bangHienTai = soBang;
                              });
                            },
                            child: Text("Bảng $soBang",
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 2. NÚT ĐIỀU KHIỂN ÂM THANH
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _dangDoc ? Colors.redAccent : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _dangDoc ? _dungDoc : _batDauDocTatCa,
                    icon: Icon(_dangDoc ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _dangDoc ? "Dừng Đọc Tất Cả" : "Đọc Tất Cả",
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. KHUNG HIỂN THỊ BẢNG SỐ
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.amber.shade200, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  topRight: Radius.circular(14)),
                            ),
                            child: Text(
                              "BẢNG NHÂN $_bangHienTai",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900),
                            ),
                          ),
                          Expanded(
                            child: danhSachHienTai == null
                                ? const Center(child: Text("Chưa chọn bảng"))
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      double chieuCaoKhung =
                                          constraints.maxHeight;
                                      double chieuRongKhung =
                                          constraints.maxWidth;
                                      double itemWidth = chieuRongKhung / 2;
                                      double itemHeight = chieuCaoKhung / 5;
                                      double ratio = itemWidth / itemHeight;
                                      return GridView.builder(
                                        padding: const EdgeInsets.all(6),
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio:
                                              ratio > 0 ? ratio : 1,
                                          mainAxisSpacing: 1,
                                          crossAxisSpacing: 1,
                                        ),
                                        itemCount: danhSachHienTai.length,
                                        itemBuilder: (context, index) {
                                          return _buildItemDong(
                                              index, danhSachHienTai);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Nút quay lại nổi bo tròn viền vàng đồng bộ với các trang khác
          Positioned(
            top: 12,
            left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _dungDoc();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber.shade400,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= MODEL BẢNG TÍNH 3x3 =================
class MauBangTinh {
  final int c1r1, c2r1, c3r1;
  final int c1r2, c2r2, c3r2;
  final int c1r3, c2r3, c3r3;
  final String dauHang1;
  final String dauHang2;
  final String dauHang3;
  final String dauCot1;
  final String dauCot2;
  final String dauCot3;
  const MauBangTinh({
    required this.c1r1, required this.c2r1, required this.c3r1,
    required this.c1r2, required this.c2r2, required this.c3r2,
    required this.c1r3, required this.c2r3, required this.c3r3,
    required this.dauHang1,
    required this.dauHang2,
    required this.dauHang3,
    required this.dauCot1,
    required this.dauCot2,
    required this.dauCot3,
  });
}

// ================= MODEL TOÁN ĐAN CHÉO =================
class CauHoiLienHoan {
  final int top1, mid1, bot1; 
  final int rowLeft, rowMid2, rowResult; 
  final int top2, mid2, bot2; 
  final String dauDichV1; 
  final String dauDichV2; 
  final String dauHangNgang1; 
  final String dauHangNgang2; 
  const CauHoiLienHoan({
    required this.top1, required this.mid1, required this.bot1,
    required this.rowLeft, required this.rowMid2, required this.rowResult,
    required this.top2, required this.mid2, required this.bot2,
    required this.dauDichV1,
    required this.dauDichV2,
    required this.dauHangNgang1,
    required this.dauHangNgang2,
  });
}
// Model lưu lại lịch sử chi tiết
class NhatKyCauHoi {
  final int soThuTu;
  final String tenLoai; 
  final bool laDung;
  final bool laDangDanCheo;
  final MauBangTinh? mau3x3;
  final List<List<int>>? danhSachOTrong3x3;
  final CauHoiLienHoan? mauDanCheo;
  final List<String>? danhSachKeysOTrongLienHoan;
  final Map<String, String> duLieuBeDien;
  NhatKyCauHoi({
    required this.soThuTu,
    required this.tenLoai,
    required this.laDung,
    required this.laDangDanCheo,
    this.mau3x3,
    this.danhSachOTrong3x3,
    this.mauDanCheo,
    this.danhSachKeysOTrongLienHoan,
    required this.duLieuBeDien,
  });
}
class TrangBangTinhLogic extends StatefulWidget {
  const TrangBangTinhLogic({super.key});
  @override
  State<TrangBangTinhLogic> createState() => _TrangBangTinhLogicState();
}
class _TrangBangTinhLogicState extends State<TrangBangTinhLogic> {
  bool _laDangDanCheo = false; 
  // ================= 50 MẪU BẢNG TÍNH 3X3 =================
  final List<MauBangTinh> _khoMau3x3 = [
    MauBangTinh(c1r1: 5, c2r1: 2, c3r1: 7, c1r2: 6, c2r2: 1, c3r2: 5, c1r3: 11, c2r3: 1, c3r3: 12, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 3, c3r1: 11, c1r2: 5, c2r2: 2, c3r2: 3, c1r3: 13, c2r3: 1, c3r3: 14, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 4, c3r1: 10, c1r2: 7, c2r2: 2, c3r2: 5, c1r3: 13, c2r3: 2, c3r3: 15, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 1, c3r1: 10, c1r2: 4, c2r2: 1, c3r2: 3, c1r3: 13, c2r3: 0, c3r3: 13, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 7, c2r1: 3, c3r1: 10, c1r2: 6, c2r2: 3, c3r2: 3, c1r3: 13, c2r3: 0, c3r3: 13, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 4, c2r1: 5, c3r1: 9, c1r2: 8, c2r2: 2, c3r2: 6, c1r3: 12, c2r3: 3, c3r3: 15, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 2, c3r1: 10, c1r2: 5, c2r2: 1, c3r2: 4, c1r3: 13, c2r3: 1, c3r3: 14, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 3, c3r1: 9, c1r2: 6, c2r2: 2, c3r2: 4, c1r3: 12, c2r3: 1, c3r3: 13, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 5, c3r1: 14, c1r2: 7, c2r2: 4, c3r2: 3, c1r3: 16, c2r3: 1, c3r3: 17, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 5, c2r1: 4, c3r1: 9, c1r2: 5, c2r2: 1, c3r2: 4, c1r3: 10, c2r3: 3, c3r3: 13, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 4, c3r1: 5, c1r2: 3, c2r2: 1, c3r2: 2, c1r3: 12, c2r3: 5, c3r3: 7,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 3, c3r1: 5, c1r2: 4, c2r2: 2, c3r2: 2, c1r3: 12, c2r3: 5, c3r3: 7,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 7, c2r1: 2, c3r1: 5, c1r2: 5, c2r2: 3, c3r2: 2, c1r3: 12, c2r3: 5, c3r3: 7,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 1, c3r1: 5, c1r2: 4, c2r2: 2, c3r2: 2, c1r3: 10, c2r3: 3, c3r3: 7,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 2, c3r1: 7, c1r2: 4, c2r2: 3, c3r2: 1, c1r3: 13, c2r3: 5, c3r3: 8,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 4, c3r1: 4, c1r2: 3, c2r2: 2, c3r2: 1, c1r3: 11, c2r3: 6, c3r3: 5,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 7, c2r1: 3, c3r1: 4, c1r2: 5, c2r2: 2, c3r2: 3, c1r3: 12, c2r3: 5, c3r3: 7,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 2, c3r1: 4, c1r2: 4, c2r2: 3, c3r2: 1, c1r3: 10, c2r3: 5, c3r3: 5,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 1, c3r1: 8, c1r2: 6, c2r2: 4, c3r2: 2, c1r3: 15, c2r3: 5, c3r3: 10, dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 5, c3r1: 3, c1r2: 6, c2r2: 2, c3r2: 4, c1r3: 14, c2r3: 7, c3r3: 7,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 4, c2r1: 3, c3r1: 7, c1r2: 2, c2r2: 1, c3r2: 3, c1r3: 6,  c2r3: 4, c3r3: 10, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 7, c2r1: 2, c3r1: 9, c1r2: 3, c2r2: 1, c3r2: 4, c1r3: 10, c2r3: 3, c3r3: 13, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 4, c3r1: 10, c1r2: 4, c2r2: 2, c3r2: 6, c1r3: 10, c2r3: 6, c3r3: 16, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 5, c2r1: 3, c3r1: 8, c1r2: 2, c2r2: 1, c3r2: 3, c1r3: 7,  c2r3: 4, c3r3: 11, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 1, c3r1: 9, c1r2: 5, c2r2: 3, c3r2: 8, c1r3: 13, c2r3: 4, c3r3: 17, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 2, c3r1: 11, c1r2: 3, c2r2: 2, c3r2: 5, c1r3: 12, c2r3: 4, c3r3: 16, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 4, c2r1: 4, c3r1: 8, c1r2: 1, c2r2: 1, c3r2: 2, c1r3: 5,  c2r3: 5, c3r3: 10, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 7, c2r1: 3, c3r1: 10, c1r2: 4, c2r2: 3, c3r2: 7, c1r3: 11, c2r3: 6, c3r3: 17, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 2, c3r1: 8, c1r2: 3, c2r2: 1, c3r2: 4, c1r3: 9,  c2r3: 3, c3r3: 12, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 2, c3r1: 10, c1r2: 6, c2r2: 3, c3r2: 9, c1r3: 14, c2r3: 5, c3r3: 19, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 3, c3r1: 12, c1r2: 5, c2r2: 3, c3r2: 8, c1r3: 14, c2r3: 6, c3r3: 20, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 5, c2r1: 4, c3r1: 9, c1r2: 2, c2r2: 1, c3r2: 3, c1r3: 7,  c2r3: 5, c3r3: 12, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 7, c2r1: 1, c3r1: 8, c1r2: 4, c2r2: 2, c3r2: 6, c1r3: 11, c2r3: 3, c3r3: 14, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 3, c3r1: 9, c1r2: 3, c2r2: 1, c3r2: 4, c1r3: 9,  c2r3: 4, c3r3: 13, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 4, c3r1: 12, c1r2: 5, c2r2: 2, c3r2: 7, c1r3: 13, c2r3: 6, c3r3: 19, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 1, c3r1: 8, c1r2: 4, c2r2: 3, c3r2: 1, c1r3: 13, c2r3: 4, c3r3: 9,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 7, c2r1: 2, c3r1: 5, c1r2: 3, c2r2: 2, c3r2: 1, c1r3: 10, c2r3: 4, c3r3: 6,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 3, c3r1: 5, c1r2: 5, c2r2: 3, c3r2: 2, c1r3: 13, c2r3: 6, c3r3: 7,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 2, c3r1: 4, c1r2: 4, c2r2: 3, c3r2: 1, c1r3: 10, c2r3: 5, c3r3: 5,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 4, c3r1: 5, c1r2: 2, c2r2: 1, c3r2: 1, c1r3: 11, c2r3: 5, c3r3: 6,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 5, c2r1: 1, c3r1: 4, c1r2: 3, c2r2: 2, c3r2: 1, c1r3: 8,  c2r3: 3, c3r3: 5,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 2, c3r1: 6, c1r2: 4, c2r2: 2, c3r2: 2, c1r3: 12, c2r3: 4, c3r3: 8,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 7, c2r1: 3, c3r1: 4, c1r2: 5, c2r2: 2, c3r2: 3, c1r3: 12, c2r3: 5, c3r3: 7,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 3, c3r1: 6, c1r2: 6, c2r2: 3, c3r2: 3, c1r3: 15, c2r3: 6, c3r3: 9,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 3, c3r1: 3, c1r2: 2, c2r2: 1, c3r2: 1, c1r3: 8,  c2r3: 4, c3r3: 4,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 4, c2r1: 1, c3r1: 3, c1r2: 3, c2r2: 2, c3r2: 1, c1r3: 7,  c2r3: 3, c3r3: 4,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 9, c2r1: 5, c3r1: 4, c1r2: 4, c2r2: 2, c3r2: 2, c1r3: 13, c2r3: 7, c3r3: 6,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 4, c3r1: 4, c1r2: 3, c2r2: 3, c3r2: 0, c1r3: 11, c2r3: 7, c3r3: 4,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 7, c2r1: 4, c3r1: 3, c1r2: 5, c2r2: 2, c3r2: 3, c1r3: 12, c2r3: 6, c3r3: 6,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 6, c2r1: 2, c3r1: 4, c1r2: 3, c2r2: 1, c3r2: 2, c1r3: 9,  c2r3: 3, c3r3: 6,  dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
 MauBangTinh(c1r1: 10, c2r1: 10, c3r1: 0, c1r2: 2, c2r2: 2, c3r2: 0, c1r3: 12, c2r3: 12, c3r3: 0, dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "-"),
    MauBangTinh(c1r1: 10, c2r1: 9, c3r1: 19, c1r2: 5, c2r2: 8, c3r2: 13, c1r3: 5, c2r3: 1, c3r3: 6, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "-", dauCot2: "-", dauCot3: "-"),
    MauBangTinh(c1r1: 11, c2r1: 8, c3r1: 3, c1r2: 4, c2r2: 2, c3r2: 2, c1r3: 15, c2r3: 10, c3r3: 5, dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 12, c2r1: 1, c3r1: 13, c1r2: 7, c2r2: 1, c3r2: 6, c1r3: 5, c2r3: 2, c3r3: 7, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "-", dauCot2: "+", dauCot3: "-"),
    MauBangTinh(c1r1: 5, c2r1: 1, c3r1: 4, c1r2: 11, c2r2: 8, c3r2: 3, c1r3: 16, c2r3: 9, c3r3: 7, dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 1, c2r1: 6, c3r1: 7, c1r2: 9, c2r2: 6, c3r2: 3, c1r3: 10, c2r3: 0, c3r3: 10, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 12, c2r1: 12, c3r1: 0, c1r2: 12, c2r2: 11, c3r2: 1, c1r3: 0, c2r3: 1, c3r3: 1, dauHang1: "-", dauHang2: "-", dauHang3: "+", dauCot1: "-", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 12, c2r1: 4, c3r1: 16, c1r2: 1, c2r2: 1, c3r2: 0, c1r3: 13, c2r3: 3, c3r3: 16, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 5, c2r1: 12, c3r1: 17, c1r2: 12, c2r2: 11, c3r2: 1, c1r3: 17, c2r3: 1, c3r3: 16, dauHang1: "+", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "-", dauCot3: "-"),
    MauBangTinh(c1r1: 12, c2r1: 7, c3r1: 5, c1r2: 7, c2r2: 2, c3r2: 9, c1r3: 19, c2r3: 5, c3r3: 14, dauHang1: "-", dauHang2: "+", dauHang3: "-", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 8, c2r1: 3, c3r1: 5, c1r2: 12, c2r2: 12, c3r2: 0, c1r3: 20, c2r3: 15, c3r3: 5, dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 2, c2r1: 11, c3r1: 13, c1r2: 7, c2r2: 5, c3r2: 2, c1r3: 9, c2r3: 6, c3r3: 15, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "+"),
    MauBangTinh(c1r1: 4, c2r1: 1, c3r1: 3, c1r2: 10, c2r2: 5, c3r2: 5, c1r3: 14, c2r3: 6, c3r3: 8, dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 10, c2r1: 10, c3r1: 20, c1r2: 8, c2r2: 4, c3r2: 12, c1r3: 2, c2r3: 6, c3r3: 8, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "-", dauCot2: "-", dauCot3: "-"),
    MauBangTinh(c1r1: 12, c2r1: 3, c3r1: 9, c1r2: 4, c2r2: 2, c3r2: 6, c1r3: 8, c2r3: 5, c3r3: 3, dauHang1: "-", dauHang2: "+", dauHang3: "-", dauCot1: "-", dauCot2: "+", dauCot3: "-"),
    MauBangTinh(c1r1: 8, c2r1: 12, c3r1: 20, c1r2: 3, c2r2: 5, c3r2: 8, c1r3: 5, c2r3: 7, c3r3: 12, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "-", dauCot2: "-", dauCot3: "-"),
    MauBangTinh(c1r1: 5, c2r1: 3, c3r1: 2, c1r2: 9, c2r2: 8, c3r2: 1, c1r3: 14, c2r3: 11, c3r3: 3, dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "+"),
    MauBangTinh(c1r1: 4, c2r1: 3, c3r1: 1, c1r2: 7, c2r2: 7, c3r2: 0, c1r3: 11, c2r3: 10, c3r3: 1, dauHang1: "-", dauHang2: "-", dauHang3: "-", dauCot1: "+", dauCot2: "+", dauCot3: "-"),
    MauBangTinh(c1r1: 11, c2r1: 3, c3r1: 14, c1r2: 1, c2r2: 1, c3r2: 0, c1r3: 12, c2r3: 2, c3r3: 14, dauHang1: "+", dauHang2: "-", dauHang3: "+", dauCot1: "+", dauCot2: "-", dauCot3: "-"),
    MauBangTinh(c1r1: 4, c2r1: 10, c3r1: 14, c1r2: 1, c2r2: 8, c3r2: 9, c1r3: 3, c2r3: 2, c3r3: 5, dauHang1: "+", dauHang2: "+", dauHang3: "+", dauCot1: "-", dauCot2: "-", dauCot3: "-"),
  ];
  // ================= 50 MẪU ĐAN CHÉO =================
  final List<CauHoiLienHoan> _khoDeLienHoan = [
    CauHoiLienHoan(top1: 5, mid1: 2, bot1: 7, rowLeft: 4, rowMid2: 3, rowResult: 3, top2: 9, mid2: 3, bot2: 6, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 7, mid1: 3, bot1: 10, rowLeft: 5, rowMid2: 2, rowResult: 6, top2: 8, mid2: 4, bot2: 2, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),    
    CauHoiLienHoan(top1: 8, mid1: 1, bot1: 9, rowLeft: 6, rowMid2: 2, rowResult: 5, top2: 9, mid2: 4, bot2: 4, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),    
    CauHoiLienHoan(top1: 9, mid1: 2, bot1: 11, rowLeft: 4, rowMid2: 3, rowResult: 3, top2: 8, mid2: 3, bot2: 5, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 5, mid1: 3, bot1: 8, rowLeft: 3, rowMid2: 1, rowResult: 5, top2: 2, mid2: 2, bot2: 7, dauDichV1: "+", dauDichV2: "+", dauHangNgang1: "+", dauHangNgang2: "-"),   
    CauHoiLienHoan(top1: 7, mid1: 2, bot1: 9, rowLeft: 2, rowMid2: 1, rowResult: 3, top2: 6, mid2: 2, bot2: 3, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 8, mid1: 2, bot1: 10, rowLeft: 4, rowMid2: 2, rowResult: 4, top2: 8, mid2: 3, bot2: 4, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),  
    CauHoiLienHoan(top1: 6, mid1: 2, bot1: 4, rowLeft: 5, rowMid2: 1, rowResult: 8, top2: 8, mid2: 3, bot2: 0, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 9, mid1: 4, bot1: 5, rowLeft: 3, rowMid2: 2, rowResult: 9, top2: 14, mid2: 2, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 8, mid1: 3, bot1: 5, rowLeft: 4, rowMid2: 1, rowResult: 8, top2: 13, mid2: 1, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 7, mid1: 1, bot1: 6, rowLeft: 6, rowMid2: 2, rowResult: 9, top2: 15, mid2: 3, bot2: 6, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 6, mid1: 1, bot1: 5, rowLeft: 4, rowMid2: 1, rowResult: 6, top2: 10, mid2: 4, bot2: 4, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 9, mid1: 5, bot1: 4, rowLeft: 2, rowMid2: 1, rowResult: 8, top2: 9, mid2: 1, bot2: 1, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),    
    CauHoiLienHoan(top1: 4, mid1: 3, bot1: 7, rowLeft: 6, rowMid2: 2, rowResult: 5, top2: 7, mid2: 1, bot2: 2, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 5, mid1: 2, bot1: 7, rowLeft: 7, rowMid2: 3, rowResult: 8, top2: 13, mid2: 2, bot2: 5, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 7, mid1: 2, bot1: 9, rowLeft: 5, rowMid2: 1, rowResult: 6, top2: 14, mid2: 3, bot2: 8, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),    
    CauHoiLienHoan(top1: 8, mid1: 2, bot1: 10, rowLeft: 4, rowMid2: 2, rowResult: 4, top2: 9, mid2: 3, bot2: 5, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 7, mid1: 3, bot1: 4, rowLeft: 4, rowMid2: 2, rowResult: 9, top2: 14, mid2: 3, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 8, mid1: 3, bot1: 5, rowLeft: 4, rowMid2: 1, rowResult: 8, top2: 13, mid2: 1, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 9, mid1: 3, bot1: 6, rowLeft: 3, rowMid2: 2, rowResult: 8, top2: 13, mid2: 2, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 4, mid1: 3, bot1: 7, rowLeft: 6, rowMid2: 2, rowResult: 5, top2: 7, mid2: 1, bot2: 2, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 8, mid1: 3, bot1: 5, rowLeft: 9, rowMid2: 2, rowResult: 8, top2: 12, mid2: 3, bot2: 4, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),    
    CauHoiLienHoan(top1: 3, mid1: 4, bot1: 7, rowLeft: 9, rowMid2: 4, rowResult: 9, top2: 13, mid2: 2, bot2: 4, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 8, mid1: 2, bot1: 6, rowLeft: 7, rowMid2: 1, rowResult: 8, top2: 3, mid2: 2, bot2: 11, dauDichV1: "-", dauDichV2: "+", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 7, mid1: 3, bot1: 4, rowLeft: 6, rowMid2: 2, rowResult: 7, top2: 2, mid2: 4, bot2: 9, dauDichV1: "-", dauDichV2: "+", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 6, mid1: 2, bot1: 4, rowLeft: 5, rowMid2: 1, rowResult: 6, top2: 3, mid2: 3, bot2: 9, dauDichV1: "-", dauDichV2: "+", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 9, mid1: 2, bot1: 7, rowLeft: 6, rowMid2: 1, rowResult: 7, top2: 12, mid2: 1, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 5, mid1: 1, bot1: 4, rowLeft: 8, rowMid2: 2, rowResult: 7, top2: 12, mid2: 3, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 4, mid1: 3, bot1: 7, rowLeft: 9, rowMid2: 2, rowResult: 8, top2: 14, mid2: 2, bot2: 6, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 5, mid1: 2, bot1: 7, rowLeft: 8, rowMid2: 3, rowResult: 9, top2: 15, mid2: 3, bot2: 6, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 6, mid1: 3, bot1: 9, rowLeft: 9, rowMid2: 2, rowResult: 8, top2: 13, mid2: 2, bot2: 5, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 3, mid1: 4, bot1: 7, rowLeft: 7, rowMid2: 2, rowResult: 5, top2: 10, mid2: 3, bot2: 5, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 4, mid1: 5, bot1: 9, rowLeft: 8, rowMid2: 3, rowResult: 6, top2: 11, mid2: 4, bot2: 5, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 7, mid1: 2, bot1: 9, rowLeft: 9, rowMid2: 2, rowResult: 9, top2: 14, mid2: 1, bot2: 5, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 5, mid1: 4, bot1: 9, rowLeft: 10, rowMid2: 3, rowResult: 9, top2: 15, mid2: 2, bot2: 6, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 8, mid1: 3, bot1: 5, rowLeft: 6, rowMid2: 2, rowResult: 7, top2: 12, mid2: 2, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 7, mid1: 2, bot1: 9, rowLeft: 5, rowMid2: 1, rowResult: 6, top2: 14, mid2: 3, bot2: 8, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 6, mid1: 2, bot1: 4, rowLeft: 4, rowMid2: 3, rowResult: 9, top2: 14, mid2: 2, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 5, mid1: 4, bot1: 9, rowLeft: 8, rowMid2: 2, rowResult: 6, top2: 11, mid2: 3, bot2: 5, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 9, mid1: 3, bot1: 6, rowLeft: 7, rowMid2: 4, rowResult: 8, top2: 13, mid2: 2, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 4, mid1: 3, bot1: 7, rowLeft: 9, rowMid2: 2, rowResult: 8, top2: 14, mid2: 4, bot2: 6, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 8, mid1: 2, bot1: 6, rowLeft: 5, rowMid2: 2, rowResult: 9, top2: 15, mid2: 3, bot2: 6, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 6, mid1: 2, bot1: 8, rowLeft: 7, rowMid2: 3, rowResult: 8, top2: 12, mid2: 2, bot2: 4, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 7, mid1: 4, bot1: 3, rowLeft: 6, rowMid2: 1, rowResult: 9, top2: 14, mid2: 2, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 3, mid1: 5, bot1: 8, rowLeft: 8, rowMid2: 3, rowResult: 6, top2: 11, mid2: 2, bot2: 5, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 9, mid1: 5, bot1: 4, rowLeft: 4, rowMid2: 1, rowResult: 10, top2: 16, mid2: 3, bot2: 6, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 5, mid1: 3, bot1: 8, rowLeft: 6, rowMid2: 4, rowResult: 7, top2: 13, mid2: 2, bot2: 6, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 8, mid1: 4, bot1: 4, rowLeft: 7, rowMid2: 2, rowResult: 9, top2: 14, mid2: 3, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "-"),
    CauHoiLienHoan(top1: 6, mid1: 1, bot1: 7, rowLeft: 8, rowMid2: 2, rowResult: 9, top2: 15, mid2: 4, bot2: 6, dauDichV1: "+", dauDichV2: "-", dauHangNgang1: "-", dauHangNgang2: "+"),
    CauHoiLienHoan(top1: 9, mid1: 2, bot1: 7, rowLeft: 3, rowMid2: 3, rowResult: 8, top2: 13, mid2: 2, bot2: 5, dauDichV1: "-", dauDichV2: "-", dauHangNgang1: "+", dauHangNgang2: "+"),
  ];
  // ================= QUẢN LÝ TIẾN TRÌNH =================
  late final List<int> _shuffledIndex3x3 = List.generate(_khoMau3x3.length, (i) => i)..shuffle();
  late final List<int> _shuffledIndexDanCheo = List.generate(_khoDeLienHoan.length, (i) => i)..shuffle();
  int _currentIndex3x3 = 0;
  int _currentIndexDanCheo = 0;
  late MauBangTinh _bangHienTai;
  late CauHoiLienHoan _cauHoiLienHoanHienTai;
  List<List<int>> _danhSachOTrong3x3 = [];
  final Map<String, String> _giaTriOTrinh3x3 = {};
  List<String> _danhSachKeysOTrongLienHoan = [];
  final Map<String, String> _giaTriNhapLienHoan = {};
  String? _oDangChonKey; 
  bool _dangXuLyDung = false; 
  int _soLanDung = 0;
  String _thongBao = "";
  Color _mauThongBao = Colors.transparent;
  final List<NhatKyCauHoi> _lichSuLamBai = [];
  OverlayEntry? _overlayEntryHienTai;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _chayKiemTraTuDongDuLieu();
    _taoCauHoiMoi();
  }
  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _ungDungGiaiPhongOverlay();
    super.dispose();
  }
  int _tinh(int a, String dau, int b) {
    if (dau == '+') return a + b;
    if (dau == '-') return a - b;
    throw ArgumentError('Dấu không hợp lệ: $dau');
  }
  void _chayKiemTraTuDongDuLieu() {

  // KIỂM TRA MẪU 3x3
  for (var i = 0; i < _khoMau3x3.length; i++) {
    final c = _khoMau3x3[i];

    bool h1 = _tinh(c.c1r1, c.dauHang1, c.c2r1) == c.c3r1;
    bool h2 = _tinh(c.c1r2, c.dauHang2, c.c2r2) == c.c3r2;
    bool h3 = _tinh(c.c1r3, c.dauHang3, c.c2r3) == c.c3r3;

    bool c1 = _tinh(c.c1r1, c.dauCot1, c.c1r2) == c.c1r3;
    bool c2 = _tinh(c.c2r1, c.dauCot2, c.c2r2) == c.c2r3;
    bool c3 = _tinh(c.c3r1, c.dauCot3, c.c3r2) == c.c3r3;

    if (!h1 || !h2 || !h3 || !c1 || !c2 || !c3) {
      debugPrint("❌ Lỗi Mẫu 3x3 câu thứ ${i + 1}");
    }
  }

  // KIỂM TRA MẪU ĐAN CHÉO
  for (var i = 0; i < _khoDeLienHoan.length; i++) {
    final c = _khoDeLienHoan[i];

    bool cot1 = _tinh(c.top1, c.dauDichV1, c.mid1) == c.bot1;
    int buoc1 = _tinh(c.rowLeft, c.dauHangNgang1, c.mid1);
    bool ngang = _tinh(buoc1, c.dauHangNgang2, c.rowMid2) == c.rowResult;
    bool cot2 = _tinh(c.top2, c.dauDichV2, c.rowResult) == c.bot2;

    if (!cot1 || !ngang || !cot2) {
      debugPrint("❌ Lỗi Mẫu Đan Chéo câu thứ ${i + 1}");
    }
  }
}
  void _taoCauHoiMoi() {
  final random = Random();
  // XÓA DỮ LIỆU CỦA CÂU CŨ
  _giaTriOTrinh3x3.clear();
  _giaTriNhapLienHoan.clear();
  _danhSachOTrong3x3 = [];
  _danhSachKeysOTrongLienHoan = [];
  _oDangChonKey = null;
  _dangXuLyDung = false;
  _laDangDanCheo = random.nextBool();
  if (!_laDangDanCheo) {
    int realIndex = _shuffledIndex3x3[_currentIndex3x3];
    _bangHienTai = _khoMau3x3[realIndex];
    _currentIndex3x3 =
        (_currentIndex3x3 + 1) % _khoMau3x3.length;
    if (realIndex >= 50) {
      // 20 CÂU MỚI: ẨN 5 Ô
      List<List<List<int>>> cacBoOTrong5O = [
        [[1, 1], [1, 2], [2, 1], [2, 2], [3, 2]],
        [[1, 2], [1, 3], [2, 2], [3, 1], [3, 3]],
        [[1, 1], [2, 2], [2, 3], [3, 1], [3, 3]],
      ];
      _danhSachOTrong3x3 =
          cacBoOTrong5O[random.nextInt(cacBoOTrong5O.length)];
    } else {
      // 50 CÂU CŨ: ẨN 3 Ô
      List<List<List<int>>> cacBoOTrong3O = [
        [[1, 2], [1, 3], [2, 3]],
        [[1, 1], [2, 1], [1, 3]],
        [[3, 1], [3, 2], [3, 3]],
      ];
      _danhSachOTrong3x3 =
          cacBoOTrong3O[random.nextInt(cacBoOTrong3O.length)];
    }
    if (_danhSachOTrong3x3.isNotEmpty) {
      _oDangChonKey =
          "${_danhSachOTrong3x3[0][0]}_${_danhSachOTrong3x3[0][1]}";
    }
  } else {
    // DẠNG ĐAN CHÉO
    int realIndex = _shuffledIndexDanCheo[_currentIndexDanCheo];
    _cauHoiLienHoanHienTai = _khoDeLienHoan[realIndex];
    _currentIndexDanCheo =
        (_currentIndexDanCheo + 1) % _khoDeLienHoan.length;
    List<List<String>> cacBoAnLienHoan = [
      ["mid1", "rowMid2", "bot2"],
      ["top1", "rowMid2", "bot2"],
      ["mid1", "rowResult", "bot2"],
    ];
    _danhSachKeysOTrongLienHoan =
        cacBoAnLienHoan[random.nextInt(cacBoAnLienHoan.length)];
    if (_danhSachKeysOTrongLienHoan.isNotEmpty) {
      _oDangChonKey = _danhSachKeysOTrongLienHoan.first;
    }
  }
  _thongBao = "";
  _mauThongBao = Colors.transparent;
  setState(() {});
}
  void _nhapSo(String so) {
    if (_dangXuLyDung || _oDangChonKey == null) return;
    setState(() {
      if (!_laDangDanCheo) {
        String hienTai = _giaTriOTrinh3x3[_oDangChonKey!] ?? "";
        if (hienTai.length < 2) {
          _giaTriOTrinh3x3[_oDangChonKey!] = hienTai + so;
        } else {
          _giaTriOTrinh3x3[_oDangChonKey!] = so;
        }
      } else {
        String hienTai = _giaTriNhapLienHoan[_oDangChonKey!] ?? "";
        if (hienTai.length < 2) {
          _giaTriNhapLienHoan[_oDangChonKey!] = hienTai + so;
        } else {
          _giaTriNhapLienHoan[_oDangChonKey!] = so;
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kiemTraTuDong();
    });
  }
  void _xoaSo() {
    if (_dangXuLyDung || _oDangChonKey == null) return;
    setState(() {
      if (!_laDangDanCheo) {
        _giaTriOTrinh3x3.remove(_oDangChonKey);
      } else {
        _giaTriNhapLienHoan.remove(_oDangChonKey);
      }
    });
  }
  void _kiemTraTuDong() {
    if (_dangXuLyDung) return; 
    if (!_laDangDanCheo) {
      for (var viTri in _danhSachOTrong3x3) {
        String key = "${viTri[0]}_${viTri[1]}";
        if (!(_giaTriOTrinh3x3.containsKey(key)) || (_giaTriOTrinh3x3[key] ?? "").isEmpty) {
          return; 
        }
      }
      for (var viTri in _danhSachOTrong3x3) {
        String key = "${viTri[0]}_${viTri[1]}";
        int valGoc = _layGiaTriChuan3x3(viTri[0], viTri[1]);
        if (valGoc >= 10 && (_giaTriOTrinh3x3[key]?.length ?? 0) < 2) {
          return; 
        }
      }
      int layGiaTri(int h, int c) {
        if (_danhSachOTrong3x3.any((vt) => vt[0] == h && vt[1] == c)) {
          return int.tryParse(_giaTriOTrinh3x3["${h}_$c"] ?? "0") ?? 0;
        }
        return _layGiaTriChuan3x3(h, c);
      }
      int v11 = layGiaTri(1, 1), v12 = layGiaTri(1, 2), v13 = layGiaTri(1, 3);
      int v21 = layGiaTri(2, 1), v22 = layGiaTri(2, 2), v23 = layGiaTri(2, 3);
      int v31 = layGiaTri(3, 1), v32 = layGiaTri(3, 2), v33 = layGiaTri(3, 3);
      bool h1 = _bangHienTai.dauHang1 == "-" ? (v11 - v12 == v13) : (v11 + v12 == v13);
      bool h2 = _bangHienTai.dauHang2 == "-" ? (v21 - v22 == v23) : (v21 + v22 == v23);
      bool h3 = _bangHienTai.dauHang3 == "-" ? (v31 - v32 == v33) : (v31 + v32 == v33);
      bool c1 = _bangHienTai.dauCot1 == "-" ? (v11 - v21 == v31) : (v11 + v21 == v31);
      bool c2 = _bangHienTai.dauCot2 == "-" ? (v12 - v22 == v32) : (v12 + v22 == v32);
      bool c3 = _bangHienTai.dauCot3 == "-" ? (v13 - v23 == v33) : (v13 + v23 == v33);
      if (h1 && h2 && h3 && c1 && c2 && c3) {
        _dangXuLyDung = true;
        _thongBaoDung();
      } else {
        _dangXuLyDung = true;
        _thongBaoSai();
      }
    } else {
      for (var key in _danhSachKeysOTrongLienHoan) {
        String? nhap = _giaTriNhapLienHoan[key];
        if (nhap == null || nhap.isEmpty) {
          return; 
        }
      }
      for (var key in _danhSachKeysOTrongLienHoan) {
        int valGoc = 0;
        if (key == "top1") valGoc = _cauHoiLienHoanHienTai.top1;
        if (key == "mid1") valGoc = _cauHoiLienHoanHienTai.mid1;
        if (key == "bot1") valGoc = _cauHoiLienHoanHienTai.bot1;
        if (key == "rowLeft") valGoc = _cauHoiLienHoanHienTai.rowLeft;
        if (key == "rowMid2") valGoc = _cauHoiLienHoanHienTai.rowMid2;
        if (key == "rowResult") valGoc = _cauHoiLienHoanHienTai.rowResult;
        if (key == "top2") valGoc = _cauHoiLienHoanHienTai.top2;
        if (key == "bot2") valGoc = _cauHoiLienHoanHienTai.bot2;
        if (valGoc >= 10 && (_giaTriNhapLienHoan[key]?.length ?? 0) < 2) {
          return;
        }
      }
      int getVal(String key, int valGoc) {
        String? nhap = _giaTriNhapLienHoan[key];
        if (nhap != null && nhap.isNotEmpty) {
          return int.tryParse(nhap) ?? valGoc;
        }
        return valGoc;
      }
      int top1 = getVal("top1", _cauHoiLienHoanHienTai.top1);
      int mid1 = getVal("mid1", _cauHoiLienHoanHienTai.mid1);
      int bot1 = getVal("bot1", _cauHoiLienHoanHienTai.bot1);
      int rowLeft = getVal("rowLeft", _cauHoiLienHoanHienTai.rowLeft);
      int rowMid2 = getVal("rowMid2", _cauHoiLienHoanHienTai.rowMid2);
      int rowResult = getVal("rowResult", _cauHoiLienHoanHienTai.rowResult);
      int top2 = getVal("top2", _cauHoiLienHoanHienTai.top2);
      int bot2 = getVal("bot2", _cauHoiLienHoanHienTai.bot2);
      bool cot1Dung = _cauHoiLienHoanHienTai.dauDichV1 == "+" 
          ? (top1 + mid1 == bot1) 
          : (top1 - mid1 == bot1);
      int ketQuaBuoc1 = _cauHoiLienHoanHienTai.dauHangNgang1 == "+"
          ? (rowLeft + mid1)
          : (rowLeft - mid1);
      bool hangNgangDung = _cauHoiLienHoanHienTai.dauHangNgang2 == "+"
          ? (ketQuaBuoc1 + rowMid2 == rowResult)
          : (ketQuaBuoc1 - rowMid2 == rowResult);
      bool cot2Dung = _cauHoiLienHoanHienTai.dauDichV2 == "+" 
          ? (top2 + rowResult == bot2) 
          : (top2 - rowResult == bot2); 
      if (cot1Dung && hangNgangDung && cot2Dung) {
        _dangXuLyDung = true;
        _thongBaoDung();
      } else {
        _dangXuLyDung = true;
        _thongBaoSai();
      }
    }
  }
  void _hienThiBongBongOverlay() {
    _ungDungGiaiPhongOverlay();
    _overlayEntryHienTai = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black26,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                decoration: BoxDecoration(
                  color: _mauThongBao,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _mauThongBao.withOpacity(0.35),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_thongBao.contains('⭐') ? '⭐' : '💡', style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      _thongBao,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _thongBao.contains('⭐') ? 'Cùng thử câu tiếp theo nhé! 🎉' : 'Bé kiểm tra lại phép tính nhé! 💪',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntryHienTai!);
  }
  void _ungDungGiaiPhongOverlay() {
    _overlayEntryHienTai?.remove();
    _overlayEntryHienTai = null;
  }
  void _thongBaoDung() {
    if (!mounted) return;
    String loaiCauHoi = _laDangDanCheo ? "🧩 Toán Đan Chéo" : "📊 Bảng Tính 3x3";
    int soThuTuMoi = _lichSuLamBai.length + 1;
    _lichSuLamBai.add(NhatKyCauHoi(
      soThuTu: soThuTuMoi, 
      tenLoai: loaiCauHoi, 
      laDung: true,
      laDangDanCheo: _laDangDanCheo,
      mau3x3: _laDangDanCheo ? null : _bangHienTai,
      danhSachOTrong3x3: _laDangDanCheo ? null : List.from(_danhSachOTrong3x3),
      mauDanCheo: _laDangDanCheo ? _cauHoiLienHoanHienTai : null,
      danhSachKeysOTrongLienHoan: _laDangDanCheo ? List.from(_danhSachKeysOTrongLienHoan) : null,
      duLieuBeDien: _laDangDanCheo ? Map.from(_giaTriNhapLienHoan) : Map.from(_giaTriOTrinh3x3),
    ));
    setState(() {
      _soLanDung++;
      _thongBao = "⭐ Bé siêu quá! Đúng rồi!";
      _mauThongBao = Colors.green.shade600;
    });
    _hienThiBongBongOverlay();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _ungDungGiaiPhongOverlay();
      _taoCauHoiMoi();
      _dangXuLyDung = false;
    });
  }
  void _thongBaoSai() {
    if (!mounted) return;
    String loaiCauHoi = _laDangDanCheo ? "🧩 Toán Đan Chéo" : "📊 Bảng Tính 3x3";
    int soThuTuMoi = _lichSuLamBai.length + 1;
    _lichSuLamBai.add(NhatKyCauHoi(
      soThuTu: soThuTuMoi, 
      tenLoai: loaiCauHoi, 
      laDung: false,
      laDangDanCheo: _laDangDanCheo,
      mau3x3: _laDangDanCheo ? null : _bangHienTai,
      danhSachOTrong3x3: _laDangDanCheo ? null : List.from(_danhSachOTrong3x3),
      mauDanCheo: _laDangDanCheo ? _cauHoiLienHoanHienTai : null,
      danhSachKeysOTrongLienHoan: _laDangDanCheo ? List.from(_danhSachKeysOTrongLienHoan) : null,
      duLieuBeDien: _laDangDanCheo ? Map.from(_giaTriNhapLienHoan) : Map.from(_giaTriOTrinh3x3),
    ));
    setState(() {
      _thongBao = "Chưa đúng rồi bé ơi!";
      _mauThongBao = Colors.red.shade400;
    });
    _hienThiBongBongOverlay();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _ungDungGiaiPhongOverlay();
      _dangXuLyDung = false;
    });
  }
  // Mở màn hình xem lại chi tiết bài làm (Đã bỏ nút phụ phía dưới, toàn bộ không gian dành cho bảng)
  void _moManHinhXemLaiCauHoi(NhatKyCauHoi item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Câu ${item.soThuTu} (${item.laDung ? 'Đúng' : 'Sai'})", 
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: item.laDung ? Colors.green.shade800 : Colors.red.shade800)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  Navigator.pop(context); // Đóng hộp thoại chi tiết câu hỏi
                  _hienThiBangKiemTraLichSu(); // Quay ngược trở lại bảng tổng quan lịch sử
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                item.laDangDanCheo
                    ? _buildGiaoDienXemLaiDanCheo(item.mauDanCheo!, item.danhSachKeysOTrongLienHoan!, item.duLieuBeDien)
                    : _buildGiaoDienXemLai3x3(item.mau3x3!, item.danhSachOTrong3x3!, item.duLieuBeDien),
              ],
            ),
          ),
          // Đã xóa hoàn toàn actions chứa nút "Quay lại danh sách" để tiết kiệm không gian
        );
      },
    );
  }
  // Giao diện xem lại bảng 3x3 kích thước lớn rõ nét, vừa vặn màn hình
  Widget _buildGiaoDienXemLai3x3(MauBangTinh mau, List<List<int>> oTrong, Map<String, String> duLieu) {
    int layGiaTriChuan(int hang, int cot) {
      if (hang == 1) return cot == 1 ? mau.c1r1 : (cot == 2 ? mau.c2r1 : mau.c3r1);
      if (hang == 2) return cot == 1 ? mau.c1r2 : (cot == 2 ? mau.c2r2 : mau.c3r2);
      return cot == 1 ? mau.c1r3 : (cot == 2 ? mau.c2r3 : mau.c3r3);
    }
    Widget xayDungo(int hang, int cot) {
      bool laOTrg = oTrong.any((vt) => vt[0] == hang && vt[1] == cot);
      int valChuan = layGiaTriChuan(hang, cot);
      if (laOTrg) {
        String key = "${hang}_$cot";
        String valBeNhap = duLieu[key] ?? "";
        int soBeNhap = int.tryParse(valBeNhap) ?? -999;
        bool laSai = soBeNhap != valChuan;
        return Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: laSai ? Colors.red.shade100 : const Color(0xFFFFF8E1),
            shape: BoxShape.circle,
            border: Border.all(color: laSai ? Colors.red.shade600 : const Color(0xFFFFA000), width: 2.0),
          ),
          child: Center(
            child: Text(
              valBeNhap,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: laSai ? Colors.red.shade900 : const Color(0xFF4E342E),
              ),
            ),
          ),
        );
      } else {
        return Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7F6),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7E57C2), width: 2.5),
          ),
          child: Center(
            child: Text("$valChuan", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF512DA8))),
          ),
        );
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1C4E9), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [xayDungo(1, 1), _buildDauPhepTinh(mau.dauHang1), xayDungo(1, 2), _buildDauPhepTinh("="), xayDungo(1, 3)],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDauPhepTinhDoc(mau.dauCot1), const SizedBox(width: 62),
                _buildDauPhepTinhDoc(mau.dauCot2), const SizedBox(width: 52),
                _buildDauPhepTinhDoc(mau.dauCot3),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [xayDungo(2, 1), _buildDauPhepTinh(mau.dauHang2), xayDungo(2, 2), _buildDauPhepTinh("="), xayDungo(2, 3)],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDauPhepTinhDoc("="), const SizedBox(width: 62),
                _buildDauPhepTinhDoc("="), const SizedBox(width: 52),
                _buildDauPhepTinhDoc("="),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [xayDungo(3, 1), _buildDauPhepTinh(mau.dauHang3), xayDungo(3, 2), _buildDauPhepTinh("="), xayDungo(3, 3)],
          ),
        ],
      ),
    );
  }
  // Giao diện xem lại đan chéo kích thước lớn rõ nét, vừa vặn màn hình
  Widget _buildGiaoDienXemLaiDanCheo(CauHoiLienHoan mau, List<String> oTrongKeys, Map<String, String> duLieu) {
    Widget xayDungOLienHoan(String key, int valGoc) {
      bool laOTrg = oTrongKeys.contains(key);
      String valBeNhap = laOTrg ? (duLieu[key] ?? "") : valGoc.toString();
      int soBeNhap = int.tryParse(valBeNhap) ?? -999;
      bool laSai = laOTrg && (soBeNhap != valGoc);
      return Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: laSai ? Colors.red.shade100 : (laOTrg ? const Color(0xFFFFF8E1) : Colors.white),
          shape: BoxShape.circle,
          border: Border.all(
            color: laSai ? Colors.red.shade600 : (laOTrg ? const Color(0xFFFFA000) : const Color(0xFF7E57C2)),
            width: 2.5,
          ),
        ),
        child: Center(
          child: Text(
            valBeNhap,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: laSai ? Colors.red.shade900 : const Color(0xFF4E342E),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1C4E9), width: 2),
      ),
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              const SizedBox.shrink(), const SizedBox.shrink(),
              Center(child: xayDungOLienHoan("top1", mau.top1)),
              const SizedBox.shrink(), const SizedBox.shrink(), const SizedBox.shrink(),
              Center(child: xayDungOLienHoan("top2", mau.top2)),
            ],
          ),
          TableRow(
            children: [
              const SizedBox.shrink(), const SizedBox.shrink(),
              Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Center(child: Text(mau.dauDichV1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF7E57C2))))),
              const SizedBox.shrink(), const SizedBox.shrink(), const SizedBox.shrink(),
              Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Center(child: Text(mau.dauDichV2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF7E57C2))))),
            ],
          ),
          TableRow(
            children: [
              Center(child: xayDungOLienHoan("rowLeft", mau.rowLeft)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _buildDauPhepTinh(mau.dauHangNgang1)),
              Center(child: xayDungOLienHoan("mid1", mau.mid1)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _buildDauPhepTinh(mau.dauHangNgang2)),
              Center(child: xayDungOLienHoan("rowMid2", mau.rowMid2)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _buildDauPhepTinh("=")),
              Center(child: xayDungOLienHoan("rowResult", mau.rowResult)),
            ],
          ),
          TableRow(
            children: [
              const SizedBox.shrink(), const SizedBox.shrink(),
              const Center(child: Text("=", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF7E57C2)))),
              const SizedBox.shrink(), const SizedBox.shrink(), const SizedBox.shrink(),
              const Center(child: Text("=", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF7E57C2)))),
            ],
          ),
          TableRow(
            children: [
              const SizedBox.shrink(), const SizedBox.shrink(),
              Center(child: xayDungOLienHoan("bot1", mau.bot1)),
              const SizedBox.shrink(), const SizedBox.shrink(), const SizedBox.shrink(),
              Center(child: xayDungOLienHoan("bot2", mau.bot2)),
            ],
          ),
        ],
      ),
    );
  }
  // Bảng danh sách tổng quan lịch sử
  void _hienThiBangKiemTraLichSu() {
    int tongSoCau = _lichSuLamBai.length;
    int soCauDung = _lichSuLamBai.where((e) => e.laDung).length;
    int soCauSai = tongSoCau - soCauDung;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assessment_rounded, color: Colors.purple, size: 26),
                  SizedBox(width: 8),
                  Text("Kết Quả Làm Bài", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6A1B9A))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _itemThongKe("Tổng câu", "$tongSoCau", Colors.blue.shade700),
                      _itemThongKe("Đúng", "$soCauDung", Colors.green.shade700),
                      _itemThongKe("Sai", "$soCauSai", Colors.red.shade600),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  tongSoCau == 0
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text("Bé chưa hoàn thành câu hỏi nào cả!", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lichSuLamBai.length,
                          itemBuilder: (context, index) {
                            var item = _lichSuLamBai[index];
                            return InkWell(
                              onTap: () {
                                Navigator.pop(context); // Đóng bảng tổng quan lịch sử
                                _moManHinhXemLaiCauHoi(item); // Mở chi tiết câu hỏi
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: item.laDung ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: item.laDung ? Colors.green.shade200 : Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: item.laDung ? Colors.green : Colors.red,
                                          child: Text(
                                            "${item.soThuTu}",
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Câu ${item.soThuTu}: ${item.tenLoai}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4E342E)),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item.laDung ? Colors.green.shade100 : Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item.laDung ? "Đúng ✓" : "Sai ✗",
                                            style: TextStyle(
                                              color: item.laDung ? Colors.green.shade800 : Colors.red.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _itemThongKe(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
  int _layGiaTriChuan3x3(int hang, int cot) {
    if (hang == 1) return cot == 1 ? _bangHienTai.c1r1 : (cot == 2 ? _bangHienTai.c2r1 : _bangHienTai.c3r1);
    if (hang == 2) return cot == 1 ? _bangHienTai.c1r2 : (cot == 2 ? _bangHienTai.c2r2 : _bangHienTai.c3r2);
    return cot == 1 ? _bangHienTai.c1r3 : (cot == 2 ? _bangHienTai.c2r3 : _bangHienTai.c3r3);
  }
  @override
  Widget build(BuildContext context) {
    String chuoiDung = _soLanDung.toString().padLeft(2, '0');
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF8F4FC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _nutQuayLaiCam(onTap: () => Navigator.pop(context)),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    _laDangDanCheo ? "🧩 Toán Đan Chéo" : "📊 Bảng Tính 3x3",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF6A1B9A)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _hienThiBangKiemTraLichSu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade600, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        chuoiDung,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.amber.shade900),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.amber, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _laDangDanCheo ? _buildGiaoDienDanCheoDungChuan() : _buildGiaoDien3x3(),
                  const SizedBox(height: 10),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD1C4E9), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var i = 0; i <= 9; i++)
                          _phimSoNgang(i.toString()),
                        _phimXoaNgang(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildGiaoDien3x3() {
    String dauH1 = _bangHienTai.dauHang1;
    String dauH2 = _bangHienTai.dauHang2;
    String dauH3 = _bangHienTai.dauHang3; 
    String dauC1 = _bangHienTai.dauCot1;
    String dauC2 = _bangHienTai.dauCot2;
    String dauC3 = _bangHienTai.dauCot3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD1C4E9), width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFF6A1B9A).withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildO3x3(1, 1), _buildDauPhepTinh(dauH1), 
              _buildO3x3(1, 2), _buildDauPhepTinh("="), 
              _buildO3x3(1, 3),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDauPhepTinhDoc(dauC1), const SizedBox(width: 72),
                _buildDauPhepTinhDoc(dauC2), const SizedBox(width: 62),
                _buildDauPhepTinhDoc(dauC3),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildO3x3(2, 1), _buildDauPhepTinh(dauH2), 
              _buildO3x3(2, 2), _buildDauPhepTinh("="), 
              _buildO3x3(2, 3),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDauPhepTinhDoc("="), const SizedBox(width: 72),
                _buildDauPhepTinhDoc("="), const SizedBox(width: 62),
                _buildDauPhepTinhDoc("="),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildO3x3(3, 1), _buildDauPhepTinh(dauH3), 
              _buildO3x3(3, 2), _buildDauPhepTinh("="), 
              _buildO3x3(3, 3),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildO3x3(int hang, int cot) {
    bool laOTrg = _danhSachOTrong3x3.any((vt) => vt[0] == hang && vt[1] == cot);
    int giaTriChuan = _layGiaTriChuan3x3(hang, cot);
    if (laOTrg) {
      String key = "${hang}_$cot";
      bool dangChon = _oDangChonKey == key;
      String giaTriHienThi = _giaTriOTrinh3x3[key] ?? "";
      return GestureDetector(
        onTap: () => setState(() => _oDangChonKey = key),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            shape: BoxShape.circle,
            border: Border.all(color: dangChon ? Colors.red.shade500 : const Color(0xFFFFA000), width: dangChon ? 3.5 : 2.5),
          ),
          child: Center(
            child: Text(
              giaTriHienThi.isEmpty ? "?" : giaTriHienThi,
              style: TextStyle(fontSize: giaTriHienThi.length > 1 ? 16 : 22, fontWeight: FontWeight.w900, color: giaTriHienThi.isEmpty ? const Color(0xFFBDBDBD) : const Color(0xFF4E342E)),
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF7E57C2), width: 2.5),
        ),
        child: Center(
          child: Text(giaTriChuan.toString(), style: TextStyle(fontSize: giaTriChuan > 9 ? 16 : 22, fontWeight: FontWeight.w900, color: const Color(0xFF512DA8))),
        ),
      );
    }
  }
  Widget _buildGiaoDienDanCheoDungChuan() {
    return Container(
      width: 360,  
      height: 240, 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD1C4E9),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              const SizedBox.shrink(), const SizedBox.shrink(),
              Center(child: _buildOLienHoan("top1", _cauHoiLienHoanHienTai.top1)),
              const SizedBox.shrink(), const SizedBox.shrink(), const SizedBox.shrink(),
              Center(child: _buildOLienHoan("top2", _cauHoiLienHoanHienTai.top2)),
            ],
          ),
          TableRow(
            children: [
              const SizedBox.shrink(), const SizedBox.shrink(),
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Center(child: Text(_cauHoiLienHoanHienTai.dauDichV1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF7E57C2))))),
              const SizedBox.shrink(), const SizedBox.shrink(), const SizedBox.shrink(),
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Center(child: Text(_cauHoiLienHoanHienTai.dauDichV2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF7E57C2))))),
            ],
          ),
          TableRow(
            children: [
              Center(child: _buildOLienHoan("rowLeft", _cauHoiLienHoanHienTai.rowLeft)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildDauPhepTinh(_cauHoiLienHoanHienTai.dauHangNgang1)),
              Center(child: _buildOLienHoan("mid1", _cauHoiLienHoanHienTai.mid1)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildDauPhepTinh(_cauHoiLienHoanHienTai.dauHangNgang2)),
              Center(child: _buildOLienHoan("rowMid2", _cauHoiLienHoanHienTai.rowMid2)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildDauPhepTinh("=")),
              Center(child: _buildOLienHoan("rowResult", _cauHoiLienHoanHienTai.rowResult)),
            ],
          ),
          TableRow(
            children: [
              const SizedBox.shrink(), const SizedBox.shrink(),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Center(child: Text("=", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF7E57C2))))),
              const SizedBox.shrink(), const SizedBox.shrink(), const SizedBox.shrink(),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Center(child: Text("=", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF7E57C2))))),
            ],
          ),
          TableRow(
            children: [
              const SizedBox.shrink(), const SizedBox.shrink(),
              Center(child: _buildOLienHoan("bot1", _cauHoiLienHoanHienTai.bot1)),
              const SizedBox.shrink(), const SizedBox.shrink(), const SizedBox.shrink(),
              Center(child: _buildOLienHoan("bot2", _cauHoiLienHoanHienTai.bot2)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildOLienHoan(String key, int valGoc) {
    bool laOTrg = _danhSachKeysOTrongLienHoan.contains(key);
    bool dangChon = _oDangChonKey == key;
    String val = laOTrg ? (_giaTriNhapLienHoan[key] ?? "") : valGoc.toString();
    return GestureDetector(
      onTap: laOTrg ? () => setState(() => _oDangChonKey = key) : null,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: laOTrg ? const Color(0xFFFFF8E1) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: dangChon ? Colors.red.shade500 : (laOTrg ? const Color(0xFFFFA000) : const Color(0xFF7E57C2)),
            width: dangChon ? 3.5 : 2.5,
          ),
        ),
        child: Center(
          child: Text(
            laOTrg && val.isEmpty ? "?" : val,
            style: TextStyle(
              fontSize: val.length > 1 ? 15 : 18,
              fontWeight: FontWeight.w900,
              color: laOTrg && val.isEmpty ? const Color(0xFFBDBDBD) : const Color(0xFF4E342E),
            ),
          ),
        ),
      ),
    );
  }
  Widget _phimSoNgang(String so) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: SizedBox(
          height: 33,
          child: ElevatedButton(
            onPressed: () => _nhapSo(so),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF512DA8),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: Text(so, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF512DA8))),
          ),
        ),
      ),
    );
  }
  Widget _phimXoaNgang() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: SizedBox(
          height: 30,
          child: ElevatedButton(
            onPressed: _xoaSo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: const Icon(Icons.backspace_rounded, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
  Widget _buildDauPhepTinh(String dau) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        dau,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dau == "=" ? const Color(0xFF512DA8) : const Color(0xFF9575CD)),
      ),
    );
  }
  Widget _buildDauPhepTinhDoc(String dau) {
    return Text(
      dau,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dau == "=" ? const Color(0xFF512DA8) : const Color(0xFF9575CD)),
    );
  }
  Widget _nutQuayLaiCam({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white, 
            shape: BoxShape.circle,
            border: Border.all(color: Colors.yellow.shade700, width: 2), 
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.4), 
                blurRadius: 6, 
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded, 
              color: Colors.grey.shade700, 
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

//TRANG MÊ CUNG
class NhatKyMeCung {
  final int soThuTu;
  final String moTa;
  final String chuoiHienThi;
  final int dapAnDung;
  final int luaChonCuaBe;
  final bool laDung;
  String get chuoi => chuoiHienThi;
  NhatKyMeCung({
    required this.soThuTu,
    required this.moTa,
    required this.chuoiHienThi,
    required this.dapAnDung,
    required this.luaChonCuaBe,
    required this.laDung,
  });
}
class TrangMeCungSo extends StatefulWidget {
  const TrangMeCungSo({super.key});
  @override
  State<TrangMeCungSo> createState() => _TrangMeCungSoState();
}
class _TrangMeCungSoState extends State<TrangMeCungSo> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late String cauHoiMoTa;
  late String chuoiHienThi;
  int dapAnDung = 1;
  List<int> danhSachLuaChon = [1, 2, 3];
  late String goiYSai;
  late String goiYDung;
  String _thongBaoTrangThai = "";
  // Biến quản lý thứ tự ngẫu nhiên, chống trùng lặp
  final List<int> _danhSachChiSoChuaDung = [];
  int _currentIndex = -1;
  // Quản lý lịch sử làm bài và điểm số
  final List<NhatKyMeCung> _lichSuLamBai = [];
  int _soCauDung = 0;
  int _soCauSai = 0;
  // Dữ liệu thử thách đầy đủ 100%
  final List<Map<String, dynamic>> _khoThuThach = [
    // DÃY SỐ LIÊN TIẾP
    { "moTa": "Dãy số chẵn liên tiếp", "chuoi": "4 ➡️ ❓ ➡️ 8 ➡️ 10", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Đây là các số chẵn đứng cạnh nhau!", "dung": "Chính xác tuyệt đối! 4, 6, 8, 10!" },
{ "moTa": "Dãy số liên tiếp cơ bản (+1)", "chuoi": "1 ➡️ 2 ➡️ 3 ➡️ ❓", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Đếm tiến thêm 1 bước từ số 3 nhé!", "dung": "Chính xác! 1, 2, 3, 4 rất tuyệt vời!" },
{ "moTa": "Dãy số liên tiếp tiến dần", "chuoi": "4 ➡️ 5 ➡️ 6 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Số tiếp theo sau số 6 là số mấy nào?", "dung": "Đúng rồi! Số 7 là đáp án chuẩn xác!" },
{ "moTa": "Dãy số liên tiếp bắt ", "chuoi": "7 ➡️ 8 ➡️ 9 ➡️ ❓", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Cộng thêm 1 vào số 9 nhé bé!", "dung": "Xuất sắc! Sau số 9 là số 10!" },
{ "moTa": "Dãy số liên tiếp khoảng giữa", "chuoi": "10 ➡️ 11 ➡️ ❓ ➡️ 13", "dapAn": 12, "luaChon": [11, 12, 14], "sai": "Gợi ý: Số đứng giữa 11 và 13 là số mấy?", "dung": "Quá thông minh! 10, 11, 12, 13 hoàn hảo!" },
{ "moTa": "Dãy số liên tiếp ẩn số ở đầu", "chuoi": "❓ ➡️ 6 ➡️ 7 ➡️ 8", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Số đứng trước số 6 trong dãy đếm tiến là gì?", "dung": "Tuyệt đỉnh! Số 5 đứng trước số 6!" },
{ "moTa": "Dãy số chẵn tăng dần", "chuoi": "2 ➡️ 4 ➡️ ❓ ➡️ 8", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Đếm thêm 2 đơn vị từ số 4 nhé!", "dung": "Chính xác! 2, 4, 6, 8 chuẩn luôn!" },
{ "moTa": "Dãy số chẵn tăng dần ", "chuoi": "6 ➡️ 8 ➡️ 10 ➡️ ❓", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Cộng thêm 2 vào số 10 nào bé!", "dung": "Tuyệt vời! Sau số 10 là số 12!" },
{ "moTa": "Dãy số chẵn có ẩn số ở đầu", "chuoi": "❓ ➡️ 4 ➡️ 6 ➡️ 8", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Số chẵn đầu tiên đứng trước số 4 là gì?", "dung": "Quá giỏi! Số 2 đứng trước số 4!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số đầu)", "chuoi": "❓ ➡️ 3 ➡️ 5 ➡️ 7", "dapAn": 1, "luaChon": [1, 2, 4], "sai": "Gợi ý: Số lẻ nào bớt đi 2 đơn vị từ số 3 nhỉ?", "dung": "Chính xác! Dãy số là: 1, 3, 5, 7!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số ở giữa)", "chuoi": "1 ➡️ 3 ➡️ ❓ ➡️ 7", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Đếm thêm 2 đơn vị từ số 3 nhé!", "dung": "Tuyệt vời! 1, 3, 5, 7 chuẩn luôn!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số cuối)", "chuoi": "3 ➡️ 5 ➡️ 7 ➡️ ❓", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Cộng thêm 2 vào số 7 nào bé!", "dung": "Xuất sắc! Sau số 7 là số 9!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số đầu)", "chuoi": "❓ ➡️ 7 ➡️ 9 ➡️ 11", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Số lẻ nào nhỏ hơn số 7 hai đơn vị bé ơi?", "dung": "Chính xác! Dãy số hoàn chỉnh là: 5, 7, 9, 11!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số ở giữa)", "chuoi": "5 ➡️ 7 ➡️ ❓ ➡️ 11", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Số lẻ đứng ngay sau số 7 là số mấy nhỉ?", "dung": "Đúng rồi! 5, 7, 9, 11 rất giỏi!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số ở giữa)", "chuoi": "7 ➡️ ❓ ➡️ 11 ➡️ 13", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Đếm nhảy 2 bước từ số 7 nhé!", "dung": "Tuyệt vời! Số cần tìm là 9!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số cuối)", "chuoi": "9 ➡️ 11 ➡️ 13 ➡️ ❓", "dapAn": 15, "luaChon": [14, 15, 16], "sai": "Gợi ý: Lấy 13 cộng thêm 2 đơn vị nào!", "dung": "Chính xác! Tiếp theo 13 sẽ là 15!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số ở giữa)", "chuoi": "11 ➡️ 13 ➡️ ❓ ➡️ 17", "dapAn": 15, "luaChon": [14, 15, 16], "sai": "Gợi ý: Số lẻ nào ở giữa số 13 và 17 nhỉ?", "dung": "Rất giỏi! 11, 13, 15, 17!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số đầu)", "chuoi": "❓ ➡️ 15 ➡️ 17 ➡️ 19", "dapAn": 13, "luaChon": [12, 13, 14], "sai": "Gợi ý: Số lẻ nào ngay trước số 15 bé ơi?", "dung": "Chuẩn xác! Số đứng đầu là 13!" },
  { "moTa": "Dãy số lẻ tăng dần (Ẩn số cuối)", "chuoi": "13 ➡️ 15 ➡️ 17 ➡️ ❓", "dapAn": 19, "luaChon": [18, 19, 20], "sai": "Gợi ý: Cộng thêm 2 vào số 17 nào bé!", "dung": "Tuyệt vời! Đáp án chính xác là 19!" },
{ "moTa": "Dãy số đếm tiến từ số 5", "chuoi": "5 ➡️ 6 ➡️ ❓ ➡️ 8", "dapAn": 7, "luaChon": [6, 7, 9], "sai": "Gợi ý: Điền số nằm giữa 6 và 8 nhé!", "dung": "Đúng rồi! 5, 6, 7, 8 hoàn hảo!" },
{ "moTa": "Dãy số đếm tiến từ số 8", "chuoi": "8 ➡️ 9 ➡️ 10 ➡️ ❓", "dapAn": 11, "luaChon": [10, 11, 12], "sai": "Gợi ý: Sau số 10 là số mấy nào?", "dung": "Xuất sắc! Số 11 là đáp án chính xác!" },
{ "moTa": "Dãy số đếm tiến bắt đầu từ số 11", "chuoi": "11 ➡️ 12 ➡️ 13 ➡️ ❓", "dapAn": 14, "luaChon": [13, 14, 15], "sai": "Gợi ý: Thêm 1 bước đếm nữa từ số 13!", "dung": "Chính xác! 11, 12, 13, 14 rất tuyệt!" },
{ "moTa": "Dãy số đếm tiến bắt đầu từ số 12", "chuoi": "12 ➡️ 13 ➡️ ❓ ➡️ 15", "dapAn": 14, "luaChon": [13, 14, 16], "sai": "Gợi ý: Số đứng ngay sau số 13 là gì?", "dung": "Quá thông minh! 12, 13, 14, 15!" },
{ "moTa": "Dãy số đếm tiến kết thúc ở 17", "chuoi": "14 ➡️ 15 ➡️ 16 ➡️ ❓", "dapAn": 17, "luaChon": [16, 17, 18], "sai": "Gợi ý: Đếm tiếp một bước từ số 16 nhé!", "dung": "Đúng thế! Số 17 tiếp nối rất chuẩn!" },
{ "moTa": "Dãy số đếm tiến lớn hơn", "chuoi": "15 ➡️ 16 ➡️ ❓ ➡️ 18", "dapAn": 17, "luaChon": [16, 17, 19], "sai": "Gợi ý: Tìm số ở giữa số 16 và số 18!", "dung": "Tuyệt đỉnh! 15, 16, 17, 18!" },
{ "moTa": "Dãy số đếm tiến qua mốc 20", "chuoi": "17 ➡️ 18 ➡️ 19 ➡️ ❓", "dapAn": 20, "luaChon": [19, 20, 21], "sai": "Gợi ý: Số tròn chục tiếp theo sau 19 là gì?", "dung": "Xuất sắc! Sau số 19 chính là số 20!" },
{ "moTa": "Dãy số chẵn lớn hơn", "chuoi": "8 ➡️ 10 ➡️ 12 ➡️ ❓", "dapAn": 14, "luaChon": [13, 14, 15], "sai": "Gợi ý: Cộng thêm 2 đơn vị vào số 12!", "dung": "Quá đỉnh! Số 14 là đáp án đúng!" },
{ "moTa": "Dãy số chẵn có ẩn số ở giữa", "chuoi": "10 ➡️ ❓ ➡️ 14 ➡️ 16", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Số chẵn nằm giữa 10 và 14 là mấy?", "dung": "Đúng rồi! 10, 12, 14, 16 rất chính xác!" },
{ "moTa": "Dãy số chẵn bắt đầu từ số 12", "chuoi": "12 ➡️ 14 ➡️ ❓ ➡️ 18", "dapAn": 16, "luaChon": [15, 16, 17], "sai": "Gợi ý: Số chẵn nằm giữa 14 và 18 là gì?", "dung": "Chính xác tuyệt đối! 12, 14, 16, 18!" },
{ "moTa": "Dãy số chẵn kết thúc ở 20", "chuoi": "14 ➡️ 16 ➡️ 18 ➡️ ❓", "dapAn": 20, "luaChon": [19, 20, 21], "sai": "Gợi ý: Thêm 2 đơn vị vào số 18 nhé bé!", "dung": "Tuyệt vời! 14, 16, 18, 20 hoàn hảo!" },
{ "moTa": "Dãy số đếm tiến bắt đầu từ số 3", "chuoi": "3 ➡️ ❓ ➡️ 5 ➡️ 6", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Số đứng ngay sau số 3 là số mấy?", "dung": "Đúng rồi! 3, 4, 5, 6 thật xuất sắc!" },
{ "moTa": "Dãy số đếm tiến ẩn số ở giữa", "chuoi": "6 ➡️ 7 ➡️ ❓ ➡️ 9", "dapAn": 8, "luaChon": [7, 8, 10], "sai": "Gợi ý: Đếm tiến từ 7 lên một bước nữa nào!", "dung": "Chính xác! 6, 7, 8, 9 rất giỏi!" },
{ "moTa": "Dãy số đếm tiến bắt đầu từ số 9", "chuoi": "9 ➡️ ❓ ➡️ 11 ➡️ 12", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Số nằm giữa 9 và 11 là số mấy?", "dung": "Quá thông minh! Số 10 là đáp án chuẩn!" },
{ "moTa": "Dãy số đếm tiến vùng số lớn", "chuoi": "13 ➡️ 14 ➡️ ❓ ➡️ 16", "dapAn": 15, "luaChon": [14, 15, 17], "sai": "Gợi ý: Số liền sau số 14 là số mấy?", "dung": "Tuyệt đỉnh! 13, 14, 15, 16 chính xác!" },
{ "moTa": "Dãy số đếm tiến gần mốc 20", "chuoi": "16 ➡️ ❓ ➡️ 18 ➡️ 19", "dapAn": 17, "luaChon": [16, 17, 18], "sai": "Gợi ý: Số đứng giữa 16 và 18 là gì?", "dung": "Đúng rồi! Số 17 nằm ở giữa rất chính xác!" },
{ "moTa": "Dãy số đếm tiến kết thúc mốc 19", "chuoi": "16 ➡️ 17 ➡️ 18 ➡️ ❓", "dapAn": 19, "luaChon": [18, 19, 20], "sai": "Gợi ý: Thêm 1 đơn vị vào số 18 nhé bé!", "dung": "Xuất sắc! 16, 17, 18, 19 hoàn thành xuất sắc!" },
{ "moTa": "Ẩn số ở đầu dãy", "chuoi": "❓ ➡️ 2 ➡️ 3 ➡️ 4", "dapAn": 1, "luaChon": [0, 1, 2], "sai": "Trước số 2 trong dãy đếm tiến là số mấy?", "dung": "Số 1 đứng đầu tiên trước số 2!" },
{ "moTa": "Ẩn số ở đầu dãy (+1)", "chuoi": "❓ ➡️ 2 ➡️ 3 ➡️ 4 ➡️ 5", "dapAn": 1, "luaChon": [0, 1, 2], "sai": "Gợi ý: Trước số 2 là số đếm bắt đầu tiên!", "dung": "Chính xác tuyệt đối! Số 1 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy (Nhảy cóc +2)", "chuoi": "❓ ➡️ 4 ➡️ 6 ➡️ 8", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Lùi lại 2 đơn vị từ số 4 nhé!", "dung": "Quá thông minh! Số 2 đứng trước số 4!" },
{ "moTa": "Ẩn số ở đầu dãy đếm lùi", "chuoi": "❓ ➡️ 4 ➡️ 3 ➡️ 2", "dapAn": 5, "luaChon": [5, 6, 9], "sai": "Gợi ý: Trước số 4 theo chiều tiến ngược lại là số mấy?", "dung": "Xuất sắc! Số 5 đứng đầu dãy!" },
{ "moTa": "Dãy số gấp đôi (Tìm số đầu tiên)", "chuoi": "❓ ➡️ 2 ➡️ 4 ➡️ 8", "dapAn": 1, "luaChon": [0, 1, 2], "sai": "Gợi ý: Lấy số mấy nhân với 2 để được 2 nhỉ?", "dung": "Tuyệt đỉnh! 1 nhân đôi lên là 2 đó bé!" },
{ "moTa": "Ẩn số ở đầu dãy đếm tiến ", "chuoi": "❓ ➡️ 3 ➡️ 4 ➡️ 5", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Số nào đứng ngay trước số 3?", "dung": "Tuyệt vời! Số 2 đứng ngay trước số 3!" },
{ "moTa": "Ẩn số ở đầu dãy đếm tiến ", "chuoi": "❓ ➡️ 5 ➡️ 6 ➡️ 7", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Đếm lùi lại 1 bước từ số 5 nào!", "dung": "Đúng rồi! Số 4 đứng trước số 5!" },
{ "moTa": "Ẩn số ở đầu dãy đếm tiến", "chuoi": "❓ ➡️ 6 ➡️ 7 ➡️ 8", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Trước số 6 là số mấy vậy bé?", "dung": "Xuất sắc! Số 5 đứng trước số 6!" },
{ "moTa": "Ẩn số ở đầu dãy đếm tiến ", "chuoi": "❓ ➡️ 7 ➡️ 8 ➡️ 9", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Lùi 1 bước từ số 7 nhé!", "dung": "Quá thông minh! Số 6 đứng trước số 7!" },
{ "moTa": "Ẩn số ở đầu dãy đếm tiến", "chuoi": "❓ ➡️ 8 ➡️ 9 ➡️ 10", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Số đứng trước số 8 là gì nào?", "dung": "Chính xác tuyệt đối! Số 7 đứng trước số 8!" },
{ "moTa": "Ẩn số ở đầu dãy tròn chục", "chuoi": "❓ ➡️ 10 ➡️ 11 ➡️ 12", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Số liền trước số 10 là mấy?", "dung": "Đúng thế! Số 9 đứng ngay trước số 10!" },
{ "moTa": "Ẩn số ở đầu dãy số chẵn vừa", "chuoi": "❓ ➡️ 10 ➡️ 12 ➡️ 14", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Lùi lại 2 bước từ số 10 nhé bé!", "dung": "Quá giỏi! Số 8 là số chẵn đứng trước 10!" },
{ "moTa": "Ẩn số ở đầu dãy chẵn lớn", "chuoi": "❓ ➡️ 12 ➡️ 14 ➡️ 16", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Trừ đi 2 đơn vị từ số 12 nào!", "dung": "Tuyệt vời! Số 10 đứng trước số 12!" },
{ "moTa": "Ẩn số ở đầu dãy đếm tiến từ 16", "chuoi": "❓ ➡️ 16 ➡️ 17 ➡️ 18", "dapAn": 15, "luaChon": [14, 15, 16], "sai": "Gợi ý: Trước số 16 là số mấy nào bé?", "dung": "Xuất sắc! Số 15 đứng trước số 16!" },
{ "moTa": "Ẩn số ở đầu dãy đếm tiến từ 18", "chuoi": "❓ ➡️ 18 ➡️ 19 ➡️ 20", "dapAn": 17, "luaChon": [16, 17, 18], "sai": "Gợi ý: Số đứng trước số 18 là gì?", "dung": "Quá thông minh! Số 17 đứng trước số 18!" },
{ "moTa": "Ẩn số ở đầu dãy chẵn ", "chuoi": "❓ ➡️ 14 ➡️ 16 ➡️ 18", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Lùi lại 2 đơn vị từ số 14 nhé!", "dung": "Tuyệt đỉnh! Số 12 đứng trước số 14!" },
{ "moTa": "Ẩn số ở đầu dãy chẵn", "chuoi": "❓ ➡️ 16 ➡️ 18 ➡️ 20", "dapAn": 14, "luaChon": [13, 14, 15], "sai": "Gợi ý: Trừ 2 từ số 16 sẽ ra số đứng trước!", "dung": "Chính xác tuyệt đối! Số 14 đứng trước số 16!" },
{ "moTa": "Ẩn số ở đầu dãy đếm tiến từ 4", "chuoi": "❓ ➡️ 4 ➡️ 5 ➡️ 6", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Số đứng ngay trước số 4 là gì?", "dung": "Đúng thế! Số 3 đứng trước số 4!" },
{ "moTa": "Ẩn số ở đầu dãy đếm tiến từ 17", "chuoi": "❓ ➡️ 17 ➡️ 18 ➡️ 19", "dapAn": 16, "luaChon": [15, 16, 17], "sai": "Gợi ý: Trước số 17 là số mấy vậy bé yêu?", "dung": "Quá giỏi! Số 16 đứng trước số 17!" },
{ "moTa": "Mê cung nhân đôi nâng cao", "chuoi": "2 ➡️ 4 ➡️ 8 ➡️ ❓", "dapAn": 16, "luaChon": [12, 14, 16], "sai": "Gợi ý: Lấy 8 nhân đôi lên nhé!", "dung": "Tuyệt đỉnh! 8 gấp đôi là 16!" },
{ "moTa": "Mê cung nhân đôi số lớn", "chuoi": "4 ➡️ 8 ➡️ 16 ➡️ ❓", "dapAn": 32, "luaChon": [24, 30, 32], "sai": "Gợi ý: Gấp đôi của số 16 là bao nhiêu nào?", "dung": "Quá xuất sắc! 16 nhân đôi bằng 32!" },
{ "moTa": "Mê cung nhân đôi", "chuoi": "1 ➡️ 2 ➡️ 4 ➡️ ❓", "dapAn": 8, "luaChon": [6, 7, 8], "sai": "Số sau gấp đôi số trước đấy bé ạ!", "dung": "Quá siêu phàm! 4 gấp đôi là 8!" },
{ "moTa": "Zích Zắc (+1 rồi -1) nâng cao", "chuoi": "4 ➡️ 5 ➡️ 4 ➡️ 5 ➡️ ❓", "dapAn": 4, "luaChon": [3, 4, 6], "sai": "Gợi ý: Sau khi cộng 1 thì bước tiếp theo phải trừ 1!", "dung": "Quá thông minh! 5 trừ 1 bằng 4!" },
{ "moTa": "Zích Zắc đổi chiều (-1 rồi +1)", "chuoi": "5 ➡️ 4 ➡️ 5 ➡️ 4 ➡️ ❓", "dapAn": 5, "luaChon": [3, 5, 6], "sai": "Quy luật: Trừ 1 rồi lại cộng 1 luân phiên nhé!", "dung": "Tuyệt đỉnh! 4 cộng 1 bằng 5!" },
{ "moTa": "Zích Zắc bắt đầu từ số lớn", "chuoi": "8 ➡️ 9 ➡️ 8 ➡️ 9 ➡️ ❓", "dapAn": 8, "luaChon": [7, 8, 10], "sai": "Gợi ý: Cứ cộng 1 rồi trừ 1 xen kẽ nhau!", "dung": "Quá xuất sắc! Số tiếp theo là 8!" },
{ "moTa": "Zích Zắc (+1 rồi -1)", "chuoi": "2 ➡️ 3 ➡️ 2 ➡️ 3 ➡️ ❓", "dapAn": 2, "luaChon": [1, 2, 4], "sai": "Quy luật zích zắc: Cứ cộng 1 rồi lại trừ 1!", "dung": "Xuất sắc! Quay về số 2 chính xác!" },
{ "moTa": "Zích Zắc (+1 rồi -1)", "chuoi": "3 ➡️ 4 ➡️ 3 ➡️ 4 ➡️ ❓", "dapAn": 3, "luaChon": [2, 3, 5], "sai": "Gợi ý: Quy luật là cộng 1 rồi trừ 1 xen kẽ!", "dung": "Chính xác tuyệt vời! 4 trừ 1 bằng 3!" },
{ "moTa": "Zích Zắc (+1 rồi -1)", "chuoi": "6 ➡️ 7 ➡️ 6 ➡️ 7 ➡️ ❓", "dapAn": 6, "luaChon": [5, 6, 8], "sai": "Gợi ý: Sau khi cộng 1 thì bước tiếp theo phải trừ 1!", "dung": "Tuyệt vời! 7 trừ 1 bằng 6 chuẩn xác!" },
{ "moTa": "Zích Zắc (+1 rồi -1)", "chuoi": "7 ➡️ 8 ➡️ 7 ➡️ 8 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 9], "sai": "Gợi ý: Cứ cộng 1 rồi lại trừ 1 luân phiên nhé bé!", "dung": "Đúng rồi! Số tiếp theo là 7!" },
{ "moTa": "Zích Zắc (+1 rồi -1)", "chuoi": "9 ➡️ 10 ➡️ 9 ➡️ 10 ➡️ ❓", "dapAn": 9, "luaChon": [8, 9, 11], "sai": "Gợi ý: Sau số 10 trong nhịp zích zắc là trừ 1!", "dung": "Quá thông minh! 10 trừ 1 bằng 9!" },
{ "moTa": "Zích Zắc (+1 rồi -1)", "chuoi": "10 ➡️ 11 ➡️ 10 ➡️ 11 ➡️ ❓", "dapAn": 10, "luaChon": [9, 10, 12], "sai": "Gợi ý: Quy luật zích zắc cộng 1 rồi trừ 1!", "dung": "Xuất sắc! Quay về số 10 chính xác!" },
{ "moTa": "Zích Zắc (-1 rồi +1)", "chuoi": "4 ➡️ 3 ➡️ 4 ➡️ 3 ➡️ ❓", "dapAn": 4, "luaChon": [2, 4, 5], "sai": "Gợi ý: Đang trừ 1 thì đổi sang cộng 1 nhé bé!", "dung": "Tuyệt đỉnh! 3 cộng 1 bằng 4!" },
{ "moTa": "Zích Zắc (-1 rồi +1)", "chuoi": "6 ➡️ 5 ➡️ 6 ➡️ 5 ➡️ ❓", "dapAn": 6, "luaChon": [4, 6, 7], "sai": "Gợi ý: Quy luật là trừ 1 rồi lại cộng 1!", "dung": "Chính xác! 5 cộng 1 bằng 6!" },
{ "moTa": "Zích Zắc (-1 rồi +1)", "chuoi": "7 ➡️ 6 ➡️ 7 ➡️ 6 ➡️ ❓", "dapAn": 7, "luaChon": [5, 7, 8], "sai": "Gợi ý: Sau khi trừ 1 thì phải cộng thêm 1 nào!", "dung": "Quá giỏi! 6 cộng 1 bằng 7 hoàn hảo!" },
{ "moTa": "Zích Zắc (-1 rồi +1)", "chuoi": "8 ➡️ 7 ➡️ 8 ➡️ 7 ➡️ ❓", "dapAn": 8, "luaChon": [6, 8, 9], "sai": "Gợi ý: Cứ trừ 1 rồi lại cộng 1 xen kẽ nhau!", "dung": "Đúng thế! Số tiếp theo là 8!" },
{ "moTa": "Zích Zắc (-1 rồi +1)", "chuoi": "9 ➡️ 8 ➡️ 9 ➡️ 8 ➡️ ❓", "dapAn": 9, "luaChon": [7, 9, 10], "sai": "Gợi ý: Đang trừ 1 thì nhịp kế tiếp là cộng 1!", "dung": "Xuất sắc! 8 cộng 1 bằng 9!" },
{ "moTa": "Zích Zắc (+1 rồi -1)", "chuoi": "11 ➡️ 12 ➡️ 11 ➡️ 12 ➡️ ❓", "dapAn": 11, "luaChon": [10, 11, 13], "sai": "Gợi ý: Quy luật zích zắc cộng 1 rồi trừ 1 nhé!", "dung": "Quá thông minh! 12 trừ 1 bằng 11!" },
{ "moTa": "Zích Zắc (+1 rồi -1)", "chuoi": "12 ➡️ 13 ➡️ 12 ➡️ 13 ➡️ ❓", "dapAn": 12, "luaChon": [11, 12, 14], "sai": "Gợi ý: Sau khi cộng 1 thì phải trừ đi 1!", "dung": "Chính xác tuyệt đối! 13 trừ 1 bằng 12!" },
{ "moTa": "Zích Zắc (-1 rồi +1)", "chuoi": "13 ➡️ 12 ➡️ 13 ➡️ 12 ➡️ ❓", "dapAn": 13, "luaChon": [11, 13, 14], "sai": "Gợi ý: Đang trừ 1 thì đổi sang cộng 1 nào bé!", "dung": "Tuyệt vời! 12 cộng 1 bằng 13!" },
{ "moTa": "Zích Zắc (+1 rồi -1)", "chuoi": "14 ➡️ 15 ➡️ 14 ➡️ 15 ➡️ ❓", "dapAn": 14, "luaChon": [13, 14, 16], "sai": "Gợi ý: Cứ cộng 1 rồi trừ 1 nhịp nhàng!", "dung": "Đúng rồi! 15 trừ 1 bằng 14!" },
{ "moTa": "Zích Zắc (-1 rồi +1)", "chuoi": "15 ➡️ 14 ➡️ 15 ➡️ 14 ➡️ ❓", "dapAn": 15,"luaChon": [13, 15, 16], "sai": "Gợi ý: Quy luật trừ 1 rồi cộng 1 xen kẽ nhé!", "dung": "Xuất sắc! 14 cộng 1 bằng 15 hoàn hảo!" },
{ "moTa": "Zích Zắc (+2 rồi -1) cơ bản", "chuoi": "1 ➡️ 3 ➡️ 2 ➡️ 4 ➡️ ❓", "dapAn": 3, "luaChon": [3, 5, 6], "sai": "Quy luật: Cộng 2 rồi trừ 1 lặp lại nhé bé!", "dung": "Quá siêu! 4 trừ 1 bằng 3!" },
{ "moTa": "Zích Zắc (+2 rồi -1) nâng cao", "chuoi": "3 ➡️ 5 ➡️ 4 ➡️ 6 ➡️ ❓", "dapAn": 5, "luaChon": [4, 5, 7], "sai": "Gợi ý: Sau khi cộng 2 thì bước tiếp theo trừ 1!", "dung": "Xuất sắc! 6 trừ 1 bằng 5!" },
{ "moTa": "Zích Zắc (-2 rồi +1)", "chuoi": "5 ➡️ 3 ➡️ 4 ➡️ 2 ➡️ ❓", "dapAn": 3, "luaChon": [1, 3, 4], "sai": "Quy luật: Trừ 2 rồi lại cộng 1 luân phiên!", "dung": "Tuyệt đỉnh! 2 cộng 1 bằng 3!" },
{ "moTa": "Zích Zắc (+2 rồi -1) số lớn", "chuoi": "6 ➡️ 8 ➡️ 7 ➡️ 9 ➡️ ❓", "dapAn": 8, "luaChon": [7, 8, 10], "sai": "Gợi ý: Lấy số trước cộng 2, rồi trừ 1!", "dung": "Quá đỉnh! 9 trừ 1 bằng 8!" },
  { "moTa": "Zích Zắc (+2 rồi -1) nâng cao", "chuoi": "1 ➡️ 3 ➡️ 2 ➡️ 4 ➡️ ❓", "dapAn": 3, "luaChon": [3, 5, 6], "sai": "Gợi ý: Nhìn kỹ quy luật cộng 2 rồi trừ 1 nhé!", "dung": "Tuyệt vời! 4 trừ 1 bằng 3!" },
  { "moTa": "Zích Zắc (+2 rồi -1) nâng cao", "chuoi": "2 ➡️ 4 ➡️ 3 ➡️ 5 ➡️ ❓", "dapAn": 4, "luaChon": [4, 6, 7], "sai": "Gợi ý: Sau số 5 sẽ là trừ đi 1 đơn vị bé nhé!", "dung": "Chính xác! 5 trừ 1 bằng 4!" },
  { "moTa": "Zích Zắc (+2 rồi -1) nâng cao", "chuoi": "4 ➡️ 6 ➡️ 5 ➡️ 7 ➡️ ❓", "dapAn": 6, "luaChon": [6, 8, 9], "sai": "Gợi ý: Lấy 7 bớt đi 1 nào bé ơi!", "dung": "Xuất sắc! 7 trừ 1 bằng 6!" },
  { "moTa": "Zích Zắc (+2 rồi -1) nâng cao", "chuoi": "5 ➡️ 7 ➡️ 6 ➡️ 8 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 9], "sai": "Gợi ý: Sau khi cộng 2 thì bước tiếp theo trừ 1!", "dung": "Đúng rồi! 8 trừ 1 bằng 7!" },
  { "moTa": "Zích Zắc (+2 rồi -1) nâng cao", "chuoi": "6 ➡️ 8 ➡️ 7 ➡️ 9 ➡️ ❓", "dapAn": 8, "luaChon": [7, 8, 10], "sai": "Gợi ý: Giảm 1 đơn vị từ số 9 nào bé!", "dung": "Quá giỏi! 9 trừ 1 bằng 8!" },
  { "moTa": "Zích Zắc (+2 rồi -1) nâng cao", "chuoi": "7 ➡️ 9 ➡️ 8 ➡️ 10 ➡️ ❓", "dapAn": 9, "luaChon": [8, 9, 11], "sai": "Gợi ý: Quy luật là cộng 2 rồi lại trừ 1 nha!", "dung": "Tuyệt đỉnh! 10 trừ 1 bằng 9!" },
  { "moTa": "Zích Zắc (+2 rồi -1) nâng cao", "chuoi": "8 ➡️ 10 ➡️ 9 ➡️ 11 ➡️ ❓", "dapAn": 10, "luaChon": [9, 10, 12], "sai": "Gợi ý: Lấy 11 trừ đi 1 đơn vị nào bé ơi!", "dung": "Chính xác! 11 trừ 1 bằng 10!" },
  { "moTa": "Zích Zắc (-2 rồi +1)", "chuoi": "6 ➡️ 4 ➡️ 5 ➡️ 3 ➡️ ❓", "dapAn": 4, "luaChon": [2, 4, 5], "sai": "Gợi ý: Sau khi trừ 2 thì bước này cộng thêm 1!", "dung": "Rất giỏi! 3 cộng 1 bằng 4!" },
  { "moTa": "Zích Zắc (-2 rồi +1)", "chuoi": "7 ➡️ 5 ➡️ 6 ➡️ 4 ➡️ ❓", "dapAn": 5, "luaChon": [3, 5, 6], "sai": "Gợi ý: Thêm 1 đơn vị vào số 4 nhé bé!", "dung": "Tuyệt vời! 4 cộng 1 bằng 5!" },
  { "moTa": "Zích Zắc (-2 rồi +1)", "chuoi": "8 ➡️ 6 ➡️ 7 ➡️ 5 ➡️ ❓", "dapAn": 6, "luaChon": [4, 6, 7], "sai": "Gợi ý: Quy luật là trừ 2 rồi lại cộng 1!", "dung": "Chính xác! 5 cộng 1 bằng 6!" },
  { "moTa": "Zích Zắc (-2 rồi +1)", "chuoi": "9 ➡️ 7 ➡️ 8 ➡️ 6 ➡️ ❓", "dapAn": 7, "luaChon": [5, 7, 8], "sai": "Gợi ý: Lấy số 6 cộng thêm 1 nào bé!", "dung": "Xuất sắc! 6 cộng 1 bằng 7!" },
  { "moTa": "Zích Zắc (-2 rồi +1)", "chuoi": "10 ➡️ 8 ➡️ 9 ➡️ 7 ➡️ ❓", "dapAn": 8, "luaChon": [6, 8, 9], "sai": "Gợi ý: Sau số 7 sẽ là thêm 1 đơn vị nha!", "dung": "Đúng rồi! 7 cộng 1 bằng 8!" },
  { "moTa": "Zích Zắc (-2 rồi +1)", "chuoi": "11 ➡️ 9 ➡️ 10 ➡️ 8 ➡️ ❓", "dapAn": 9, "luaChon": [7, 9, 10], "sai": "Gợi ý: Đếm thêm 1 bước từ số 8 nào bé!", "dung": "Tuyệt đỉnh! 8 cộng 1 bằng 9!" },
  { "moTa": "Zích Zắc (-2 rồi +1)", "chuoi": "12 ➡️ 10 ➡️ 11 ➡️ 9 ➡️ ❓", "dapAn": 10, "luaChon": [8, 10, 11], "sai": "Gợi ý: Lấy số 9 cộng thêm 1 đơn vị nhé!", "dung": "Quá xuất sắc! 9 cộng 1 bằng 10!" },
{ "moTa": "Tăng tốc nhân đôi zích zắc", "chuoi": "1 ➡️ 2 ➡️ 4 ➡️ 8 ➡️ ❓", "dapAn": 16, "luaChon": [10, 12, 16], "sai": "Mỗi bước đi số ô nhân đôi lên nhé!", "dung": "Đỉnh cao! Gấp đôi của 8 là 16!" },
{ "moTa": "Nhân đôi bắt đầu từ 2", "chuoi": "2 ➡️ 4 ➡️ 8 ➡️ 16 ➡️ ❓", "dapAn": 32, "luaChon": [24, 30, 32], "sai": "Gợi ý: Mỗi bước số nhân lên gấp đôi nhé bé!", "dung": "Tuyệt vời! Gấp đôi của 16 là 32!" },
{ "moTa": "Nhân đôi dãy số nhỏ ", "chuoi": "1 ➡️ 2 ➡️ 4 ➡️ ❓", "dapAn": 8, "luaChon": [6, 7, 8], "sai": "Gợi ý: Số phía sau gấp đôi số liền trước!", "dung": "Chính xác! Gấp đôi của 4 là 8!" },
{ "moTa": "Nhân đôi dãy số vừa", "chuoi": "2 ➡️ 4 ➡️ 8 ➡️ ❓", "dapAn": 16, "luaChon": [12, 14, 16], "sai": "Gợi ý: Lấy 8 cộng thêm chính nó nào!", "dung": "Quá thông minh! Gấp đôi của 8 là 16!" },
{ "moTa": "Nhân đôi dãy số ", "chuoi": "3 ➡️ 6 ➡️ 12 ➡️ ❓", "dapAn": 24, "luaChon": [18, 20, 24], "sai": "Gợi ý: Mỗi lần tăng lên gấp đôi giá trị!", "dung": "Xuất sắc! Gấp đôi của 12 là 24!" },
{ "moTa": "Nhân đôi dãy số bắt đầu từ 4", "chuoi": "4 ➡️ 8 ➡️ 16 ➡️ ❓", "dapAn": 32, "luaChon": [24, 28, 32], "sai": "Gợi ý: Số tiếp theo bằng 16 nhân đôi lên!", "dung": "Tuyệt đỉnh! Gấp đôi của 16 là 32!" },
{ "moTa": "Nhân đôi tìm ẩn số ở giữa", "chuoi": "2 ➡️ ❓ ➡️ 8 ➡️ 16", "dapAn": 4, "luaChon": [3, 4, 6], "sai": "Gợi ý: Số nào gấp đôi 2 và bằng một nửa của 8?", "dung": "Đúng rồi! Số 4 đứng ở giữa rất chính xác!" },
{ "moTa": "Nhân đôi tìm ẩn số ở giữa lớn hơn", "chuoi": "4 ➡️ ❓ ➡️ 16 ➡️ 32", "dapAn": 8, "luaChon": [6, 8, 10], "sai": "Gợi ý: Gấp đôi của 4 là mấy nào bé?", "dung": "Quá giỏi! Số 8 nằm ở giữa hoàn hảo!" },
{ "moTa": "Nhân đôi với số khởi đầu là 5", "chuoi": "5 ➡️ 10 ➡️ 20 ➡️ ❓", "dapAn": 40, "luaChon": [30, 35, 40], "sai": "Gợi ý: Mỗi bước nhân 2 lần số trước đó!", "dung": "Chính xác tuyệt đối! Gấp đôi của 20 là 40!" },
{ "moTa": "Nhân đôi ẩn số ở gần đầu", "chuoi": "❓ ➡️ 3 ➡️ 6 ➡️ 12", "dapAn": 1, "luaChon": [1, 2, 4], "sai": "Gợi ý: Số nào nhân đôi lên thì bằng 3? À nhầm, số nào nhân đôi lên thành 3... suy luận lùi lại một nửa nhé!", "dung": "Tuyệt vời! Số 1.5 hoặc nửa của 2... (chọn 1 hoặc quy luật chia đôi lùi về). Chính xác là 1.5 hoặc theo dãy cơ bản số 1!" },
{ "moTa": "Nhân đôi mở rộng tầm cao", "chuoi": "6 ➡️ 12 ➡️ 24 ➡️ ❓", "dapAn": 48, "luaChon": [36, 42, 48], "sai": "Gợi ý: Lấy 24 cộng thêm 24 nữa nhé bé!", "dung": "Xuất sắc! Gấp đôi của 24 chính là 48!" },
{ "moTa": "Zích zắc đối xứng gương", "chuoi": "1 ➡️ 3 ➡️ 5 ➡️ 3 ➡️ ❓", "dapAn": 1, "luaChon": [1, 2, 4], "sai": "Gợi ý: Dãy số tăng dần rồi đối xứng giảm dần qua trục giữa!", "dung": "Xuất sắc! Gương đối xứng phản chiếu về số 1!" },
{ "moTa": "Zích zắc đối xứng gương", "chuoi": "2 ➡️ 4 ➡️ 6 ➡️ 4 ➡️ ❓", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Lật ngược lại quy trình tăng dần trước đó nhé!", "dung": "Quá thông minh! Quay về số 2 chính xác!" },
{ "moTa": "Zích zắc đối xứng gương", "chuoi": "3 ➡️ 6 ➡️ 9 ➡️ 6 ➡️ ❓", "dapAn": 3, "luaChon": [3, 4, 5], "sai": "Gợi ý: Đỉnh gương là số 9, lùi đối xứng lại nào!", "dung": "Tuyệt đỉnh! Đối xứng qua số 9 là số 3!" },
{ "moTa": "Vòng lặp 3 số cơ bản", "chuoi": "1 ➡️ 2 ➡️ 3 ➡️ 1 ➡️ 2 ➡️ ❓", "dapAn": 3, "luaChon": [1, 2, 3], "sai": "Quy luật: Lặp lại chuỗi 3 số 1, 2, 3 liên tục!", "dung": "Tuyệt đỉnh! Quay lại số 3 trong chuỗi vòng lặp!" },
{ "moTa": "Vòng lặp 3 số nâng cao", "chuoi": "5 ➡️ 7 ➡️ 9 ➡️ 5 ➡️ 7 ➡️ ❓", "dapAn": 9, "luaChon": [5, 7, 9], "sai": "Gợi ý: Chuỗi lặp gồm 3 số 5, 7, 9 nhé bé!", "dung": "Quá thông minh! Tiếp theo là số 9!" },
{ "moTa": "Vòng lặp 3 số giảm dần", "chuoi": "9 ➡️ 6 ➡️ 3 ➡️ 9 ➡️ 6 ➡️ ❓", "dapAn": 3, "luaChon": [3, 6, 9], "sai": "Quy luật: Vòng lặp giảm dần qua 3 số 9, 6, 3!", "dung": "Xuất sắc! Lại là số 3 hoàn hảo!" },
{ "moTa": "Vòng lặp 3 số", "chuoi": "1 ➡️ 2 ➡️ 5 ➡️ 1 ➡️ 2 ➡️ ❓", "dapAn": 5, "luaChon": [2, 5, 8], "sai": "Chuỗi 3 số (1, 2, 5) đang lặp lại!", "dung": "Hoan hô! Vòng lặp tiếp diễn hoàn hảo!" },
{ "moTa": "Vòng lặp 3 ", "chuoi": "2 ➡️ 3 ➡️ 4 ➡️ 2 ➡️ 3 ➡️ ❓", "dapAn": 4, "luaChon": [2, 3, 4], "sai": "Gợi ý: Chuỗi lặp gồm 3 số 2, 3, 4 liên tục nhé!", "dung": "Chính xác tuyệt vời! Lặp lại số 4!" },
{ "moTa": "Vòng lặp 3 ", "chuoi": "3 ➡️ 4 ➡️ 5 ➡️ 3 ➡️ 4 ➡️ ❓", "dapAn": 5, "luaChon": [3, 4, 5], "sai": "Gợi ý: Quy luật lặp lại ba số 3, 4, 5 luân phiên!", "dung": "Tuyệt vời! Sau số 4 là số 5!" },
{ "moTa": "Vòng lặp 3 ", "chuoi": "4 ➡️ 5 ➡️ 6 ➡️ 4 ➡️ 5 ➡️ ❓", "dapAn": 6, "luaChon": [4, 5, 6], "sai": "Gợi ý: Cụm 3 số đang lặp lại là 4, 5, 6!", "dung": "Đúng rồi! Số tiếp theo chính là 6!" },
{ "moTa": "Vòng lặp 3 ", "chuoi": "6 ➡️ 7 ➡️ 8 ➡️ 6 ➡️ 7 ➡️ ❓", "dapAn": 8, "luaChon": [6, 7, 8], "sai": "Gợi ý: Vòng lặp gồm bộ ba số 6, 7, 8 nhé bé!", "dung": "Xuất sắc! Lặp lại số 8 rất chuẩn!" },
{ "moTa": "Vòng lặp 3 ", "chuoi": "7 ➡️ 8 ➡️ 9 ➡️ 7 ➡️ 8 ➡️ ❓", "dapAn": 9, "luaChon": [7, 8, 9], "sai": "Gợi ý: Chuỗi tuần hoàn 7, 8, 9 đang quay vòng!", "dung": "Quá thông minh! Tiếp theo là số 9!" },
{ "moTa": "Vòng lặp 3 số chẵn ", "chuoi": "2 ➡️ 4 ➡️ 6 ➡️ 2 ➡️ 4 ➡️ ❓", "dapAn": 6, "luaChon": [2, 4, 6], "sai": "Gợi ý: Bộ ba số chẵn 2, 4, 6 lặp lại liên tục!", "dung": "Tuyệt đỉnh! Quay lại số 6 trong vòng lặp!" },
{ "moTa": "Vòng lặp 3 số chẵn ", "chuoi": "4 ➡️ 6 ➡️ 8 ➡️ 4 ➡️ 6 ➡️ ❓", "dapAn": 8, "luaChon": [4, 6, 8], "sai": "Gợi ý: Quy luật lặp lại cụm ba số 4, 6, 8!", "dung": "Đúng thế! Sau số 6 là số 8!" },
{ "moTa": "Vòng lặp 3 số chẵn", "chuoi": "6 ➡️ 8 ➡️ 10 ➡️ 6 ➡️ 8 ➡️ ❓", "dapAn": 10, "luaChon": [6, 8, 10], "sai": "Gợi ý: Chuỗi 3 số chẵn 6, 8, 10 đang lặp lại!", "dung": "Chính xác! Số 10 hoàn thành vòng lặp!" },
{ "moTa": "Vòng lặp 3 số chẵn", "chuoi": "8 ➡️ 10 ➡️ 12 ➡️ 8 ➡️ 10 ➡️ ❓", "dapAn": 12, "luaChon": [8, 10, 12], "sai": "Gợi ý: Vòng tuần hoàn gồm ba số 8, 10, 12 nhé!", "dung": "Quá giỏi! Tiếp theo là số 12!" },
{ "moTa": "Vòng lặp 3 số chẵn", "chuoi": "10 ➡️ 12 ➡️ 14 ➡️ 10 ➡️ 12 ➡️ ❓", "dapAn": 14, "luaChon": [10, 12, 14], "sai": "Gợi ý: Bộ số 10, 12, 14 đang lặp lại nhịp nhàng!", "dung": "Xuất sắc! Số 14 là đáp án chính xác!" },
{ "moTa": "Vòng lặp 3 số", "chuoi": "1 ➡️ ❓ ➡️ 3 ➡️ 1 ➡️ 2 ➡️ 3", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Số đứng giữa trong cụm 1, 2, 3 là mấy?", "dung": "Tuyệt vời! Số 2 nằm ở vị trí thứ hai!" },
{ "moTa": "Vòng lặp 3 số ", "chuoi": "❓ ➡️ 7 ➡️ 9 ➡️ 5 ➡️ 7 ➡️ 9", "dapAn": 5, "luaChon": [5, 7, 9], "sai": "Gợi ý: Bộ ba số 5, 7, 9 bắt đầu bằng số mấy?", "dung": "Đúng rồi! Mở đầu chuỗi là số 5!" },
{ "moTa": "Vòng lặp 3 số giảm dần", "chuoi": "8 ➡️ 6 ➡️ 4 ➡️ 8 ➡️ 6 ➡️ ❓", "dapAn": 4, "luaChon": [4, 6, 8], "sai": "Gợi ý: Vòng lặp giảm dần qua 3 số 8, 6, 4!", "dung": "Chính xác tuyệt đối! Lại là số 4!" },
{ "moTa": "Vòng lặp 3 số giảm dần", "chuoi": "7 ➡️ 5 ➡️ 3 ➡️ 7 ➡️ 5 ➡️ ❓", "dapAn": 3, "luaChon": [3, 5, 7], "sai": "Gợi ý: Chuỗi tuần hoàn giảm dần 7, 5, 3 nhé bé!", "dung": "Tuyệt đỉnh! Kết thúc cụm bằng số 3!" },
{ "moTa": "Vòng lặp 3 số lẻ ", "chuoi": "1 ➡️ 3 ➡️ 5 ➡️ 1 ➡️ 3 ➡️ ❓", "dapAn": 5, "luaChon": [1, 3, 5], "sai": "Gợi ý: Bộ ba số lẻ 1, 3, 5 đang lặp lại vòng tròn!", "dung": "Quá thông minh! Tiếp theo là số 5!" },
{ "moTa": "Vòng lặp 3 số lẻ ", "chuoi": "3 ➡️ 5 ➡️ 7 ➡️ 3 ➡️ 5 ➡️ ❓", "dapAn": 7, "luaChon": [3, 5, 7], "sai": "Gợi ý: Chuỗi lặp gồm các số lẻ 3, 5, 7 liên tục!", "dung": "Xuất sắc! Lặp lại số 7 chuẩn xác!" },
{ "moTa": "Vòng lặp 3 số lẻ ", "chuoi": "5 ➡️ 7 ➡️ 9 ➡️ 5 ➡️ 7 ➡️ ❓", "dapAn": 9, "luaChon": [5, 7, 9], "sai": "Gợi ý: Vòng lặp ba số lẻ 5, 7, 9 đang tiếp diễn!", "dung": "Đúng thế! Số 9 hoàn thành chuỗi!" },
{ "moTa": "Vòng lặp 3 số hỗn", "chuoi": "2 ➡️ 5 ➡️ 8 ➡️ 2 ➡️ 5 ➡️ ❓", "dapAn": 8, "luaChon": [2, 5, 8], "sai": "Gợi ý: Bộ ba số cách đều 2, 5, 8 đang lặp lại!", "dung": "Quá giỏi! Tiếp theo là số 8!" },
{ "moTa": "Vòng lặp 3 số hỗn hợp", "chuoi": "3 ➡️ 6 ➡️ 9 ➡️ 3 ➡️ 6 ➡️ ❓", "dapAn": 9, "luaChon": [3, 6, 9], "sai": "Gợi ý: Chuỗi lặp gồm các số 3, 6, 9 cách đều 3 đơn vị!", "dung": "Tuyệt vời! Lặp lại số 9 hoàn hảo!" },
{ "moTa": "Vòng lặp 3 số ", "chuoi": "4 ➡️ 7 ➡️ 10 ➡️ 4 ➡️ 7 ➡️ ❓", "dapAn": 10, "luaChon": [4, 7, 10], "sai": "Gợi ý: Vòng tuần hoàn gồm bộ ba 4, 7, 10 nhé bé!", "dung": "Chính xác tuyệt đối! Số 10 kết thúc chuỗi!" },
{ "moTa": "Cộng dồn tịnh tiến (+1, +2, +3 , +4)", "chuoi": "1 ➡️ 2 ➡️ 4 ➡️ 7 ➡️ ❓", "dapAn": 11, "luaChon": [9, 10, 11], "sai": "Khoảng cách tăng dần (+1, +2, +3, tiếp +4)", "dung": "Quá thông minh! 7 cộng 4 là 11!" },
  { "moTa": "Cộng dồn tịnh tiến (+1, +2, +3, +4)", "chuoi": "2 ➡️ 3 ➡️ 5 ➡️ 8 ➡️ ❓", "dapAn": 12, "luaChon": [10, 11, 12], "sai": "Gợi ý: Khoảng cách tăng dần từ +1, +2, +3 rồi tiếp theo là +4 nhé!", "dung": "Quá thông minh! 8 cộng 4 bằng 12!" },
  { "moTa": "Cộng dồn tịnh tiến (+1, +2, +3, +4)", "chuoi": "3 ➡️ 4 ➡️ 6 ➡️ 9 ➡️ ❓", "dapAn": 13, "luaChon": [11, 12, 13], "sai": "Gợi ý: Đã cộng 1, cộng 2, cộng 3, giờ bé cộng thêm 4 vào số 9 nào!", "dung": "Xuất sắc! 9 cộng 4 là 13!" },
  { "moTa": "Cộng dồn tịnh tiến (+1, +2, +3, +4)", "chuoi": "4 ➡️ 5 ➡️ 7 ➡️ 10 ➡️ ❓", "dapAn": 14, "luaChon": [12, 13, 14], "sai": "Gợi ý: Quy luật là tăng dần bước nhảy (+1, +2, +3, +4) bé ơi!", "dung": "Tuyệt đỉnh! 10 cộng 4 bằng 14!" },
  { "moTa": "Cộng dồn tịnh tiến (+1, +2, +3, +4)", "chuoi": "5 ➡️ 6 ➡️ 8 ➡️ 11 ➡️ ❓", "dapAn": 15, "luaChon": [13, 14, 15], "sai": "Gợi ý: Bước nhảy tiếp theo là 4 đơn vị, lấy 11 cộng 4 nhé!", "dung": "Chính xác! 11 cộng 4 chuẩn là 15!" },
{ "moTa": "Cộng dồn tịnh tiến (+2, +3, +4, +5)", "chuoi": "1 ➡️ 3 ➡️ 6 ➡️ 10 ➡️ ❓", "dapAn": 15, "luaChon": [14, 15, 16], "sai": "Gợi ý: Khoảng cách tăng dần mỗi bước là +2, +3, +4, tiếp theo là +5!", "dung": "Quá thông minh! 10 cộng 5 bằng 15!" },
{ "moTa": "Cộng dồn tịnh tiến (+2, +3, +4, +5)", "chuoi": "2 ➡️ 4 ➡️ 7 ➡️ 11 ➡️ ❓", "dapAn": 16, "luaChon": [15, 16, 17], "sai": "Gợi ý: Khoảng cách cộng các bước là +2, +3, +4, tiếp tục là +5!", "dung": "Xuất sắc! 11 cộng 5 bằng 16 hoàn hảo!" },
{ "moTa": "Cộng dồn tịnh tiến (+1, +2, +3, +4)", "chuoi": "6 ➡️ 7 ➡️ 9 ➡️ 12 ➡️ ❓", "dapAn": 16, "luaChon": [15, 16, 17], "sai": "Gợi ý: Quy luật khoảng cách tăng đều +1, +2, +3, rồi cộng thêm 4!", "dung": "Đúng rồi! 12 cộng 4 là 16 chuẩn xác!" },
{ "moTa": "Zích zắc âm dương (+3 rồi -2)", "chuoi": "3 ➡️ 6 ➡️ 4 ➡️ 7 ➡️ ❓", "dapAn": 5, "luaChon": [5, 8, 9], "sai": "Quy luật: Cộng 3 rồi trừ 2 luân phiên!", "dung": "Quá đỉnh! 7 trừ 2 bằng 5!" },
  { "moTa": "Zích zắc âm dương (+3 rồi -2)", "chuoi": "1 ➡️ 4 ➡️ 2 ➡️ 5 ➡️ ❓", "dapAn": 3, "luaChon": [3, 6, 8], "sai": "Gợi ý: Quy luật là cộng 3 rồi trừ 2 luân phiên!", "dung": "Chính xác! 5 trừ 2 bằng 3!" },
  { "moTa": "Zích zắc âm dương (+3 rồi -2)", "chuoi": "2 ➡️ 5 ➡️ 3 ➡️ 6 ➡️ ❓", "dapAn": 4, "luaChon": [4, 7, 9], "sai": "Gợi ý: Lấy 6 bớt đi 2 đơn vị nào bé!", "dung": "Tuyệt vời! 6 trừ 2 bằng 4!" },
  { "moTa": "Zích zắc âm dương (+3 rồi -2)", "chuoi": "4 ➡️ 7 ➡️ 5 ➡️ 8 ➡️ ❓", "dapAn": 6, "luaChon": [5, 6, 11], "sai": "Gợi ý: Sau khi cộng 3 thì bước tiếp theo trừ đi 2 nhé!", "dung": "Xuất sắc! 8 trừ 2 bằng 6!" },
  { "moTa": "Zích zắc âm dương (+3 rồi -2)", "chuoi": "5 ➡️ 8 ➡️ 6 ➡️ 9 ➡️ ❓", "dapAn": 7, "luaChon": [7, 10, 12], "sai": "Gợi ý: Trừ 2 đơn vị từ số 9 nào bé ơi!", "dung": "Quá thông minh! 9 trừ 2 bằng 7!" },
  { "moTa": "Zích zắc âm dương (+3 rồi -2)", "chuoi": "6 ➡️ 9 ➡️ 7 ➡️ 10 ➡️ ❓", "dapAn": 8, "luaChon": [8, 11, 13], "sai": "Gợi ý: Nhìn kỹ quy luật cộng 3 rồi trừ 2 nhé!", "dung": "Đúng rồi! 10 trừ 2 bằng 8!" },
  { "moTa": "Zích zắc âm dương (+3 rồi -2)", "chuoi": "7 ➡️ 10 ➡️ 8 ➡️ 11 ➡️ ❓", "dapAn": 9, "luaChon": [9, 12, 14], "sai": "Gợi ý: Lấy 11 trừ 2 đơn vị xem bằng bao nhiêu!", "dung": "Tuyệt đỉnh! 11 trừ 2 chuẩn là 9!" },
  { "moTa": "Zích zắc âm dương (-3 rồi +2)", "chuoi": "6 ➡️ 3 ➡️ 5 ➡️ 2 ➡️ ❓", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Quy luật là trừ 3 rồi lại cộng 2 luân phiên!", "dung": "Tuyệt vời! 2 cộng 2 bằng 4!" },
  { "moTa": "Zích zắc âm dương (-3 rồi +2)", "chuoi": "7 ➡️ 4 ➡️ 6 ➡️ 3 ➡️ ❓", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Sau khi trừ 3 thì bước này cộng thêm 2 nhé!", "dung": "Chính xác! 3 cộng 2 bằng 5!" },
  { "moTa": "Zích zắc âm dương (-3 rồi +2)", "chuoi": "8 ➡️ 5 ➡️ 7 ➡️ 4 ➡️ ❓", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Thêm 2 đơn vị vào số 4 nào bé!", "dung": "Xuất sắc! 4 cộng 2 bằng 6!" },
  { "moTa": "Zích zắc âm dương (-3 rồi +2)", "chuoi": "9 ➡️ 6 ➡️ 8 ➡️ 5 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Lấy số 5 cộng thêm 2 đơn vị nhé!", "dung": "Quá thông minh! 5 cộng 2 bằng 7!" },
  { "moTa": "Zích zắc âm dương (-3 rồi +2)", "chuoi": "10 ➡️ 7 ➡️ 9 ➡️ 6 ➡️ ❓", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Đếm thêm 2 bước từ số 6 nào bé!", "dung": "Đúng rồi! 6 cộng 2 chuẩn là 8!" },
{ "moTa": "Dãy cộng 3 liên tiếp", "chuoi": "3 ➡️ 6 ➡️ ❓ ➡️ 12", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Cộng thêm 3 vào số 6 sẽ ra bao nhiêu nhỉ?", "dung": "Quá đỉnh! 6 cộng 3 bằng 9!" },
{ "moTa": "Nhảy cóc (+2 đơn vị) ", "chuoi": "1 ➡️ 3 ➡️ ❓ ➡️ 7", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Mỗi bước cộng thêm 2 đơn vị vào số trước nhé!", "dung": "Quá thông minh! 1, 3, 5, 7 chính xác!" },
{ "moTa": "Nhảy cóc (+2 đơn vị)", "chuoi": "4 ➡️ 6 ➡️ ❓ ➡️ 10", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Sau số 6 đếm thêm 2 đơn vị nữa nào bé!", "dung": "Đúng rồi! 4, 6, 8, 10 rất xuất sắc!" },
{ "moTa": "Đếm ngược lùi dần ", "chuoi": "6 ➡️ 5 ➡️ ❓ ➡️ 3 ➡️ 2", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Đang đếm lùi dần, trước số 3 là số mấy?", "dung": "Tuyệt đỉnh! 6, 5, 4, 3, 2 quá giỏi!" },
{ "moTa": "Đếm ngược lùi dần ", "chuoi": "10 ➡️ 9 ➡️ 8 ➡️ ❓ ➡️ 6", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Lùi lại 1 bước từ số 8 nhé bé!", "dung": "Xuất sắc! 10, 9, 8, 7, 6 chuẩn luôn!" },
{ "moTa": "Dãy cộng 3 liên tiếp", "chuoi": "2 ➡️ 5 ➡️ ❓ ➡️ 11", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Cộng thêm 3 đơn vị vào số 5 nào!", "dung": "Quá giỏi! 2, 5, 8, 11 tuyệt vời!" },
{ "moTa": "Dãy cộng 3 liên tiếp", "chuoi": "3 ➡️ 6 ➡️ 9 ➡️ ❓ ➡️ 15", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Thêm 3 vào số 9 sẽ ra bao nhiêu nhỉ?", "dung": "Đúng thế! 3, 6, 9, 12, 15 chính xác!" },
{ "moTa": "Nhảy cóc (+2 đơn vị) ", "chuoi": "6 ➡️ 8 ➡️ 10 ➡️ ❓", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Cộng thêm 2 vào số 10 nhé bé!", "dung": "Chính xác tuyệt đối! 6, 8, 10, 12!" },
{ "moTa": "Đếm ngược lùi dần", "chuoi": "4 ➡️ 3 ➡️ ❓ ➡️ 1", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Lùi 1 bước từ số 3 xuống nào!", "dung": "Tuyệt vời! 4, 3, 2, 1 hoàn thành xuất sắc!" },
{ "moTa": "Mê cung Fibonacci cơ bản mỗi mũi tên là dấu +", "chuoi": "1 ➡️ 1 ➡️ 2 ➡️ 3 ➡️ ❓", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Lấy 2 cộng 3 xem ra mấy nào bé?", "dung": "Quá siêu đẳng! 2 cộng 3 bằng 5!" },
{ "moTa": "Mê cung Fibonacci cơ bản mỗi mũi tên là dấu +", "chuoi": "1 ➡️ 2 ➡️ 3 ➡️ 5 ➡️ ❓", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Lấy hai số đứng cạnh nhau cuối cùng cộng lại!", "dung": "Tuyệt đỉnh! 3 cộng 5 bằng 8!" },
{ "moTa": "Mê cung Fibonacci cơ bản mỗi mũi tên là dấu +", "chuoi": "2 ➡️ 3 ➡️ 5 ➡️ 8 ➡️ ❓", "dapAn": 13, "luaChon": [11, 12, 13], "sai": "Gợi ý: Cộng hai số 5 và 8 ở cuối dãy lại với nhau!", "dung": "Xuất sắc! 5 cộng 8 bằng 13!" },
{ "moTa": "Mê cung Fibonacci cơ bản mỗi mũi tên là dấu +", "chuoi": "1 ➡️ 3 ➡️ 4 ➡️ 7 ➡️ ❓", "dapAn": 11, "luaChon": [10, 11, 12], "sai": "Gợi ý: Vẫn quy luật cũ, lấy 4 cộng 7 xem ra bao nhiêu?", "dung": "Quá đỉnh chóp! 4 cộng 7 bằng 11!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "3 ➡️ 4 ➡️ 7 ➡️ 11 ➡️ ❓", "dapAn": 18, "luaChon": [16, 17, 18], "sai": "Gợi ý: Lấy hai số cuối cùng là 7 và 4 cộng lại nhé bé!", "dung": "Tuyệt vời! 7 cộng 11 bằng 18!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "1 ➡️ 4 ➡️ 5 ➡️ 9 ➡️ ❓", "dapAn": 14, "luaChon": [12, 13, 14], "sai": "Gợi ý: Lấy số 5 cộng với số 9 ở cuối chuỗi nào!", "dung": "Chính xác tuyệt đối! 5 cộng 9 bằng 14!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "1 ➡️ 1 ➡️ 2 ➡️ ❓ ➡️ 5", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Số nào cộng với 2 để bằng 5, hoặc lấy 1 cộng 2?", "dung": "Quá thông minh! 1 cộng 2 bằng 3!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "1 ➡️ 2 ➡️ ❓ ➡️ 5 ➡️ 8", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Lấy số 1 cộng với số 2 ngay đầu nhé!", "dung": "Đúng rồi! 1 cộng 2 bằng 3 chuẩn xác!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "3 ➡️ 5 ➡️ 8 ➡️ 13 ➡️ ❓", "dapAn": 21, "luaChon": [19, 20, 21], "sai": "Gợi ý: Lấy số 8 cộng với số 13 ở cuối dãy nào!", "dung": "Xuất sắc! 8 cộng 13 bằng 21!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "2 ➡️ 1 ➡️ 3 ➡️ 4 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Lấy hai số cuối là 3 và 4 cộng lại với nhau!", "dung": "Tuyệt đỉnh! 3 cộng 4 bằng 7!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "2 ➡️ 3 ➡️ 5 ➡️ 8 ➡️ ❓", "dapAn": 13, "luaChon": [11, 12, 13], "sai": "Gợi ý: Cộng hai số 5 và 8 ở cuối dãy lại nhé bé!", "dung": "Quá giỏi! 5 cộng 8 bằng 13!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "4 ➡️ 1 ➡️ 5 ➡️ 6 ➡️ ❓", "dapAn": 11, "luaChon": [10, 11, 12], "sai": "Gợi ý: Lấy số 5 cộng với số 6 ở cuối chuỗi!", "dung": "Chính xác! 5 cộng 6 bằng 11 hoàn hảo!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "2 ➡️ 2 ➡️ 4 ➡️ 6 ➡️ ❓", "dapAn": 10, "luaChon": [8, 9, 10], "sai": "Gợi ý: Lấy hai số cuối là 4 và 6 cộng lại nào!", "dung": "Đúng thế! 4 cộng 6 bằng 10!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "3 ➡️ 3 ➡️ 6 ➡️ 9 ➡️ ❓", "dapAn": 15, "luaChon": [12, 14, 15], "sai": "Gợi ý: Cộng hai số cuối cùng là 6 và 9 nhé bé!", "dung": "Tuyệt vời! 6 cộng 9 bằng 15!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "2 ➡️ 5 ➡️ 7 ➡️ 12 ➡️ ❓", "dapAn": 19, "luaChon": [17, 18, 19], "sai": "Gợi ý: Lấy số 7 cộng với số 12 ở cuối dãy nào!", "dung": "Quá thông minh! 7 cộng 12 bằng 19!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "4 ➡️ 3 ➡️ 7 ➡️ 10 ➡️ ❓", "dapAn": 17, "luaChon": [15, 16, 17], "sai": "Gợi ý: Lấy hai số liền trước là 7 và 10 cộng lại!", "dung": "Xuất sắc! 7 cộng 10 bằng 17!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "1 ➡️ 4 ➡️ 5 ➡️ 9 ➡️ ❓", "dapAn": 14, "luaChon": [13, 14, 15], "sai": "Gợi ý: Quy luật tổng hai số liền trước: 5 cộng 9!", "dung": "Chính xác tuyệt đối! 5 cộng 9 bằng 14!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "5 ➡️ 8 ➡️ 13 ➡️ 21 ➡️ ❓", "dapAn": 34, "luaChon": [30, 32, 34], "sai": "Gợi ý: Lấy số 13 cộng với số 21 ở cuối dãy nhé!", "dung": "Tuyệt đỉnh! 13 cộng 21 bằng 34!" },
{ "moTa": "Fibonacci mỗi mũi tên là dấu +", "chuoi": "1 ➡️ ❓ ➡️ 4 ➡️ 7 ➡️ 11", "dapAn": 3, "luaChon": [2, 3, 5], "sai": "Gợi ý: Số nào cộng với 1 để ra 4, và 1 cộng mấy ra số đó?", "dung": "Quá giỏi! 1 cộng 3 bằng 4, hoàn thành xuất sắc!" },
{ "moTa": "Zích zắc giảm dần(-2 rồi +1)", "chuoi": "10 ➡️ 8 ➡️ 9 ➡️ 7 ➡️ ❓", "dapAn": 8, "luaChon": [6, 8, 9], "sai": "Quy luật: Trừ 2 rồi lại cộng 1 lặp lại nhé bé!", "dung": "Quá đỉnh! 7 cộng 1 bằng 8!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "12 ➡️ 10 ➡️ 11 ➡️ 9 ➡️ ❓", "dapAn": 10, "luaChon": [8, 10, 11], "sai": "Quy luật: Lấy số trước trừ 2, rồi cộng 1!", "dung": "Tuyệt vời! 9 cộng 1 bằng 10!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "15 ➡️ 13 ➡️ 14 ➡️ 12 ➡️ ❓", "dapAn": 13, "luaChon": [11, 13, 14], "sai": "Gợi ý: Trừ 2 rồi cộng 1 xen kẽ liên tục!", "dung": "Xuất sắc! 12 cộng 1 bằng 13!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "8 ➡️ 6 ➡️ 7 ➡️ 5 ➡️ ❓", "dapAn": 6, "luaChon": [4, 5, 6], "sai": "Gợi ý: Quy luật là trừ 2 rồi cộng 1 xen kẽ nhé bé!", "dung": "Tuyệt vời! 5 cộng 1 bằng 6 chuẩn xác!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "9 ➡️ 7 ➡️ 8 ➡️ 6 ➡️ ❓", "dapAn": 7, "luaChon": [5, 6, 7], "sai": "Gợi ý: Sau khi trừ 2 thì bước tiếp theo phải cộng 1!", "dung": "Chính xác tuyệt đối! 6 cộng 1 bằng 7!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "11 ➡️ 9 ➡️ 10 ➡️ 8 ➡️ ❓", "dapAn": 9, "luaChon": [7, 8, 9], "sai": "Gợi ý: Lấy số trước trừ 2, rồi lại cộng thêm 1 nào!", "dung": "Quá thông minh! 8 cộng 1 bằng 9!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "13 ➡️ 11 ➡️ 12 ➡️ 10 ➡️ ❓", "dapAn": 11, "luaChon": [9, 10, 11], "sai": "Gợi ý: Cứ trừ 2 rồi cộng 1 luân phiên liên tục nhé!", "dung": "Đúng rồi! 10 cộng 1 bằng 11 hoàn hảo!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "14 ➡️ 12 ➡️ 13 ➡️ 11 ➡️ ❓", "dapAn": 12, "luaChon": [10, 11, 12], "sai": "Gợi ý: Trừ 2 từ số 11 rồi cộng 1 nào bé yêu!", "dung": "Xuất sắc! 11 cộng 1 bằng 12!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "16 ➡️ 14 ➡️ 15 ➡️ 13 ➡️ ❓", "dapAn": 14, "luaChon": [12, 13, 14], "sai": "Gợi ý: Quy luật zích zắc -2 rồi +1 quen thuộc!", "dung": "Tuyệt đỉnh! 13 cộng 1 bằng 14!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "17 ➡️ 15 ➡️ 16 ➡️ 14 ➡️ ❓", "dapAn": 15, "luaChon": [13, 14, 15], "sai": "Gợi ý: Sau khi trừ 2 thì ta phải cộng thêm 1 nhé!", "dung": "Quá giỏi! 14 cộng 1 bằng 15 chính xác!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "18 ➡️ 16 ➡️ 17 ➡️ 15 ➡️ ❓", "dapAn": 16, "luaChon": [14, 15, 16], "sai": "Gợi ý: Lấy 15 cộng thêm 1 đơn vị nào bé!", "dung": "Chính xác! 15 cộng 1 bằng 16!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "19 ➡️ 17 ➡️ 18 ➡️ 16 ➡️ ❓", "dapAn": 17, "luaChon": [15, 16, 17], "sai": "Gợi ý: Quy luật trừ 2 rồi cộng 1 nhịp nhàng!", "dung": "Tuyệt vời! 16 cộng 1 bằng 17!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "20 ➡️ 18 ➡️ 19 ➡️ 17 ➡️ ❓", "dapAn": 18, "luaChon": [16, 17, 18], "sai": "Gợi ý: Lấy số 17 cộng thêm 1 đơn vị nữa nhé!", "dung": "Quá siêu đẳng! 17 cộng 1 bằng 18!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "7 ➡️ 5 ➡️ 6 ➡️ 4 ➡️ ❓", "dapAn": 5, "luaChon": [3, 4, 5], "sai": "Gợi ý: Sau khi trừ 2 thì đổi sang cộng 1 nào!", "dung": "Đúng thế! 4 cộng 1 bằng 5!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "6 ➡️ 4 ➡️ 5 ➡️ 3 ➡️ ❓", "dapAn": 4, "luaChon": [2, 3, 4], "sai": "Gợi ý: Lấy số 3 cộng thêm 1 đơn vị nhé bé!", "dung": "Xuất sắc! 3 cộng 1 bằng 4 chuẩn xác!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "22 ➡️ 20 ➡️ 21 ➡️ 19 ➡️ ❓", "dapAn": 20, "luaChon": [18, 19, 20], "sai": "Gợi ý: Quy luật -2 rồi +1 lặp lại liên tục!", "dung": "Tuyệt đỉnh! 19 cộng 1 bằng 20!" },
{ "moTa": "Zích zắc giảm dần (-2 rồi +1)", "chuoi": "25 ➡️ 23 ➡️ 24 ➡️ 22 ➡️ ❓", "dapAn": 23, "luaChon": [21, 22, 23], "sai": "Gợi ý: Lấy 22 cộng thêm 1 đơn vị ở cuối dãy!", "dung": "Quá thông minh! 22 cộng 1 bằng 23 hoàn hảo!" },
{ "moTa": "Zích zắc giảm dần ", "chuoi": "30 ➡️ 28 ➡️ 29 ➡️ 27 ➡️ ❓", "dapAn": 28, "luaChon": [26, 27, 28], "sai": "Gợi ý: Trừ 2 rồi cộng 1, lấy 27 cộng 1 nào bé!", "dung": "Chính xác tuyệt đối! 27 cộng 1 bằng 28!" },
{ "moTa": "Dãy số lẻ liên tiếp", "chuoi": "1 ➡️ 3 ➡️ 5 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Đây là các số lẻ đứng cạnh nhau tăng dần nhé!", "dung": "Chính xác tuyệt đối! Số lẻ tiếp theo là 7!" },
{ "moTa": "Dãy số lẻ liên tiếp", "chuoi": "3 ➡️ 5 ➡️ 7 ➡️ ❓", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Số lẻ đứng ngay sau số 7 là mấy nào?", "dung": "Tuyệt đỉnh! Số lẻ tiếp theo là 9!" },
{ "moTa": "Dãy số lẻ liên tiếp", "chuoi": "5 ➡️ 7 ➡️ 9 ➡️ ❓", "dapAn": 11, "luaChon": [10, 11, 12], "sai": "Gợi ý: Cộng thêm 2 đơn vị vào số 9 nhé bé!", "dung": "Quá xuất sắc! Số 11 là đáp án chuẩn xác!" },
{ "moTa": "Ẩn số ở đầu dãy số lẻ", "chuoi": "❓ ➡️ 3 ➡️ 5 ➡️ 7", "dapAn": 1, "luaChon": [0, 1, 2], "sai": "Gợi ý: Số lẻ đầu tiên bắt đầu từ mấy?", "dung": "Quá thông minh! Số 1 đứng đầu tiên!" },
{ "moTa": "Dãy số lẻ liên tiếp", "chuoi": "7 ➡️ 9 ➡️ 11 ➡️ ❓", "dapAn": 13, "luaChon": [12, 13, 14], "sai": "Gợi ý: Cộng thêm 2 đơn vị vào số 11 nhé bé!", "dung": "Tuyệt vời! Số lẻ tiếp theo là 13!" },
{ "moTa": "Dãy số lẻ liên tiếp", "chuoi": "9 ➡️ 11 ➡️ 13 ➡️ ❓", "dapAn": 15, "luaChon": [14, 15, 16], "sai": "Gợi ý: Số lẻ đứng ngay sau số 13 là mấy nào?", "dung": "Chính xác tuyệt đối! Số lẻ tiếp theo là 15!" },
{ "moTa": "Dãy số lẻ liên tiếp", "chuoi": "11 ➡️ 13 ➡️ 15 ➡️ ❓", "dapAn": 17, "luaChon": [16, 17, 18], "sai": "Gợi ý: Thêm 2 vào số 15 sẽ ra bao nhiêu nhỉ?", "dung": "Quá xuất sắc! Số 17 là đáp án chuẩn xác!" },
{ "moTa": "Dãy số lẻ liên tiếp", "chuoi": "13 ➡️ 15 ➡️ 17 ➡️ ❓", "dapAn": 19, "luaChon": [18, 19, 20], "sai": "Gợi ý: Đếm thêm 2 đơn vị từ số 17 nào!", "dung": "Tuyệt đỉnh! Số lẻ tiếp theo là 19!" },
{ "moTa": "Dãy số lẻ liên tiếp", "chuoi": "15 ➡️ 17 ➡️ 19 ➡️ ❓", "dapAn": 21, "luaChon": [20, 21, 22], "sai": "Gợi ý: Số lẻ đứng sau số 19 là bao nhiêu?", "dung": "Quá thông minh! Số 21 chính xác hoàn hảo!" },
{ "moTa": "Ẩn số ở đầu dãy số lẻ", "chuoi": "❓ ➡️ 5 ➡️ 7 ➡️ 9", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Số lẻ đứng trước số 5 là mấy?", "dung": "Đúng rồi! Số 3 đứng trước số 5!" },
{ "moTa": "Ẩn số ở đầu dãy số lẻ", "chuoi": "❓ ➡️ 9 ➡️ 11 ➡️ 13", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Lùi lại 2 đơn vị từ số 9 nhé bé!", "dung": "Xuất sắc! Số 7 đứng trước số 9!" },
{ "moTa": "Ẩn số ở đầu dãy số lẻ", "chuoi": "❓ ➡️ 11 ➡️ 13 ➡️ 15", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Trước số 11 trong dãy số lẻ là số mấy?", "dung": "Tuyệt vời! Số 9 đứng đầu dãy!" },
{ "moTa": "Ẩn số ở giữa dãy số lẻ", "chuoi": "3 ➡️ ❓ ➡️ 7 ➡️ 9", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Số lẻ nằm giữa số 3 và số 7 là gì?", "dung": "Chính xác tuyệt đối! Số 5 đứng ở giữa!" },
{ "moTa": "Ẩn số ở giữa dãy số lẻ lớn", "chuoi": "7 ➡️ 9 ➡️ ❓ ➡️ 13", "dapAn": 11, "luaChon": [10, 11, 12], "sai": "Gợi ý: Số lẻ nằm giữa số 9 và số 13 nào!", "dung": "Quá giỏi! Số 11 là đáp án chính xác!" },
{ "moTa": "Dãy đếm lùi giảm dần", "chuoi": "5 ➡️ 4 ➡️ 3 ➡️ ❓", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Mỗi bước bớt đi 1 đơn vị theo chiều đếm ngược!", "dung": "Tuyệt vời! 5, 4, 3, 2 hoàn hảo!" },
{ "moTa": "Dãy đếm lùi giảm dần", "chuoi": "8 ➡️ 7 ➡️ 6 ➡️ ❓", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Lùi lại 1 đơn vị từ số 6 nhé bé!", "dung": "Chính xác tuyệt đối! Sau số 6 là số 5!" },
{ "moTa": "Dãy đếm lùi giảm dần", "chuoi": "10 ➡️ 9 ➡️ 8 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Trừ đi 1 đơn vị từ số 8 nào!", "dung": "Quá xuất sắc! Số 7 là đáp án chính xác!" },
{ "moTa": "Ẩn số ở đầu dãy đếm lùi", "chuoi": "❓ ➡️ 4 ➡️ 3 ➡️ 2", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Số nào đứng trước số 4 theo chiều đếm ngược?", "dung": "Quá thông minh! Số 5 đứng đầu tiên!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "6 ➡️ 5 ➡️ 4 ➡️ ❓", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Lùi lại 1 bước từ số 4 nhé bé!", "dung": "Tuyệt vời! Sau số 4 là số 3!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "7 ➡️ 6 ➡️ 5 ➡️ ❓", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Mỗi bước bớt đi 1 đơn vị nào!", "dung": "Chính xác tuyệt đối! Sau số 5 là số 4!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "9 ➡️ 8 ➡️ 7 ➡️ ❓", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Trừ đi 1 đơn vị từ số 7 nhé!", "dung": "Quá xuất sắc! Số 6 là đáp án chính xác!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "11 ➡️ 10 ➡️ 9 ➡️ ❓", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Lùi 1 bước từ số 9 nào bé yêu!", "dung": "Tuyệt đỉnh! Sau số 9 là số 8!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "12 ➡️ 11 ➡️ 10 ➡️ ❓", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Giảm đi 1 đơn vị từ số 10 nhé!", "dung": "Quá thông minh! Số 9 chuẩn xác!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "13 ➡️ 12 ➡️ 11 ➡️ ❓", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Trước số 11 trong dãy đếm lùi là số mấy?", "dung": "Đúng rồi! Số 10 hoàn hảo!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "14 ➡️ 13 ➡️ 12 ➡️ ❓", "dapAn": 11, "luaChon": [10, 11, 12], "sai": "Gợi ý: Lùi lại 1 bước từ số 12 nào!", "dung": "Xuất sắc! Số 11 là đáp án đúng!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "15 ➡️ 14 ➡️ 13 ➡️ ❓", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Trừ 1 từ số 13 nhé bé!", "dung": "Tuyệt vời! Sau số 13 là số 12!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "16 ➡️ 15 ➡️ 14 ➡️ ❓", "dapAn": 13, "luaChon": [12, 13, 14], "sai": "Gợi ý: Đếm lùi lại 1 bước từ số 14 nào!", "dung": "Chính xác! Số 13 chính xác tuyệt đối!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "17 ➡️ 16 ➡️ 15 ➡️ ❓", "dapAn": 14, "luaChon": [13, 14, 15], "sai": "Gợi ý: Lùi 1 đơn vị từ số 15 nhé bé!", "dung": "Quá giỏi! Số 14 hoàn toàn chính xác!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "18 ➡️ 17 ➡️ 16 ➡️ ❓", "dapAn": 15, "luaChon": [14, 15, 16], "sai": "Gợi ý: Giảm đi 1 đơn vị từ số 16 nào!", "dung": "Tuyệt đỉnh! Số 15 là đáp án đúng!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "19 ➡️ 18 ➡️ 17 ➡️ ❓", "dapAn": 16, "luaChon": [15, 16, 17], "sai": "Gợi ý: Trừ đi 1 từ số 17 nhé!", "dung": "Quá thông minh! Số 16 tuyệt vời!" },
{ "moTa": "Dãy đếm lùi bắt đầu", "chuoi": "20 ➡️ 19 ➡️ 18 ➡️ ❓", "dapAn": 17, "luaChon": [16, 17, 18], "sai": "Gợi ý: Lùi 1 bước từ số 18 nào bé yêu!", "dung": "Xuất sắc! Số 17 chuẩn xác!" },
{ "moTa": "Ẩn số ở đầu dãy đếm lùi", "chuoi": "❓ ➡️ 6 ➡️ 5 ➡️ 4", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Số nào đứng trước số 6 theo chiều đếm ngược?", "dung": "Đúng thế! Số 7 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy đếm lùi", "chuoi": "❓ ➡️ 7 ➡️ 6 ➡️ 5", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Trước số 7 là số mấy vậy bé?", "dung": "Tuyệt vời! Số 8 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy đếm lùi", "chuoi": "❓ ➡️ 8 ➡️ 7 ➡️ 6", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Lùi lại một bước ngược chiều từ số 8 nào!", "dung": "Chính xác tuyệt đối! Số 9 đứng đầu dãy!" },
{ "moTa": "Ẩn số ở đầu dãy đếm lùi", "chuoi": "❓ ➡️ 9 ➡️ 8 ➡️ 7", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Số nào đứng trước số 9 theo chiều đếm ngược?", "dung": "Quá thông minh! Số 10 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy đếm lùi", "chuoi": "❓ ➡️ 11 ➡️ 10 ➡️ 9", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Trước số 11 trong chiều đếm lùi là số mấy?", "dung": "Xuất sắc! Số 12 mở đầu hoàn hảo!" },
{ "moTa": "Ẩn số ở giữa dãy đếm lùi", "chuoi": "6 ➡️ ❓ ➡️ 4 ➡️ 3", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Số nằm giữa số 6 và số 4 là số mấy?", "dung": "Tuyệt đỉnh! Số 5 nằm ở giữa rất chính xác!" },
{ "moTa": "Ẩn số ở giữa dãy đếm lùi", "chuoi": "9 ➡️ 8 ➡️ ❓ ➡️ 6", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Số nằm giữa số 8 và số 6 nào bé!", "dung": "Quá giỏi! Số 7 nằm ở giữa hoàn hảo!" },
{ "moTa": "Dãy lặp lại cặp 2 số", "chuoi": "1 ➡️ 2 ➡️ 1 ➡️ 2 ➡️ ❓", "dapAn": 1, "luaChon": [1, 2, 3], "sai": "Quy luật: Vòng lặp luân phiên hai số 1 và 2 nhé bé!", "dung": "Quá thông minh! Lại là số 1 bắt đầu chu kỳ mới!" },
{ "moTa": "Dãy lặp lại cặp 2 số", "chuoi": "3 ➡️ 5 ➡️ 3 ➡️ 5 ➡️ ❓", "dapAn": 3, "luaChon": [3, 4, 5], "sai": "Gợi ý: Cặp số lặp lại là 3 và 5 xen kẽ nhau!", "dung": "Xuất sắc! Sau số 5 lại quay về số 3!" },
{ "moTa": "Dãy lặp lại cặp 2 số", "chuoi": "7 ➡️ 9 ➡️ 7 ➡️ 9 ➡️ ❓", "dapAn": 7, "luaChon": [7, 8, 9], "sai": "Quy luật: Luân phiên cặp số 7 và 9 liên tục!", "dung": "Tuyệt đỉnh! Chu kỳ tiếp theo bắt đầu với số 7!" },
{ "moTa": "Ẩn số ở đầu dãy lặp", "chuoi": "❓ ➡️ 2 ➡️ 1 ➡️ 2", "dapAn": 1, "luaChon": [1, 2, 3], "sai": "Gợi ý: Trước số 2 là số mấy trong cặp lặp 1 và 2?", "dung": "Chính xác tuyệt đối! Số 1 đứng đầu chuỗi!" },
{ "moTa": "Lặp lại cặp 2 số ", "chuoi": "2 ➡️ 4 ➡️ 2 ➡️ 4 ➡️ ❓", "dapAn": 2, "luaChon": [2, 3, 4], "sai": "Gợi ý: Cặp số lặp lại là 2 và 4 xen kẽ nhau nhé bé!", "dung": "Tuyệt vời! Sau số 4 lại quay về số 2!" },
{ "moTa": "Lặp lại cặp 2 số", "chuoi": "4 ➡️ 6 ➡️ 4 ➡️ 6 ➡️ ❓", "dapAn": 4, "luaChon": [4, 5, 6], "sai": "Gợi ý: Quy luật luân phiên hai số chẵn 4 và 6!", "dung": "Chính xác tuyệt đối! Vòng lặp mới bắt đầu với số 4!" },
{ "moTa": "Lặp lại cặp 2 số", "chuoi": "5 ➡️ 8 ➡️ 5 ➡️ 8 ➡️ ❓", "dapAn": 5, "luaChon": [5, 6, 8], "sai": "Gợi ý: Cặp số 5 và 8 đang lặp lại liên tục đấy!", "dung": "Quá thông minh! Tiếp theo là số 5!" },
{ "moTa": "Lặp lại cặp 2 số ", "chuoi": "6 ➡️ 10 ➡️ 6 ➡️ 10 ➡️ ❓", "dapAn": 6, "luaChon": [6, 8, 10], "sai": "Gợi ý: Chu kỳ lặp lại gồm hai số 6 và 10 nhé!", "dung": "Xuất sắc! Lại là số 6 hoàn hảo!" },
{ "moTa": "Lặp lại cặp 2 số", "chuoi": "8 ➡️ 12 ➡️ 8 ➡️ 12 ➡️ ❓", "dapAn": 8, "luaChon": [8, 10, 12], "sai": "Gợi ý: Luân phiên cặp số 8 và 12 nhịp nhàng!", "dung": "Tuyệt đỉnh! Chu kỳ tiếp theo bắt đầu bằng 8!" },
{ "moTa": "Ẩn số ở đầu dãy lặp lại ", "chuoi": "❓ ➡️ 4 ➡️ 2 ➡️ 4", "dapAn": 2, "luaChon": [2, 3, 4], "sai": "Gợi ý: Trước số 4 là số mấy trong cặp lặp 2 và 4?", "dung": "Đúng rồi! Số 2 đứng ở vị trí đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy lặp cặp", "chuoi": "❓ ➡️ 6 ➡️ 4 ➡️ 6", "dapAn": 4, "luaChon": [4, 5, 6], "sai": "Gợi ý: Số nào đứng trước số 6 trong chuỗi lặp 4 và 6?", "dung": "Quá giỏi! Số 4 mở đầu chuỗi chính xác!" },
{ "moTa": "Ẩn số ở giữa dãy lặp cặp", "chuoi": "3 ➡️ ❓ ➡️ 3 ➡️ 5 ➡️ 3", "dapAn": 5, "luaChon": [3, 4, 5], "sai": "Gợi ý: Số nằm giữa số 3 và số 3 là số mấy nhỉ?", "dung": "Chính xác tuyệt đối! Số 5 nằm ở giữa!" },
{ "moTa": "Ẩn số ở giữa dãy lặp cặp", "chuoi": "7 ➡️ 9 ➡️ ❓ ➡️ 9 ➡️ 7", "dapAn": 7, "luaChon": [7, 8, 9], "sai": "Gợi ý: Xem lại cặp số lặp 7 và 9 ở xung quanh nhé bé!", "dung": "Tuyệt vời! Số 7 nằm ở giữa rất chính xác!" },
{ "moTa": "Lặp lại cặp 2 số số ", "chuoi": "9 ➡️ 11 ➡️ 9 ➡️ 11 ➡️ ❓", "dapAn": 9, "luaChon": [9, 10, 11], "sai": "Gợi ý: Cặp số lẻ liên tiếp 9 và 11 đang lặp lại!", "dung": "Xuất sắc! Vòng lặp quay lại số 9 hoàn hảo!" },
{ "moTa": "Ẩn số ở đầu dãy số chẵn", "chuoi": "❓ ➡️ 4 ➡️ 6 ➡️ 8", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Số chẵn đầu tiên bắt đầu từ mấy nào?", "dung": "Quá thông minh! Số 2 đứng đầu tiên!" },
{ "moTa": "Dãy số chẵn liên tiếp bắt đầu từ 8", "chuoi": "8 ➡️ 10 ➡️ 12 ➡️ ❓", "dapAn": 14, "luaChon": [13, 14, 15], "sai": "Gợi ý: Cộng thêm 2 đơn vị vào số 12 nhé bé!", "dung": "Tuyệt vời! Số chẵn tiếp theo là 14!" },
{ "moTa": "Dãy số chẵn liên tiếp bắt đầu từ 10", "chuoi": "10 ➡️ 12 ➡️ 14 ➡️ ❓", "dapAn": 16, "luaChon": [15, 16, 17], "sai": "Gợi ý: Số chẵn đứng ngay sau số 14 là mấy nào?", "dung": "Chính xác tuyệt đối! Số chẵn tiếp theo là 16!" },
{ "moTa": "Dãy số chẵn liên tiếp vùng số lớn", "chuoi": "12 ➡️ 14 ➡️ 16 ➡️ ❓", "dapAn": 18, "luaChon": [17, 18, 19], "sai": "Gợi ý: Thêm 2 vào số 16 sẽ ra bao nhiêu nhỉ?", "dung": "Quá xuất sắc! Số 18 là đáp án chuẩn xác!" },
{ "moTa": "Dãy số chẵn liên tiếp mốc gần 20", "chuoi": "14 ➡️ 16 ➡️ 18 ➡️ ❓", "dapAn": 20, "luaChon": [19, 20, 21], "sai": "Gợi ý: Đếm thêm 2 đơn vị từ số 18 nào!", "dung": "Tuyệt đỉnh! Số chẵn tiếp theo là 20!" },
{ "moTa": "Dãy số chẵn liên tiếp mốc 20", "chuoi": "16 ➡️ 18 ➡️ 20 ➡️ ❓", "dapAn": 22, "luaChon": [21, 22, 23], "sai": "Gợi ý: Số chẵn đứng sau số 20 là bao nhiêu?", "dung": "Quá thông minh! Số 22 chính xác hoàn hảo!" },
{ "moTa": "Dãy số chẵn liên tiếp mốc lớn 22", "chuoi": "18 ➡️ 20 ➡️ 22 ➡️ ❓", "dapAn": 24, "luaChon": [23, 24, 25], "sai": "Gợi ý: Cộng thêm 2 vào số 22 nhé bé!", "dung": "Tuyệt vời! Số 24 là đáp án chính xác!" },
{ "moTa": "Dãy số chẵn liên tiếp mốc lớn 24", "chuoi": "20 ➡️ 22 ➡️ 24 ➡️ ❓", "dapAn": 26, "luaChon": [25, 26, 27], "sai": "Gợi ý: Sau số 24 là số chẵn nào tiếp theo?", "dung": "Chính xác! Số 26 hoàn hảo!" },
{ "moTa": "Dãy số chẵn liên tiếp mốc lớn 26", "chuoi": "22 ➡️ 24 ➡️ 26 ➡️ ❓", "dapAn": 28, "luaChon": [27, 28, 29], "sai": "Gợi ý: Thêm 2 đơn vị vào số 26 nào!", "dung": "Xuất sắc! Số 28 chuẩn xác!" },
{ "moTa": "Dãy số chẵn liên tiếp mốc lớn 28", "chuoi": "24 ➡️ 26 ➡️ 28 ➡️ ❓", "dapAn": 30, "luaChon": [29, 30, 31], "sai": "Gợi ý: Số chẵn tiếp theo sau số 28 là gì?", "dung": "Tuyệt đỉnh! Số 30 tuyệt vời!" },
{ "moTa": "Dãy số chẵn liên tiếp mốc lớn 30", "chuoi": "26 ➡️ 28 ➡️ 30 ➡️ ❓", "dapAn": 32, "luaChon": [31, 32, 33], "sai": "Gợi ý: Đếm thêm 2 từ số 30 nhé bé!", "dung": "Quá giỏi! Số 32 chính xác!" },
{ "moTa": "Ẩn số ở đầu dãy số chẵn từ 6", "chuoi": "❓ ➡️ 6 ➡️ 8 ➡️ 10", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Số chẵn đứng trước số 6 là mấy?", "dung": "Đúng rồi! Số 4 đứng trước số 6!" },
{ "moTa": "Ẩn số ở đầu dãy số chẵn từ 8", "chuoi": "❓ ➡️ 8 ➡️ 10 ➡️ 12", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Lùi lại 2 đơn vị từ số 8 nhé bé!", "dung": "Xuất sắc! Số 6 đứng trước số 8!" },
{ "moTa": "Ẩn số ở đầu dãy số chẵn từ 10", "chuoi": "❓ ➡️ 10 ➡️ 12 ➡️ 14", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Trước số 10 trong dãy số chẵn là số mấy?", "dung": "Tuyệt vời! Số 8 đứng đầu dãy!" },
{ "moTa": "Ẩn số ở đầu dãy số chẵn từ 12", "chuoi": "❓ ➡️ 12 ➡️ 14 ➡️ 16", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Lùi 2 đơn vị từ số 12 nào!", "dung": "Quá thông minh! Số 10 đứng trước số 12!" },
{ "moTa": "Ẩn số ở đầu dãy số chẵn từ 14", "chuoi": "❓ ➡️ 14 ➡️ 16 ➡️ 18", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Số chẵn đứng trước số 14 là bao nhiêu?", "dung": "Chính xác tuyệt đối! Số 12 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở giữa dãy số chẵn cơ bản", "chuoi": "2 ➡️ ❓ ➡️ 6 ➡️ 8", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Số chẵn nằm giữa số 2 và số 6 là gì?", "dung": "Chính xác tuyệt đối! Số 4 đứng ở giữa!" },
{ "moTa": "Ẩn số ở giữa dãy số chẵn lớn", "chuoi": "6 ➡️ 8 ➡️ ❓ ➡️ 12", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Số chẵn nằm giữa số 8 và số 12 nào!", "dung": "Quá giỏi! Số 10 là đáp án chính xác!" },
{ "moTa": "Ẩn số ở giữa dãy chẵn vùng 14", "chuoi": "10 ➡️ 12 ➡️ ❓ ➡️ 16", "dapAn": 14, "luaChon": [13, 14, 15], "sai": "Gợi ý: Số chẵn nằm giữa 12 và 16 là mấy nhỉ?", "dung": "Tuyệt đỉnh! Số 14 nằm ở giữa hoàn hảo!" },
{ "moTa": "Ẩn số ở giữa dãy chẵn vùng 18", "chuoi": "14 ➡️ 16 ➡️ ❓ ➡️ 20", "dapAn": 18, "luaChon": [17, 18, 19], "sai": "Gợi ý: Đếm thêm 2 từ số 16 hoặc lùi 2 từ 20 nào!", "dung": "Xuất sắc! Số 18 chính xác chuẩn xác!" },
{ "moTa": "Ẩn số ở giữa dãy chẵn vùng 22", "chuoi": "18 ➡️ 20 ➡️ ❓ ➡️ 24", "dapAn": 22, "luaChon": [21, 22, 23], "sai": "Gợi ý: Số nằm giữa số 20 và số 24 là gì nào bé?", "dung": "Quá thông minh! Số 22 đứng ở giữa tuyệt vời!" },
{ "moTa": "Dãy lùi đều trừ 2 cơ bản", "chuoi": "10 ➡️ 8 ➡️ 6 ➡️ ❓", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Mỗi bước giảm đi 2 đơn vị nhé!", "dung": "Tuyệt đỉnh! 6 trừ 2 bằng 4 chính xác!" },
{ "moTa": "Dãy lùi đều trừ 2 nâng cao", "chuoi": "9 ➡️ 7 ➡️ 5 ➡️ ❓", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Bớt đi 2 đơn vị từ số 5 nào bé!", "dung": "Quá xuất sắc! 5 trừ 2 bằng 3 chuẩn tuyệt đối!" },
{ "moTa": "Dãy lùi đều trừ 2 số lớn", "chuoi": "12 ➡️ 10 ➡️ 8 ➡️ ❓", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Lấy số 8 trừ đi 2 đơn vị nhé!", "dung": "Quá thông minh! 8 trừ 2 bằng 6 hoàn hảo!" },
{ "moTa": "Ẩn số ở đầu dãy lùi trừ 2", "chuoi": "❓ ➡️ 8 ➡️ 6 ➡️ 4", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Số nào lớn hơn 8 đúng 2 đơn vị theo chiều xuôi?", "dung": "Xuất sắc! Số 10 đứng đầu dãy số!" },
{ "moTa": "Dãy lùi đều trừ 2 bắt đầu từ 11", "chuoi": "11 ➡️ 9 ➡️ 7 ➡️ ❓", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Lấy số 7 trừ đi 2 đơn vị nhé bé!", "dung": "Tuyệt vời! 7 trừ 2 bằng 5 chính xác!" },
{ "moTa": "Dãy lùi đều trừ 2 bắt đầu từ 13", "chuoi": "13 ➡️ 11 ➡️ 9 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Bớt đi 2 đơn vị từ số 9 nào!", "dung": "Chính xác tuyệt đối! 9 trừ 2 bằng 7!" },
{ "moTa": "Dãy lùi đều trừ 2 bắt đầu từ 14", "chuoi": "14 ➡️ 12 ➡️ 10 ➡️ ❓", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Lấy số 10 trừ đi 2 đơn vị nhé!", "dung": "Quá xuất sắc! 10 trừ 2 bằng 8 hoàn hảo!" },
{ "moTa": "Dãy lùi đều trừ 2 bắt đầu từ 15", "chuoi": "15 ➡️ 13 ➡️ 11 ➡️ ❓", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Trừ đi 2 từ số 11 nào bé yêu!", "dung": "Tuyệt đỉnh! 11 trừ 2 bằng 9 chuẩn xác!" },
{ "moTa": "Dãy lùi đều trừ 2 bắt đầu từ 16", "chuoi": "16 ➡️ 14 ➡️ 12 ➡️ ❓", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Lùi lại 2 bước từ số 12 nhé!", "dung": "Quá thông minh! 12 trừ 2 bằng 10 tuyệt vời!" },
{ "moTa": "Ẩn số ở đầu dãy lùi trừ 2 từ 10", "chuoi": "❓ ➡️ 10 ➡️ 8 ➡️ 6", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Số nào lớn hơn 10 đúng 2 đơn vị nào?", "dung": "Đúng rồi! Số 12 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy lùi trừ 2 từ 12", "chuoi": "❓ ➡️ 12 ➡️ 10 ➡️ 8", "dapAn": 14, "luaChon": [13, 14, 15], "sai": "Gợi ý: Trước số 12 theo chiều xuôi là số mấy vậy bé?", "dung": "Xuất sắc! Số 14 đứng đầu dãy!" },
{ "moTa": "Ẩn số ở đầu dãy lùi trừ 2 từ 14", "chuoi": "❓ ➡️ 14 ➡️ 12 ➡️ 10", "dapAn": 16, "luaChon": [15, 16, 17], "sai": "Gợi ý: Lấy 14 cộng thêm 2 đơn vị để tìm số đầu nhé!", "dung": "Tuyệt vời! Số 16 mở đầu hoàn hảo!" },
{ "moTa": "Ẩn số ở giữa dãy lùi trừ 2 cơ bản", "chuoi": "10 ➡️ ❓ ➡️ 6 ➡️ 4", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Số nằm giữa số 10 và số 6 là mấy?", "dung": "Chính xác tuyệt đối! Số 8 nằm ở giữa!" },
{ "moTa": "Ẩn số ở giữa dãy lùi trừ 2 lớn", "chuoi": "14 ➡️ ❓ ➡️ 10 ➡️ 8", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Số nằm giữa số 14 và số 10 nào bé!", "dung": "Quá giỏi! Số 12 nằm ở giữa rất chính xác!" },
{ "moTa": "Dãy số cách đều cộng 3 cơ bản", "chuoi": "1 ➡️ 4 ➡️ 7 ➡️ ❓", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Mỗi bước cộng thêm 3 đơn vị liên tục nhé bé!", "dung": "Quá thông minh! 7 cộng 3 bằng 10 tuyệt vời!" },
{ "moTa": "Dãy số cách đều cộng 3 nâng cao", "chuoi": "4 ➡️ 7 ➡️ 10 ➡️ ❓", "dapAn": 13, "luaChon": [11, 12, 13], "sai": "Gợi ý: Lấy số 10 cộng thêm 3 đơn vị nữa nào!", "dung": "Xuất sắc! 10 cộng 3 bằng 13 chuẩn xác!" },
{ "moTa": "Dãy số cách đều cộng 3 số lớn", "chuoi": "7 ➡️ 10 ➡️ 13 ➡️ ❓", "dapAn": 16, "luaChon": [14, 15, 16], "sai": "Gợi ý: Cộng thêm 3 vào số 13 nhé bé!", "dung": "Tuyệt đỉnh! 13 cộng 3 bằng 16 hoàn hảo!" },
{ "moTa": "Ẩn số ở đầu dãy cách đều cộng 3", "chuoi": "❓ ➡️ 4 ➡️ 7 ➡️ 10", "dapAn": 1, "luaChon": [0, 1, 2], "sai": "Gợi ý: Số nào cộng thêm 3 để ra số 4 theo chiều xuôi?", "dung": "Quá thông minh! Số 1 đứng đầu tiên!" },
{ "moTa": "Dãy số cách đều cộng 3 bắt đầu từ 2", "chuoi": "2 ➡️ 5 ➡️ 8 ➡️ ❓", "dapAn": 11, "luaChon": [9, 10, 11], "sai": "Gợi ý: Cộng thêm 3 đơn vị vào số 8 nhé bé!", "dung": "Tuyệt vời! 8 cộng 3 bằng 11 chính xác!" },
{ "moTa": "Dãy số cách đều cộng 3 bắt đầu từ 3", "chuoi": "3 ➡️ 6 ➡️ 9 ➡️ ❓", "dapAn": 12, "luaChon": [10, 11, 12], "sai": "Gợi ý: Lấy số 9 cộng thêm 3 đơn vị nào!", "dung": "Chính xác tuyệt đối! 9 cộng 3 bằng 12!" },
{ "moTa": "Dãy số cách đều cộng 3 bắt đầu từ 5", "chuoi": "5 ➡️ 8 ➡️ 11 ➡️ ❓", "dapAn": 14, "luaChon": [12, 13, 14], "sai": "Gợi ý: Lấy số 11 cộng thêm 3 đơn vị nhé!", "dung": "Quá xuất sắc! 11 cộng 3 bằng 14 hoàn hảo!" },
{ "moTa": "Dãy số cách đều cộng 3 bắt đầu từ 6", "chuoi": "6 ➡️ 9 ➡️ 12 ➡️ ❓", "dapAn": 15, "luaChon": [13, 14, 15], "sai": "Gợi ý: Thêm 3 vào số 12 nào bé yêu!", "dung": "Tuyệt đỉnh! 12 cộng 3 bằng 15 chuẩn xác!" },
{ "moTa": "Dãy số cách đều cộng 3 bắt đầu từ 8", "chuoi": "8 ➡️ 11 ➡️ 14 ➡️ ❓", "dapAn": 17, "luaChon": [15, 16, 17], "sai": "Gợi ý: Đếm thêm 3 đơn vị từ số 14 nhé!", "dung": "Quá thông minh! 14 cộng 3 bằng 17 tuyệt vời!" },
{ "moTa": "Dãy số cách đều cộng 3 mốc lớn 10", "chuoi": "10 ➡️ 13 ➡️ 16 ➡️ ❓", "dapAn": 19, "luaChon": [17, 18, 19], "sai": "Gợi ý: Lấy 16 cộng thêm 3 đơn vị nào!", "dung": "Đúng rồi! 16 cộng 3 bằng 19 hoàn hảo!" },
{ "moTa": "Dãy số cách đều cộng 3 mốc lớn 12", "chuoi": "12 ➡️ 15 ➡️ 18 ➡️ ❓", "dapAn": 21, "luaChon": [19, 20, 21], "sai": "Gợi ý: Cộng thêm 3 vào số 18 nhé bé!", "dung": "Xuất sắc! 18 cộng 3 bằng 21 chuẩn xác!" },
{ "moTa": "Dãy số cách đều cộng 3 mốc lớn 14", "chuoi": "14 ➡️ 17 ➡️ 20 ➡️ ❓", "dapAn": 23, "luaChon": [21, 22, 23], "sai": "Gợi ý: Thêm 3 đơn vị vào số 20 nào!", "dung": "Tuyệt vời! 20 cộng 3 bằng 23 chính xác!" },
{ "moTa": "Dãy số cách đều cộng 3 mốc lớn 15", "chuoi": "15 ➡️ 18 ➡️ 21 ➡️ ❓", "dapAn": 24, "luaChon": [22, 23, 24], "sai": "Gợi ý: Lấy 21 cộng thêm 3 đơn vị nhé!", "dung": "Chính xác tuyệt đối! 21 cộng 3 bằng 24!" },
{ "moTa": "Dãy số cách đều cộng 3 mốc lớn 18", "chuoi": "18 ➡️ 21 ➡️ 24 ➡️ ❓", "dapAn": 27, "luaChon": [25, 26, 27], "sai": "Gợi ý: Đếm thêm 3 bước từ số 24 nào bé!", "dung": "Quá giỏi! 24 cộng 3 bằng 27 tuyệt vời!" },
{ "moTa": "Ẩn số ở đầu dãy cộng 3 từ 5", "chuoi": "❓ ➡️ 5 ➡️ 8 ➡️ 11", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Số nào cộng thêm 3 để ra số 5 theo chiều xuôi?", "dung": "Đúng thế! Số 2 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy cộng 3 từ 6", "chuoi": "❓ ➡️ 6 ➡️ 9 ➡️ 12", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Lùi lại 3 đơn vị từ số 6 nhé bé!", "dung": "Xuất sắc! Số 3 đứng đầu dãy!" },
{ "moTa": "Ẩn số ở đầu dãy cộng 3 từ 8", "chuoi": "❓ ➡️ 8 ➡️ 11 ➡️ 14", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Trước số 8 trong dãy cộng 3 là số mấy?", "dung": "Tuyệt vời! Số 5 mở đầu hoàn hảo!" },
{ "moTa": "Ẩn số ở giữa dãy cộng 3 cơ bản", "chuoi": "1 ➡️ ❓ ➡️ 7 ➡️ 10", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Số nằm giữa số 1 và số 7 là mấy?", "dung": "Chính xác tuyệt đối! Số 4 nằm ở giữa!" },
{ "moTa": "Ẩn số ở giữa dãy cộng 3 lớn", "chuoi": "4 ➡️ 7 ➡️ ❓ ➡️ 13", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Số nằm giữa số 7 và số 13 nào bé!", "dung": "Quá thông minh! Số 10 nằm ở giữa rất chính xác!" },
{ "moTa": "Dãy số giảm đều trừ ", "chuoi": "12 ➡️ 9 ➡️ 6 ➡️ ❓", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Mỗi bước giảm đi 3 đơn vị liên tục nhé bé!", "dung": "Quá thông minh! 6 trừ 3 bằng 3 tuyệt vời!" },
{ "moTa": "Dãy số giảm đều trừ ", "chuoi": "15 ➡️ 12 ➡️ 9 ➡️ ❓", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Lấy số 9 bớt đi 3 đơn vị nữa nào!", "dung": "Xuất sắc! 9 trừ 3 bằng 6 chuẩn xác!" },
{ "moTa": "Dãy số giảm đều trừ 3 ", "chuoi": "18 ➡️ 15 ➡️ 12 ➡️ ❓", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Lấy số 12 trừ đi 3 đơn vị tiếp tục nhé!", "dung": "Tuyệt đỉnh! 12 trừ 3 bằng 9 hoàn hảo!" },
{ "moTa": "Ẩn số ở đầu dãy giảm đều trừ 3", "chuoi": "❓ ➡️ 12 ➡️ 9 ➡️ 6", "dapAn": 15, "luaChon": [14, 15, 16], "sai": "Gợi ý: Số nào lớn hơn 12 đúng 3 đơn vị theo chiều xuôi?", "dung": "Quá tuyệt vời! Số 15 đứng đầu chuỗi giảm đều!" },
{ "moTa": "Dãy số giảm đều trừ 3 ", "chuoi": "21 ➡️ 18 ➡️ 15 ➡️ ❓", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Lấy số 15 trừ đi 3 đơn vị nhé bé!", "dung": "Tuyệt vời! 15 trừ 3 bằng 12 chính xác!" },
{ "moTa": "Dãy số giảm đều trừ 3 ", "chuoi": "24 ➡️ 21 ➡️ 18 ➡️ ❓", "dapAn": 15, "luaChon": [14, 15, 16], "sai": "Gợi ý: Bớt đi 3 đơn vị từ số 18 nào!", "dung": "Chính xác tuyệt đối! 18 trừ 3 bằng 15!" },
{ "moTa": "Dãy số giảm đều trừ 3 ", "chuoi": "27 ➡️ 24 ➡️ 21 ➡️ ❓", "dapAn": 18, "luaChon": [17, 18, 19], "sai": "Gợi ý: Lấy số 21 trừ đi 3 đơn vị nhé!", "dung": "Quá xuất sắc! 21 trừ 3 bằng 18 hoàn hảo!" },
{ "moTa": "Dãy số giảm đều trừ 3 ", "chuoi": "30 ➡️ 27 ➡️ 24 ➡️ ❓", "dapAn": 21, "luaChon": [20, 21, 22], "sai": "Gợi ý: Trừ đi 3 từ số 24 nào bé yêu!", "dung": "Tuyệt đỉnh! 24 trừ 3 bằng 21 chuẩn xác!" },
{ "moTa": "Dãy số giảm đều trừ 3 ", "chuoi": "33 ➡️ 30 ➡️ 27 ➡️ ❓", "dapAn": 24, "luaChon": [23, 24, 25], "sai": "Gợi ý: Lùi lại 3 bước từ số 27 nhé!", "dung": "Quá thông minh! 27 trừ 3 bằng 24 tuyệt vời!" },
{ "moTa": "Ẩn số ở đầu dãy giảm đều trừ 3 từ 18", "chuoi": "❓ ➡️ 18 ➡️ 15 ➡️ 12", "dapAn": 21, "luaChon": [20, 21, 22], "sai": "Gợi ý: Số nào lớn hơn 18 đúng 3 đơn vị nào?", "dung": "Đúng rồi! Số 21 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy giảm đều trừ 3 từ 21", "chuoi": "❓ ➡️ 21 ➡️ 18 ➡️ 15", "dapAn": 24, "luaChon": [23, 24, 25], "sai": "Gợi ý: Trước số 21 theo chiều xuôi là số mấy vậy bé?", "dung": "Xuất sắc! Số 24 đứng đầu dãy!" },
{ "moTa": "Ẩn số ở đầu dãy giảm đều trừ 3 từ 24", "chuoi": "❓ ➡️ 24 ➡️ 21 ➡️ 18", "dapAn": 27, "luaChon": [26, 27, 28], "sai": "Gợi ý: Lấy 24 cộng thêm 3 đơn vị để tìm số đầu nhé!", "dung": "Tuyệt vời! Số 27 mở đầu hoàn hảo!" },
{ "moTa": "Ẩn số ở giữa dãy giảm đều trừ 3 cơ bản", "chuoi": "15 ➡️ ❓ ➡️ 9 ➡️ 6", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Số nằm giữa số 15 và số 9 là mấy?", "dung": "Chính xác tuyệt đối! Số 12 nằm ở giữa!" },
{ "moTa": "Ẩn số ở giữa dãy giảm đều trừ 3 lớn", "chuoi": "21 ➡️ ❓ ➡️ 15 ➡️ 12", "dapAn": 18, "luaChon": [17, 18, 19], "sai": "Gợi ý: Số nằm giữa số 21 và số 15 nào bé!", "dung": "Quá giỏi! Số 18 nằm ở giữa rất chính xác!" },
{ "moTa": "Dãy đan xen cộng 1 trừ 2 cơ bản", "chuoi": "2 ➡️ 3 ➡️ 1 ➡️ 2 ➡️ ❓", "dapAn": 0, "luaChon": [0, 1, 3], "sai": "Gợi ý: Quy luật là cộng 1 rồi trừ 2 xen kẽ nhau!", "dung": "Tuyệt đỉnh! 2 trừ 2 bằng 0 chính xác!" },
{ "moTa": "Dãy đan xen cộng 1 trừ 2 nâng cao", "chuoi": "4 ➡️ 5 ➡️ 3 ➡️ 4 ➡️ ❓", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Lấy số trước cộng 1 rồi tiếp tục trừ 2 nhé bé!", "dung": "Quá xuất sắc! 4 trừ 2 bằng 2 chuẩn xác!" },
{ "moTa": "Dãy đan xen cộng 1 trừ 2 số lớn", "chuoi": "6 ➡️ 7 ➡️ 5 ➡️ 6 ➡️ ❓", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Luân phiên quy luật cộng 1 rồi trừ 2 liên tục nào!", "dung": "Tuyệt đỉnh! 6 trừ 2 bằng 4 hoàn hảo!" },
{ "moTa": "Ẩn số ở đầu dãy đan xen cộng 1 trừ 2", "chuoi": "❓ ➡️ 3 ➡️ 1 ➡️ 2", "dapAn": 2, "luaChon": [1, 2, 4], "sai": "Gợi ý: Số nào cộng 1 thì bằng 3 theo chiều xuôi?", "dung": "Quá thông minh! Số 2 đứng đầu tiên!" },
{ "moTa": "Dãy đan xen cộng 1 trừ 2 bắt đầu từ 3", "chuoi": "3 ➡️ 4 ➡️ 2 ➡️ 3 ➡️ ❓", "dapAn": 1, "luaChon": [0, 1, 2], "sai": "Gợi ý: Quy luật là cộng 1 rồi trừ 2 xen kẽ nhé bé!", "dung": "Tuyệt vời! 3 trừ 2 bằng 1 chính xác!" },
{ "moTa": "Dãy đan xen cộng 1 trừ 2 bắt đầu từ 5", "chuoi": "5 ➡️ 6 ➡️ 4 ➡️ 5 ➡️ ❓", "dapAn": 3, "luaChon": [2, 3, 4], "sai": "Gợi ý: Lấy số trước cộng 1 rồi tiếp tục trừ 2 nào!", "dung": "Chính xác tuyệt đối! 5 trừ 2 bằng 3 chuẩn xác!" },
{ "moTa": "Dãy đan xen cộng 1 trừ 2 bắt đầu từ 7", "chuoi": "7 ➡️ 8 ➡️ 6 ➡️ 7 ➡️ ❓", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Luân phiên quy luật cộng 1 rồi trừ 2 liên tục nhé!", "dung": "Quá xuất sắc! 7 trừ 2 bằng 5 hoàn hảo!" },
{ "moTa": "Dãy đan xen cộng 1 trừ 2 bắt đầu từ 8", "chuoi": "8 ➡️ 9 ➡️ 7 ➡️ 8 ➡️ ❓", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Cộng 1 rồi bớt đi 2 đơn vị nào bé yêu!", "dung": "Tuyệt đỉnh! 8 trừ 2 bằng 6 đúng rồi!" },
{ "moTa": "Dãy đan xen cộng 1 trừ 2 bắt đầu từ 9", "chuoi": "9 ➡️ 10 ➡️ 8 ➡️ 9 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Lấy 9 cộng 1 thành 10, rồi trừ 2 nào!", "dung": "Quá thông minh! 9 trừ 2 bằng 7 tuyệt vời!" },
{ "moTa": "Ẩn số ở đầu dãy đan xen cộng 1 trừ 2 từ số 4", "chuoi": "❓ ➡️ 4 ➡️ 2 ➡️ 3", "dapAn": 3, "luaChon": [2, 3, 5], "sai": "Gợi ý: Số nào cộng 1 thì bằng 4 theo chiều xuôi?", "dung": "Đúng thế! Số 3 đứng đầu chuỗi!" },
{ "moTa": "Ẩn số ở đầu dãy đan xen cộng 1 trừ 2 từ số 5", "chuoi": "❓ ➡️ 5 ➡️ 3 ➡️ 4", "dapAn": 4, "luaChon": [3, 4, 6], "sai": "Gợi ý: Trước số 5 theo quy luật cộng 1 là số mấy?", "dung": "Xuất sắc! Số 4 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy đan xen cộng 1 trừ 2 từ số 6", "chuoi": "❓ ➡️ 6 ➡️ 4 ➡️ 5", "dapAn": 5, "luaChon": [4, 5, 7], "sai": "Gợi ý: Số nào cộng thêm 1 để ra số 6 nào bé?", "dung": "Tuyệt vời! Số 5 mở đầu hoàn hảo!" },
{ "moTa": "Dãy nhân 3 trừ 1 cơ bản", "chuoi": "2 ➡️ 5 ➡️ 14 ➡️ ❓", "dapAn": 41, "luaChon": [39, 40, 41], "sai": "Gợi ý: Lấy số trước nhân 3 rồi trừ đi 1 (2x3-1, 5x3-1, 14x3-1)", "dung": "Quá xuất sắc! 14 nhân 3 trừ 1 bằng 41 chuẩn xác!" },
{ "moTa": "Ẩn số ở đầu dãy nhân 3 trừ 1", "chuoi": "❓ ➡️ 5 ➡️ 14 ➡️ 41", "dapAn": 2, "luaChon": [1, 2, 3], "sai": "Gợi ý: Số nào nhân 3 rồi trừ 1 thì bằng 5 theo chiều xuôi?", "dung": "Xuất sắc! Số 2 đứng đầu tiên!" },
{ "moTa": "Dãy số luân phiên cộng 2 trừ 1 số lớn", "chuoi": "5 ➡️ 7 ➡️ 6 ➡️ 8 ➡️ ❓", "dapAn": 7, "luaChon": [6, 7, 9], "sai": "Gợi ý: Quy luật cộng 2 rồi trừ 1 lặp lại liên tục!", "dung": "Tuyệt đỉnh! 8 trừ 1 bằng 7 chính xác!" },
{ "moTa": "Dãy số luân phiên cộng 2 trừ 1 nâng cao", "chuoi": "8 ➡️ 10 ➡️ 9 ➡️ 11 ➡️ ❓", "dapAn": 10, "luaChon": [9, 10, 12], "sai": "Gợi ý: Lấy số trước cộng 2 rồi trừ đi 1 nhé bé!", "dung": "Quá xuất sắc! 11 trừ 1 bằng 10 chuẩn xác!" },
{ "moTa": "Dãy số luân phiên cộng 2 trừ 1 số cực lớn", "chuoi": "12 ➡️ 14 ➡️ 13 ➡️ 15 ➡️ ❓", "dapAn": 14, "luaChon": [13, 14, 16], "sai": "Gợi ý: Tiếp tục chu kỳ cộng 2 rồi trừ 1 nào!", "dung": "Tuyệt đỉnh! 15 trừ 1 bằng 14 hoàn hảo!" },
{ "moTa": "Ẩn số ở đầu dãy luân phiên cộng 2 trừ 1", "chuoi": "❓ ➡️ 7 ➡️ 6 ➡️ 8", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Số nào cộng 2 để ra số 7 theo chiều xuôi?", "dung": "Quá thông minh! Số 5 đứng đầu chuỗi!" },
{ "moTa": "Dãy số luân phiên cộng 2 trừ 1 bắt đầu từ 3", "chuoi": "3 ➡️ 5 ➡️ 4 ➡️ 6 ➡️ ❓", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Quy luật cộng 2 rồi trừ 1 xen kẽ nhau nhé bé!", "dung": "Tuyệt vời! 6 trừ 1 bằng 5 chính xác!" },
{ "moTa": "Dãy số luân phiên cộng 2 trừ 1 bắt đầu từ 4", "chuoi": "4 ➡️ 6 ➡️ 5 ➡️ 7 ➡️ ❓", "dapAn": 6, "luaChon": [5, 6, 8], "sai": "Gợi ý: Lấy số trước cộng 2 rồi trừ đi 1 nào!", "dung": "Chính xác tuyệt đối! 7 trừ 1 bằng 6 chuẩn xác!" },
{ "moTa": "Dãy số luân phiên cộng 2 trừ 1 bắt đầu từ 6", "chuoi": "6 ➡️ 8 ➡️ 7 ➡️ 9 ➡️ ❓", "dapAn": 8, "luaChon": [7, 8, 10], "sai": "Gợi ý: Luân phiên quy luật cộng 2 rồi trừ 1 liên tục nhé!", "dung": "Quá xuất sắc! 9 trừ 1 bằng 8 hoàn hảo!" },
{ "moTa": "Dãy số luân phiên cộng 2 trừ 1 bắt đầu từ 7", "chuoi": "7 ➡️ 9 ➡️ 8 ➡️ 10 ➡️ ❓", "dapAn": 9, "luaChon": [8, 9, 11], "sai": "Gợi ý: Cộng 2 rồi bớt đi 1 đơn vị nào bé yêu!", "dung": "Tuyệt đỉnh! 10 trừ 1 bằng 9 đúng rồi!" },
{ "moTa": "Dãy số luân phiên cộng 2 trừ 1 bắt đầu từ 9", "chuoi": "9 ➡️ 11 ➡️ 10 ➡️ 12 ➡️ ❓", "dapAn": 11, "luaChon": [10, 11, 13], "sai": "Gợi ý: Lấy 9 cộng 2 thành 11, rồi trừ 1 nào!", "dung": "Quá thông minh! 12 trừ 1 bằng 11 tuyệt vời!" },
{ "moTa": "Ẩn số ở đầu dãy luân phiên cộng 2 trừ 1 bắt", "chuoi": "❓ ➡️ 6 ➡️ 5 ➡️ 7", "dapAn": 4, "luaChon": [3, 4, 5], "sai": "Gợi ý: Số nào cộng 2 thì bằng 6 theo chiều xuôi?", "dung": "Đúng thế! Số 4 đứng đầu chuỗi!" },
{ "moTa": "Ẩn số ở đầu dãy luân phiên cộng 2 trừ 1 bắt", "chuoi": "❓ ➡️ 8 ➡️ 7 ➡️ 9", "dapAn": 6, "luaChon": [5, 6, 7], "sai": "Gợi ý: Trước số 8 theo quy luật cộng 2 là số mấy?", "dung": "Xuất sắc! Số 6 đứng đầu tiên!" },
{ "moTa": "Ẩn số ở đầu dãy luân phiên cộng 2 trừ 1 bắt", "chuoi": "❓ ➡️ 9 ➡️ 8 ➡️ 10", "dapAn": 7, "luaChon": [6, 7, 8], "sai": "Gợi ý: Số nào cộng thêm 2 để ra số 9 nào bé?", "dung": "Tuyệt vời! Số 7 mở đầu hoàn hảo!" },
{ "moTa": "Ẩn số ở giữa dãy luân phiên cộng 2 trừ 1 cơ bản", "chuoi": "3 ➡️ ❓ ➡️ 4 ➡️ 6 ➡️ 5", "dapAn": 5, "luaChon": [4, 5, 6], "sai": "Gợi ý: Số đứng giữa 3 và 4 theo quy luật cộng 2 là gì?", "dung": "Chính xác tuyệt đối! Số 5 nằm ở giữa!" },
{ "moTa": "Ẩn số ở giữa dãy luân phiên cộng 2 trừ 1 nâng cao", "chuoi": "6 ➡️ ❓ ➡️ 7 ➡️ 9 ➡️ 8", "dapAn": 8, "luaChon": [7, 8, 9], "sai": "Gợi ý: Số nằm giữa số 6 và số 7 theo quy luật cộng 2 nào!", "dung": "Quá giỏi! Số 8 nằm ở giữa rất chính xác!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 cơ bản", "chuoi": "10 ➡️ 9 ➡️ 12 ➡️ ❓", "dapAn": 11, "luaChon": [10, 11, 13], "sai": "Gợi ý: Quy luật là trừ 1 rồi cộng 3 xen kẽ nhau (10-1=9, 9+3=12, tiếp theo là 12-1)", "dung": "Tuyệt đỉnh! 12 trừ 1 bằng 11 chính xác!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 nâng cao", "chuoi": "10 ➡️ 9 ➡️ 12 ➡️ 11 ➡️ ❓", "dapAn": 14, "luaChon": [12, 13, 14], "sai": "Gợi ý: Tiếp tục chu kỳ trừ 1 rồi cộng 3 với số 11 nhé bé!", "dung": "Xuất sắc! 11 cộng 3 bằng 14 chuẩn xác!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 số lớn", "chuoi": "20 ➡️ 19 ➡️ 22 ➡️ 21 ➡️ ❓", "dapAn": 24, "luaChon": [22, 23, 24], "sai": "Gợi ý: Lấy số trước trừ 1 rồi cộng 3 luân phiên nào!", "dung": "Quá thông minh! 21 cộng 3 bằng 24 hoàn hảo!" },
{ "moTa": "Ẩn số ở đầu dãy xen kẽ trừ 1 cộng 3", "chuoi": "❓ ➡️ 9 ➡️ 12 ➡️ 11", "dapAn": 10, "luaChon": [9, 10, 11], "sai": "Gợi ý: Số nào trừ 1 để ra số 9 theo chiều xuôi?", "dung": "Tuyệt vời! Số 10 đứng đầu dãy!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 bắt đầu từ 8", "chuoi": "8 ➡️ 7 ➡️ 10 ➡️ ❓", "dapAn": 9, "luaChon": [8, 9, 11], "sai": "Gợi ý: Quy luật là trừ 1 rồi cộng 3 xen kẽ nhau (8-1=7, 7+3=10, tiếp theo là 10-1)", "dung": "Tuyệt đỉnh! 10 trừ 1 bằng 9 chính xác!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 bắt đầu từ 9", "chuoi": "9 ➡️ 8 ➡️ 11 ➡️ ❓", "dapAn": 10, "luaChon": [9, 10, 12], "sai": "Gợi ý: Lấy số 11 trừ đi 1 đơn vị nhé bé!", "dung": "Chính xác tuyệt đối! 11 trừ 1 bằng 10!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 bắt đầu từ 11", "chuoi": "11 ➡️ 10 ➡️ 13 ➡️ ❓", "dapAn": 12, "luaChon": [11, 12, 14], "sai": "Gợi ý: Trừ 1 rồi cộng 3 liên tục nào bé yêu!", "dung": "Quá xuất sắc! 13 trừ 1 bằng 12 hoàn hảo!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 bắt đầu từ 12", "chuoi": "12 ➡️ 11 ➡️ 14 ➡️ ❓", "dapAn": 13, "luaChon": [12, 13, 15], "sai": "Gợi ý: Tiếp tục lấy số 14 trừ đi 1 đơn vị nhé!", "dung": "Tuyệt đỉnh! 14 trừ 1 bằng 13 chuẩn xác!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 bắt đầu từ 14", "chuoi": "14 ➡️ 13 ➡️ 16 ➡️ ❓", "dapAn": 15, "luaChon": [14, 15, 17], "sai": "Gợi ý: Lấy số 16 bớt đi 1 đơn vị nào!", "dung": "Quá thông minh! 16 trừ 1 bằng 15 tuyệt vời!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 nâng cao từ 8", "chuoi": "8 ➡️ 7 ➡️ 10 ➡️ 9 ➡️ ❓", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Tiếp tục chu kỳ trừ 1 rồi cộng 3 với số 9 nhé!", "dung": "Đúng rồi! 9 cộng 3 bằng 12 hoàn hảo!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 nâng cao từ 9", "chuoi": "9 ➡️ 8 ➡️ 11 ➡️ 10 ➡️ ❓", "dapAn": 13, "luaChon": [12, 13, 14], "sai": "Gợi ý: Lấy số 10 cộng thêm 3 đơn vị nào bé!", "dung": "Xuất sắc! 10 cộng 3 bằng 13 chuẩn xác!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 nâng cao từ 11", "chuoi": "11 ➡️ 10 ➡️ 13 ➡️ 12 ➡️ ❓", "dapAn": 15, "luaChon": [14, 15, 16], "sai": "Gợi ý: Lấy số 12 cộng tiếp 3 đơn vị nhé!", "dung": "Tuyệt vời! 12 cộng 3 bằng 15 chính xác!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 nâng cao từ 12", "chuoi": "12 ➡️ 11 ➡️ 14 ➡️ 13 ➡️ ❓", "dapAn": 16, "luaChon": [15, 16, 17], "sai": "Gợi ý: Cộng thêm 3 vào số 13 nào!", "dung": "Chính xác tuyệt đối! 13 cộng 3 bằng 16!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 số lớn từ 15", "chuoi": "15 ➡️ 14 ➡️ 17 ➡️ 16 ➡️ ❓", "dapAn": 19, "luaChon": [18, 19, 20], "sai": "Gợi ý: Lấy số 16 cộng thêm 3 đơn vị nhé bé!", "dung": "Quá giỏi! 16 cộng 3 bằng 19 tuyệt vời!" },
{ "moTa": "Dãy số xen kẽ trừ 1 cộng 3 số lớn từ 16", "chuoi": "16 ➡️ 15 ➡️ 18 ➡️ 17 ➡️ ❓", "dapAn": 20, "luaChon": [19, 20, 21], "sai": "Gợi ý: Tiếp tục chu kỳ trừ 1 rồi cộng 3 với số 17 nào!", "dung": "Đúng thế! 17 cộng 3 bằng 20 chính xác!" },
{ "moTa": "Ẩn số ở đầu dãy xen kẽ từ 8", "chuoi": "❓ ➡️ 8 ➡️ 11 ➡️ 10", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Số nào trừ 1 để ra số 8 theo chiều xuôi?", "dung": "Xuất sắc! Số 9 đứng đầu dãy!" },
{ "moTa": "Ẩn số ở đầu dãy xen kẽ từ 11", "chuoi": "❓ ➡️ 11 ➡️ 14 ➡️ 13", "dapAn": 12, "luaChon": [11, 12, 13], "sai": "Gợi ý: Trước số 11 theo quy luật trừ 1 là số mấy?", "dung": "Tuyệt vời! Số 12 mở đầu hoàn hảo!" },
{ "moTa": "Ẩn số ở giữa dãy xen kẽ trừ 1 cộng 3 cơ bản", "chuoi": "10 ➡️ ❓ ➡️ 12 ➡️ 11", "dapAn": 9, "luaChon": [8, 9, 10], "sai": "Gợi ý: Số nằm giữa 10 và 12 theo quy luật trừ 1 là gì?", "dung": "Chính xác tuyệt đối! Số 9 nằm ở giữa!" },
{ "moTa": "Ẩn số ở giữa dãy xen kẽ trừ 1 cộng 3 lớn", "chuoi": "15 ➡️ ❓ ➡️ 17 ➡️ 16", "dapAn": 14, "luaChon": [13, 14, 15], "sai": "Gợi ý: Số nằm giữa 15 và 17 theo quy luật trừ 1 nào bé!", "dung": "Quá giỏi! Số 14 nằm ở giữa rất chính xác!" },
{ "moTa": "Dãy số cấp số cộng bước nhảy lớn cơ bản", "chuoi": "5 ➡️ 10 ➡️ 15 ➡️ ❓", "dapAn": 25, "luaChon": [23, 25, 27], "sai": "Gợi ý: Mỗi bước đếm tiến thêm 5 đơn vị liên tục nào!", "dung": "Quá thông minh! 20 cộng 5 bằng 25 tuyệt vời!" },
{ "moTa": "Dãy số cấp số cộng bước nhảy lớn nâng cao", "chuoi": "10 ➡️ 20 ➡️ 30 ➡️ ❓", "dapAn": 40, "luaChon": [35, 40, 45], "sai": "Gợi ý: Mỗi bước tăng đều thêm 10 đơn vị nhé bé!", "dung": "Xuất sắc! 30 cộng 10 bằng 40 chuẩn xác!" },
{ "moTa": "Dãy số cấp số cộng bước nhảy lớn số lớn", "chuoi": "25 ➡️ 50 ➡️ 75 ➡️ ❓", "dapAn": 100, "luaChon": [90, 100, 110], "sai": "Gợi ý: Khoảng cách giữa các số là 25 đơn vị liên tục!", "dung": "Tuyệt đỉnh! 75 cộng 25 bằng 100 hoàn hảo!" },
{ "moTa": "Ẩn số ở đầu dãy cấp số cộng bước nhảy lớn", "chuoi": "❓ ➡️ 10 ➡️ 15 ➡️ 20", "dapAn": 5, "luaChon": [0, 5, 10], "sai": "Gợi ý: Số nào cộng thêm 5 để ra số 10 theo chiều xuôi?", "dung": "Quá tuyệt vời! Số 5 đứng đầu dãy!" }
  ];
  @override
  void initState() {
    super.initState();
    _khoiTaoTtsVaCauHoi();
  }
  Future<void> _khoiTaoTtsVaCauHoi() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.5);
    _taiLaiDanhSachNgauNhien();
    _taoThuThachMoi();
  }
  void _taiLaiDanhSachNgauNhien() {
    _danhSachChiSoChuaDung.clear();
    for (int i = 0; i < _khoThuThach.length; i++) {
      _danhSachChiSoChuaDung.add(i);
    }
    _danhSachChiSoChuaDung.shuffle(_random);
  }
  void _taoThuThachMoi() {
    if (_danhSachChiSoChuaDung.isEmpty) {
      _taiLaiDanhSachNgauNhien();
    }
    _currentIndex = _danhSachChiSoChuaDung.removeAt(0);
    final item = _khoThuThach[_currentIndex];
    setState(() {
      cauHoiMoTa = item["moTa"];
      chuoiHienThi = item["chuoi"];
      dapAnDung = item["dapAn"];
      danhSachLuaChon = List<int>.from(item["luaChon"]);
      goiYSai = item["sai"];
      goiYDung = item["dung"];
      _thongBaoTrangThai = ""; 
    });
    flutterTts.speak(cauHoiMoTa);
  }
  // Bảng hiển thị lịch sử làm bài (giống hệt cấu trúc chuẩn của Toán Chéo)
  void _hienThiBangKiemTraLichSu() {
    int tongSoCau = _lichSuLamBai.length;
    double diemTichLuy = tongSoCau > 0 ? (_soCauDung / tongSoCau) * 10 : 0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assessment_rounded, color: Colors.purple, size: 26),
                  SizedBox(width: 8),
                  Text("Kết Quả Làm Bài", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6A1B9A))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _itemThongKe("Tổng câu", "$tongSoCau", Colors.blue.shade700),
                      _itemThongKe("Đúng", "$_soCauDung", Colors.green.shade700),
                      _itemThongKe("Sai", "$_soCauSai", Colors.red.shade600),
                      _itemThongKe("Điểm", "${diemTichLuy.toStringAsFixed(1)}đ", Colors.purple.shade700),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  tongSoCau == 0
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text("Bé chưa hoàn thành câu hỏi nào cả!", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lichSuLamBai.length,
                          itemBuilder: (context, index) {
                            var item = _lichSuLamBai[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: item.laDung ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.laDung ? Colors.green.shade200 : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Câu ${item.soThuTu}: ${item.moTa}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4E342E)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Đề: ${item.chuoiHienThi} | Bé chọn: ${item.luaChonCuaBe} | Đúng: ${item.dapAnDung}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: item.laDung ? Colors.black87 : Colors.red.shade700,
                                            fontWeight: item.laDung ? FontWeight.normal : FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.laDung ? Colors.green.shade100 : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.laDung ? "Đúng ✓" : "Sai ✗",
                                      style: TextStyle(
                                        color: item.laDung ? Colors.green.shade800 : Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _itemThongKe(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _nutQuayLaiCam(
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Mê Cung Số Học Đỉnh Cao",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        actions: [
          // Nút mở lịch sử (icon cuốn sổ)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _nutKiemTraCauHoi(
              onTap: () {
                _hienThiBangKiemTraLichSu();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _ngoiSaoVang(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cauHoiMoTa,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purpleAccent, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.purple.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Text(
                  chuoiHienThi,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              if (_thongBaoTrangThai.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    _thongBaoTrangThai,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Text("Bé hãy chọn đáp án đúng để vượt mê cung:",
                  style: TextStyle(fontSize: 1, color: Colors.black54)),
              const SizedBox(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: danhSachLuaChon.map((so) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        bool laDung = (so == dapAnDung);
                        setState(() {
                          if (laDung) {
                            _soCauDung++;
                          } else {
                            _soCauSai++;
                          }
                          // Ghi nhận vào nhật ký lịch sử làm bài
                          _lichSuLamBai.add(NhatKyMeCung(
                            soThuTu: _lichSuLamBai.length + 1,
                            moTa: cauHoiMoTa,
                            chuoiHienThi: chuoiHienThi,
                            dapAnDung: dapAnDung,
                            luaChonCuaBe: so,
                            laDung: laDung,
                          ));
                        });

                        if (laDung) {
                          flutterTts.speak(goiYDung);
                          _hienThongBaoDung(
                              context, "🎉 Hoan hô bé!", goiYDung);
                        } else {
                          flutterTts.speak(goiYSai);
                          setState(() {
                            _thongBaoTrangThai = goiYSai;
                          });
                        }
                      },
                      child: Text("$so",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 1),
              TextButton.icon(
                onPressed: () => flutterTts.speak(cauHoiMoTa),
                icon: const Icon(Icons.volume_up, color: Colors.purple),
                label: const Text("Nghe lại câu hỏi",
                    style: TextStyle(color: Colors.purple, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _nutQuayLaiCam({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.yellow.shade700, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.grey.shade700,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  Widget _nutKiemTraCauHoi({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.purpleAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.list_alt_rounded,
              color: Colors.purple,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  // Ngôi sao vàng góc phải kèm theo tổng số câu bé đã trả lời
Widget _ngoiSaoVang() {
  int tongSoCauDaLam = _lichSuLamBai.length;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.amber, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.amber.withOpacity(0.4),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          color: Colors.amber,
          size: 22,
        ),
        const SizedBox(width: 4),
        Text(
          "$tongSoCauDaLam",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF8D6E63),
          ),
        ),
      ],
    ),
  );
}
  void _hienThongBaoDung(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        Future.delayed(const Duration(milliseconds: 3700), () {
          if (Navigator.canPop(c)) {
            Navigator.pop(c);
            _taoThuThachMoi();
          }
        });
        return AlertDialog(
          title: Text(title),
          content: Text(msg, style: const TextStyle(fontSize: 16)),
        );
      },
    );
  }
}

//TRANG QUY LUẬT ẨN
class NhatKyQuyLuat {
  final int soThuTu;
  final String tieuDe;
  final String deBai;
  final String dapAnDung;
  final String luaChonCuaBe;
  final bool laDung;

  NhatKyQuyLuat({
    required this.soThuTu,
    required this.tieuDe,
    required this.deBai,
    required this.dapAnDung,
    required this.luaChonCuaBe,
    required this.laDung,
  });
}
class TrangQuyLuatAn extends StatefulWidget {
  const TrangQuyLuatAn({super.key});
  @override
  State<TrangQuyLuatAn> createState() => _TrangQuyLuatAnState();
}
class _TrangQuyLuatAnState extends State<TrangQuyLuatAn> {
  final FlutterTts flutterTts = FlutterTts();
  late ConfettiController _confettiController;
  int soLanDienLienTiep = 0;
  bool dangKhoaNut = false;
  // 1. Khai báo đúng kiểu dữ liệu
  late List<Map<String, dynamic>> danhSachCauHoiXaoTron;
  int chiSoCauHienTai = 0;
  Map<String, dynamic>? cauHoiHienTai;
  // Quản lý lịch sử làm bài và điểm số (Chỉ khai báo duy nhất 1 lần)
  final List<NhatKyQuyLuat> _lichSuLamBai = [];
  int _soCauDung = 0;
  int _soCauSai = 0;
  // Danh sách câu hỏi gốc đầy đủ
  final List<Map<String, dynamic>> danhSachQuyLuatGoc = const [
    // 1. DẠNG GỐC (LẶP THEO CHU KỲ)
    {
      "tieuDe": "Quy luật màu sắc",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🔴 🔵 🟡 🔴 🔵 🟡  ❓",
      "docCauHoi": "Giải mã quy luật lặp: Hình nào sẽ xuất hiện tiếp theo?",
      "dapAnDung": "🔴",
      "tenDapAn": "🔴 Đỏ",
      "danhSachLuaChon": ["🔴", "🔵", "🟡"],
      "thongBaoDung": "Đúng rồi! Chuỗi lặp lại Đỏ - Xanh - Vàng.",
      "thongBaoSai": "Sai rồi, hãy quan sát vòng lặp 3 màu nhé!",
    },
    {
      "tieuDe": "Quy luật lặp 4 màu",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🔴 🔵 🟡 🟢 🔴 🔵 🟡  ❓",
      "docCauHoi":
          "Đỏ, xanh dương, vàng, xanh lá. Rồi lại Đỏ, xanh dương, vàng. Tiếp theo là màu gì bé nhỉ?",
      "dapAnDung": "🟢",
      "tenDapAn": "🟢 Xanh lá",
      "danhSachLuaChon": ["🟢", "🔴", "🟡"],
      "thongBaoDung":
          "Chính xác! Vòng lặp gồm 4 màu: Đỏ - Xanh dương - Vàng - Xanh lá.",
      "thongBaoSai": "Chưa đúng rồi, bé quan sát kỹ chuỗi 4 màu nhé!"
    },
    {
      "tieuDe": "Quy luật cặp đôi song hành",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍎 🍎 🍌 🍌 🍎 🍎  ❓",
      "docCauHoi":
          "Hai quả táo, hai quả chuối, rồi lại hai quả táo. Tiếp theo là quả gì bé ơi?",
      "dapAnDung": "🍌",
      "tenDapAn": "🍌 Quả chuối",
      "danhSachLuaChon": ["🍌", "🍎", "🍊"],
      "thongBaoDung": "Giỏi quá! Các quả đi thành từng cặp 2 Táo - 2 Chuối.",
      "thongBaoSai": "Thử lại nào, sau cặp hai quả táo sẽ tới cặp quả gì nhỉ?"
    },
    {
      "tieuDe": "Quy luật xen kẽ kẹp giữa",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "⭐ 🌙 ⭐ ☀️ ⭐ 🌙 ⭐  ❓",
      "docCauHoi":
          "Ngôi sao, mặt trăng, ngôi sao, mặt trời, ngôi sao, mặt trăng, ngôi sao. Tiếp theo là gì?",
      "dapAnDung": "☀️",
      "tenDapAn": "☀️ Mặt trời",
      "danhSachLuaChon": ["☀️", "🌙", "⭐"],
      "thongBaoDung":
          "Xuất sắc! Ngôi sao luôn đứng xen kẽ giữa Mặt trăng và Mặt trời.",
      "thongBaoSai":
          "Chưa chính xác, bé chú ý xem sau Mặt trăng là đến hình gì nhé!"
    },
    {
      "tieuDe": "Quy luật 4 hình khối",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🟦 🔺 🟡 🟩 🟦 🔺  ❓",
      "docCauHoi":
          "Vuông xanh, tam giác đỏ, tròn vàng, vuông xanh lá. Lại đến vuông xanh, tam giác. Tiếp theo là hình gì?",
      "dapAnDung": "🟡",
      "tenDapAn": "🟡 Tròn vàng",
      "danhSachLuaChon": ["🟡", "🟩", "🟦"],
      "thongBaoDung": "Đúng rồi! Chuỗi lặp lại bộ 4 hình khối.",
      "thongBaoSai": "Sai rồi, bé quan sát lại thứ tự 4 hình khối nhé!"
    },
    {
      "tieuDe": "Quy luật nhịp điệu 2-1-2",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐱 🐱 🐶 🐰 🐰 🐶 🐱 🐱  ❓",
      "docCauHoi":
          "Hai mèo, một cún, hai thỏ, một cún. Lại đến hai mèo. Tiếp theo là con vật nào?",
      "dapAnDung": "🐶",
      "tenDapAn": "🐶 Chú cún",
      "danhSachLuaChon": ["🐶", "🐱", "🐰"],
      "thongBaoDung":
          "Thông minh lắm! Đứng giữa các cặp mèo và thỏ luôn là chú cún.",
      "thongBaoSai":
          "Thử lại xem, chú cún đứng ở vị trí xen kẽ giữa các cặp con vật đấy!"
    },
    {
      "tieuDe": "Quy luật phương tiện 4 bước",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🚗 🚲 ✈️ 🚢 🚗 🚲 ✈️  ❓",
      "docCauHoi":
          "Ô tô, xe đạp, máy bay, tàu thủy. Rồi lại ô tô, xe đạp, máy bay. Tiếp theo là xe gì?",
      "dapAnDung": "🚢",
      "tenDapAn": "🚢 Tàu thủy",
      "danhSachLuaChon": ["🚢", "🚗", "🚲"],
      "thongBaoDung":
          "Tuyệt vời! Chuỗi hành trình gồm 4 phương tiện nối tiếp nhau.",
      "thongBaoSai": "Chưa đúng, phương tiện nào đi sau máy bay bé nhỉ?"
    },
    {
      "tieuDe": "Quy luật hoa quả 4 mùa",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍉 🍇 🍊 🍓 🍉 🍇  ❓",
      "docCauHoi":
          "Dưa hấu, nho, cam, dâu tây. Lại đến dưa hấu, nho. Đố bé quả tiếp theo là gì?",
      "dapAnDung": "🍊",
      "tenDapAn": "🍊 Quả cam",
      "danhSachLuaChon": ["🍊", "🍓", "🍉"],
      "thongBaoDung": "Chính xác! Chuỗi lặp lại 4 loại quả theo đúng thứ tự.",
      "thongBaoSai":
          "Chưa đúng rồi, sau quả nho là quả gì trong chuỗi 4 quả nhỉ?"
    },
    {
      "tieuDe": "Quy luật tam giác màu so le",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🔴 🔴 🔵 🔴 🔴 🔵 🔴  ❓",
      "docCauHoi":
          "Hai chấm đỏ, một chấm xanh. Lại hai chấm đỏ, một chấm xanh. Rồi đến một chấm đỏ. Tiếp theo là gì?",
      "dapAnDung": "🔴",
      "tenDapAn": "🔴 Đỏ",
      "danhSachLuaChon": ["🔴", "🔵", "🟡"],
      "thongBaoDung": "Quá chuẩn! Phải đủ hai chấm đỏ rồi mới tới chấm xanh.",
      "thongBaoSai": "Hãy đếm kỹ nhé, cần có đủ 2 chấm đỏ đi liền nhau!"
    },
    {
      "tieuDe": "Quy luật thời tiết 4 mùa",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "☀️ ☁️ 🌧️ ❄️ ☀️ ☁️ 🌧️  ❓",
      "docCauHoi":
          "Nắng, mây, mưa, tuyết. Rồi lại nắng, mây, mưa. Tiếp theo là thời tiết gì?",
      "dapAnDung": "❄️",
      "tenDapAn": "❄️ Tuyết rơi",
      "danhSachLuaChon": ["❄️", "☀️", "🌧️"],
      "thongBaoDung": "Đúng rồi! Chuỗi 4 mùa: Nắng - Mây - Mưa - Tuyết.",
      "thongBaoSai": "Sai rồi, sau trận mưa sẽ đến thời tiết gì nào?"
    },
    {
      "tieuDe": "Quy luật biểu cảm cảm xúc",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "😀 😮 😡 😴 😀 😮  ❓",
      "docCauHoi":
          "Cười, ngạc nhiên, tức giận, ngủ gật. Lại đến cười, ngạc nhiên. Tiếp theo là mặt gì?",
      "dapAnDung": "😡",
      "tenDapAn": "😡 Tức giận",
      "danhSachLuaChon": ["😡", "😴", "😀"],
      "thongBaoDung": "Chính xác! Vòng lặp gồm 4 khuôn mặt cảm xúc.",
      "thongBaoSai": "Chưa đúng, sau khuôn mặt ngạc nhiên là khuôn mặt nào?"
    },
    {
      "tieuDe": "Quy luật sinh vật biển 4 loài",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐟 🐙 🦀 🐬 🐟 🐙  ❓",
      "docCauHoi":
          "Cá, bạch tuộc, cua, cá heo. Lại đến cá, bạch tuộc. Tiếp theo là con gì dưới biển?",
      "dapAnDung": "🦀",
      "tenDapAn": "🦀 Con cua",
      "danhSachLuaChon": ["🦀", "🐬", "🐟"],
      "thongBaoDung": "Xuất sắc! Chuỗi đại dương gồm 4 bạn nhỏ nối đuôi nhau.",
      "thongBaoSai": "Chưa đúng, bạn nào bò sau bạn bạch tuộc nhỉ?"
    },
    {
      "tieuDe": "Quy luật đồ ăn ngọt",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍦 🍦 🍩 🎂 🍦 🍦 🍩  ❓",
      "docCauHoi":
          "Hai cây kem, một bánh donut, một bánh sinh nhật. Lại đến hai cây kem, một donut. Tiếp theo là món gì?",
      "dapAnDung": "🎂",
      "tenDapAn": "🎂 Bánh sinh nhật",
      "danhSachLuaChon": ["🎂", "🍦", "🍩"],
      "thongBaoDung": "Giỏi lắm! Sau bánh donut là bánh sinh nhật.",
      "thongBaoSai": "Thử lại nhé, quan sát xem món gì đứng sau bánh donut!"
    },
    {
      "tieuDe": "Quy luật loài hoa 4 sắc",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🌸 🌺 🌻 🌹 🌸 🌺 🌻  ❓",
      "docCauHoi":
          "Hoa đào, hoa râm bụt, hoa hướng dương, hoa hồng. Lại đến hoa đào, râm bụt, hướng dương. Tiếp theo là hoa gì?",
      "dapAnDung": "🌹",
      "tenDapAn": "🌹 Hoa hồng",
      "danhSachLuaChon": ["🌹", "🌸", "🌺"],
      "thongBaoDung": "Đúng rồi! Hoa hồng là bông hoa thứ 4 trong chuỗi.",
      "thongBaoSai":
          "Sai rồi, bông hoa nào đứng cuối cùng trong vườn hoa 4 màu nhỉ?"
    },
    {
      "tieuDe": "Quy luật vũ trụ bao la",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🚀 👨‍🚀 🌍 🌙 🚀 👨‍🚀  ❓",
      "docCauHoi":
          "Tên lửa, phi hành gia, Trái Đất, Mặt Trăng. Lại đến tên lửa, phi hành gia. Tiếp theo là gì?",
      "dapAnDung": "🌍",
      "tenDapAn": "🌍 Trái Đất",
      "danhSachLuaChon": ["🌍", "🌙", "🚀"],
      "thongBaoDung": "Chính xác! Phi hành gia sẽ bay đến Trái Đất tiếp theo.",
      "thongBaoSai": "Chưa đúng, chú phi hành gia đang hướng về hành tinh nào?"
    },
    {
      "tieuDe": "Quy luật thể thao năng động",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "⚽ ⚽ 🏀 🏀 🏈 ⚽ ⚽ 🏀  ❓",
      "docCauHoi":
          "Hai bóng đá, hai bóng rổ, một bóng bầu dục. Lại hai bóng đá, một bóng rổ. Tiếp theo là quả bóng gì?",
      "dapAnDung": "🏀",
      "tenDapAn": "🏀 Bóng rổ",
      "danhSachLuaChon": ["🏀", "⚽", "🏈"],
      "thongBaoDung": "Xuất sắc! Cần có đủ cặp 2 quả bóng rổ.",
      "thongBaoSai": "Chưa đúng rồi, bóng rổ đi theo từng cặp 2 quả bé nhé!"
    },
    {
      "tieuDe": "Quy luật hình khối",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🔵 🟥 🔺 🔵 🟥 🔺  ❓",
      "docCauHoi": "Giải mã quy luật lặp: Hình nào sẽ xuất hiện tiếp theo?",
      "dapAnDung": "🔵",
      "tenDapAn": "🔵 Tròn",
      "danhSachLuaChon": ["🔵", "🟥", "🔺"],
      "thongBaoDung": "Đúng rồi! Chuỗi lặp lại Tròn - Vuông - Tam Giác.",
      "thongBaoSai": "Sai rồi, hãy quan sát vòng lặp 3 hình nhé!",
    },
    {
      "tieuDe": "Quy luật 4 hình khối cơ bản",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🔵 🟥 🔺 ⭐ 🔵 🟥 🔺  ❓",
      "docCauHoi":
          "Tròn, vuông, tam giác, ngôi sao. Rồi lại đến tròn, vuông, tam giác. Tiếp theo là hình gì bé nhỉ?",
      "dapAnDung": "⭐",
      "tenDapAn": "⭐ Ngôi sao",
      "danhSachLuaChon": ["⭐", "🔵", "🟥"],
      "thongBaoDung":
          "Chính xác! Chuỗi lặp lại 4 hình: Tròn - Vuông - Tam giác - Ngôi sao.",
      "thongBaoSai":
          "Chưa đúng rồi, bé quan sát kỹ vị trí hình đứng sau tam giác nhé!"
    },
    {
      "tieuDe": "Quy luật cặp đôi hình khối",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🟦 🟦 🔴 🔴 🟦 🟦  ❓",
      "docCauHoi":
          "Hai hình vuông xanh, hai hình tròn đỏ, rồi lại hai hình vuông xanh. Tiếp theo là hình gì bé ơi?",
      "dapAnDung": "🔴",
      "tenDapAn": "🔴 Tròn đỏ",
      "danhSachLuaChon": ["🔴", "🟦", "🟡"],
      "thongBaoDung": "Giỏi quá! Các hình đi theo từng cặp 2 Vuông - 2 Tròn.",
      "thongBaoSai":
          "Thử lại nào, sau cặp hai hình vuông xanh sẽ đến hình gì nhỉ?"
    },
    {
      "tieuDe": "Quy luật ngôi sao kẹp giữa",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "⭐ 🔺 ⭐ 🟥 ⭐ 🔺 ⭐  ❓",
      "docCauHoi":
          "Ngôi sao, tam giác, ngôi sao, hình vuông, ngôi sao, tam giác, ngôi sao. Tiếp theo là hình gì?",
      "dapAnDung": "🟥",
      "tenDapAn": "🟥 Hình vuông",
      "danhSachLuaChon": ["🟥", "🔺", "⭐"],
      "thongBaoDung":
          "Xuất sắc! Ngôi sao luôn đứng xen kẽ giữa Tam giác và Hình vuông.",
      "thongBaoSai":
          "Chưa đúng, bé chú ý xem sau hình tam giác là đến hình gì nhé!"
    },
    {
      "tieuDe": "Quy luật 5 hình khối đa dạng",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🟣 🟧 🔺 ⭐ 🔷 🟣 🟧 🔺  ❓",
      "docCauHoi":
          "Tròn tím, vuông cam, tam giác, ngôi sao, thoi xanh. Lại đến tròn tím, vuông cam, tam giác. Hình tiếp theo là gì?",
      "dapAnDung": "⭐",
      "tenDapAn": "⭐ Ngôi sao",
      "danhSachLuaChon": ["⭐", "🔷", "🟣"],
      "thongBaoDung": "Tuyệt vời! Vòng lặp gồm 5 hình khối nối tiếp nhau.",
      "thongBaoSai":
          "Chưa chính xác, sau hình tam giác là hình gì trong bộ 5 hình nhỉ?"
    },
    {
      "tieuDe": "Quy luật hình 3D (Khối không gian)",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🧊 ⚽ 📦 🧊 ⚽  ❓",
      "docCauHoi":
          "Khối băng, quả bóng tròn, hộp quà vuông. Lại đến khối băng, quả bóng. Đố bé tiếp theo là hình gì?",
      "dapAnDung": "📦",
      "tenDapAn": "📦 Hộp quà",
      "danhSachLuaChon": ["📦", "🧊", "⚽"],
      "thongBaoDung":
          "Đúng rồi! Chuỗi lặp lại 3 khối: Lập phương - Cầu - Hộp chữ nhật.",
      "thongBaoSai": "Sai rồi, hãy chú ý xem vật thể nào đứng sau quả bóng nhé!"
    },
    {
      "tieuDe": "Quy luật nhịp điệu 2-1-2",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🟢 🟢 🟡 🔴 🔴 🟡 🟢 🟢  ❓",
      "docCauHoi":
          "Hai tròn xanh lá, một tròn vàng, hai tròn đỏ, một tròn vàng. Lại hai tròn xanh lá. Tiếp theo là màu gì?",
      "dapAnDung": "🟡",
      "tenDapAn": "🟡 Tròn vàng",
      "danhSachLuaChon": ["🟡", "🟢", "🔴"],
      "thongBaoDung":
          "Thông minh lắm! Đứng giữa các cặp tròn xanh và tròn đỏ luôn là tròn vàng.",
      "thongBaoSai":
          "Thử lại xem, hình tròn vàng đứng ở vị trí xen kẽ giữa các cặp đấy!"
    },
    {
      "tieuDe": "Quy luật hình học phức tạp",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🔺 🔲 💎 🟡 🔺 🔲  ❓",
      "docCauHoi":
          "Tam giác, ô vuông, viên kim cương, tròn vàng. Lại đến tam giác, ô vuông. Tiếp theo là hình gì?",
      "dapAnDung": "💎",
      "tenDapAn": "💎 Viên kim cương",
      "danhSachLuaChon": ["💎", "🟡", "🔺"],
      "thongBaoDung": "Chính xác! Chuỗi lặp lại 4 hình theo đúng thứ tự.",
      "thongBaoSai": "Chưa đúng, sau hình ô vuông là hình gì bé ơi?"
    },
    {
      "tieuDe": "Quy luật ba tam giác so le",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🔺 🔺 🔺 🟦 🔺 🔺 🔺  ❓",
      "docCauHoi":
          "Ba tam giác đỏ, một vuông xanh. Lại đến ba tam giác đỏ. Tiếp theo là hình gì bé nhỉ?",
      "dapAnDung": "🟦",
      "tenDapAn": "🟦 Vuông xanh",
      "danhSachLuaChon": ["🟦", "🔺", "🟡"],
      "thongBaoDung":
          "Quá chuẩn! Phải có đủ ba tam giác đỏ rồi mới tới hình vuông xanh.",
      "thongBaoSai":
          "Hãy đếm kỹ nhé, cần có đủ 3 hình tam giác đỏ đi liền nhau!"
    },
    {
      "tieuDe": "Quy luật trái tim & hình khối",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "💖 🟩 🟡 🔷 💖 🟩 🟡  ❓",
      "docCauHoi":
          "Trái tim, vuông xanh lá, tròn vàng, thoi xanh dương. Lại đến trái tim, vuông xanh lá, tròn vàng. Tiếp theo là gì?",
      "dapAnDung": "🔷",
      "tenDapAn": "🔷 Hình thoi",
      "danhSachLuaChon": ["🔷", "💖", "🟩"],
      "thongBaoDung": "Xuất sắc! Hình thoi là hình đứng thứ 4 trong chuỗi.",
      "thongBaoSai": "Sai rồi, hình nào đứng sau hình tròn vàng bé nhỉ?"
    },
    {
      "tieuDe": "Quy luật hình tam giác xoay hướng",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🔺 🔻 🔺 🔻 🔺  ❓",
      "docCauHoi":
          "Tam giác chỉ lên, tam giác chỉ xuống, tam giác chỉ lên, tam giác chỉ xuống. Tiếp theo là tam giác nào?",
      "dapAnDung": "🔻",
      "tenDapAn": "🔻 Tam giác chỉ xuống",
      "danhSachLuaChon": ["🔻", "🔺", "🟦"],
      "thongBaoDung": "Đúng rồi! Chuỗi lặp so le: Chỉ lên -> Chỉ xuống.",
      "thongBaoSai": "Chưa đúng, hình phía trước là tam giác chỉ lên rồi bé ơi!"
    },
    {
      "tieuDe": "Quy luật hoa quả",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍎 🍌 🍊 🍎 🍌 🍊  ❓",
      "docCauHoi": "Giải mã quy luật lặp: Quả nào sẽ xuất hiện tiếp theo?",
      "dapAnDung": "🍎",
      "tenDapAn": "🍎 Táo",
      "danhSachLuaChon": ["🍎", "🍊", "🍌"],
      "thongBaoDung": "Chính xác! Chuỗi lặp lại Táo - Chuối - Cam.",
      "thongBaoSai": "Sai rồi, hãy chú ý vòng lặp bắt đầu bằng quả Táo nhé!",
    },
    {
      "tieuDe": "Quy luật 4 loại quả nhiệt đới",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍎 🍌 🍊 🍉 🍎 🍌 🍊  ❓",
      "docCauHoi":
          "Táo, chuối, cam, dưa hấu. Lại đến táo, chuối, cam. Đố bé quả tiếp theo là gì?",
      "dapAnDung": "🍉",
      "tenDapAn": "🍉 Dưa hấu",
      "danhSachLuaChon": ["🍉", "🍎", "🍌"],
      "thongBaoDung":
          "Chính xác! Chuỗi lặp lại 4 loại quả: Táo - Chuối - Cam - Dưa hấu.",
      "thongBaoSai":
          "Chưa đúng rồi, bé nhìn lại vị trí quả đứng sau quả cam nhé!"
    },
    {
      "tieuDe": "Quy luật cặp đôi hoa quả",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍓 🍓 🍇 🍇 🍓 🍓  ❓",
      "docCauHoi":
          "Hai quả dâu tây, hai chùm nho, rồi lại hai quả dâu tây. Tiếp theo là quả gì bé ơi?",
      "dapAnDung": "🍇",
      "tenDapAn": "🍇 Chùm nho",
      "danhSachLuaChon": ["🍇", "🍓", "🍍"],
      "thongBaoDung": "Giỏi quá! Các loại quả đi theo từng cặp 2 Dâu - 2 Nho.",
      "thongBaoSai":
          "Thử lại nào, sau cặp hai quả dâu tây sẽ đến cặp quả gì nhỉ?"
    },
    {
      "tieuDe": "Quy luật Quả Táo kẹp giữa",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍎 🥑 🍎 🥭 🍎 🥑 🍎  ❓",
      "docCauHoi": "Táo, bơ, táo, xoài, táo, bơ, táo. Tiếp theo sẽ là quả gì?",
      "dapAnDung": "🥭",
      "tenDapAn": "🥭 Quả xoài",
      "danhSachLuaChon": ["🥭", "🥑", "🍎"],
      "thongBaoDung":
          "Xuất sắc! Quả táo luôn đứng xen kẽ giữa quả bơ và quả xoài.",
      "thongBaoSai":
          "Chưa đúng, bé chú ý xem sau quả bơ và táo là đến quả gì nhé!"
    },
    {
      "tieuDe": "Quy luật 5 loại quả mọng",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍒 🫐 🥝 🍑 🍐 🍒 🫐 🥝  ❓",
      "docCauHoi":
          "Anh đào, việt quất, ki-wi, đào, lê. Lại đến anh đào, việt quất, ki-wi. Tiếp theo là quả gì?",
      "dapAnDung": "🍑",
      "tenDapAn": "🍑 Quả đào",
      "danhSachLuaChon": ["🍑", "🍐", "🍒"],
      "thongBaoDung": "Tuyệt vời! Vòng lặp gồm 5 loại quả nối tiếp nhau.",
      "thongBaoSai":
          "Chưa chính xác, quả nào đứng sau quả ki-wi trong chuỗi 5 quả nhỉ?"
    },
    {
      "tieuDe": "Quy luật hoa quả nhịp điệu 2-1-2",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍋 🍋 🍍 🥥 🥥 🍍 🍋 🍋  ❓",
      "docCauHoi":
          "Hai quả chanh, một quả dứa, hai quả dừa, một quả dứa. Lại đến hai quả chanh. Tiếp theo là quả gì?",
      "dapAnDung": "🍍",
      "tenDapAn": "🍍 Quả dứa",
      "danhSachLuaChon": ["🍍", "🍋", "🥥"],
      "thongBaoDung":
          "Thông minh lắm! Đứng giữa các cặp chanh và dừa luôn là quả dứa.",
      "thongBaoSai":
          "Thử lại xem, quả dứa đứng ở vị trí xen kẽ giữa các cặp đấy!"
    },
    {
      "tieuDe": "Quy luật hoa quả mọng nước",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍐 🫐 🍓 🍋 🍐 🫐  ❓",
      "docCauHoi":
          "Lê, việt quất, dâu tây, chanh. Lại đến lê, việt quất. Tiếp theo là quả gì bé nhỉ?",
      "dapAnDung": "🍓",
      "tenDapAn": "🍓 Dâu tây",
      "danhSachLuaChon": ["🍓", "🍋", "🍐"],
      "thongBaoDung": "Chính xác! Chuỗi lặp lại 4 loại quả theo đúng thứ tự.",
      "thongBaoSai": "Chưa đúng, quả nào đứng sau việt quất bé ơi?"
    },
    {
      "tieuDe": "Quy luật Ba quả chuối so le",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍌 🍌 🍌 🍎 🍌 🍌 🍌  ❓",
      "docCauHoi":
          "Ba quả chuối, một quả táo. Lại đến ba quả chuối. Tiếp theo là quả gì bé ơi?",
      "dapAnDung": "🍎",
      "tenDapAn": "🍎 Quả táo",
      "danhSachLuaChon": ["🍎", "🍌", "🍊"],
      "thongBaoDung": "Quá chuẩn! Phải có đủ ba quả chuối rồi mới tới quả táo.",
      "thongBaoSai": "Hãy đếm kỹ nhé, cần có đủ 3 quả chuối đi liền nhau đấy!"
    },
    {
      "tieuDe": "Quy luật hoa quả mùa hè",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🥥 🍈 🍉 🍍 🥥 🍈 🍉  ❓",
      "docCauHoi":
          "Dừa, dưa lưới, dưa hấu, dứa. Lại đến dừa, dưa lưới, dưa hấu. Tiếp theo là quả gì?",
      "dapAnDung": "🍍",
      "tenDapAn": "🍍 Quả dứa",
      "danhSachLuaChon": ["🍍", "🥥", "🍈"],
      "thongBaoDung": "Xuất sắc! Quả dứa là quả đứng thứ 4 trong chuỗi.",
      "thongBaoSai": "Sai rồi, quả nào đứng sau quả dưa hấu bé nhỉ?"
    },
    {
      "tieuDe": "Quy luật sinh tố hỗn hợp",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🥑 🍌 🥛 🥑 🍌  ❓",
      "docCauHoi":
          "Bơ, chuối, ly sữa. Lại đến bơ, chuối. Đố bé tiếp theo sẽ là gì để làm món sinh tố?",
      "dapAnDung": "🥛",
      "tenDapAn": "🥛 Ly sữa",
      "danhSachLuaChon": ["🥛", "🥑", "🍌"],
      "thongBaoDung": "Đúng rồi! Chuỗi lặp lại: Bơ - Chuối - Ly sữa.",
      "thongBaoSai":
          "Chưa đúng, món gì đứng sau quả chuối trong công thức sinh tố nhỉ?"
    },
    {
      "tieuDe": "Quy luật quả chua & ngọt",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🍋 🍎 🍋 🍎 🍋  ❓",
      "docCauHoi":
          "Chanh chua, táo ngọt, chanh chua, táo ngọt, chanh chua. Tiếp theo là quả gì?",
      "dapAnDung": "🍎",
      "tenDapAn": "🍎 Táo ngọt",
      "danhSachLuaChon": ["🍎", "🍋", "🍌"],
      "thongBaoDung": "Đúng rồi! Chuỗi lặp so le giữa Chanh chua và Táo ngọt.",
      "thongBaoSai": "Chưa đúng, quả đứng trước là chanh chua rồi bé ơi!"
    },
    {
      "tieuDe": "Quy luật động vật",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐱 🐶 🐰 🐱 🐶 🐰  ❓",
      "docCauHoi": "Giải mã quy luật lặp: Con vật nào sẽ xuất hiện tiếp theo?",
      "dapAnDung": "🐱",
      "tenDapAn": "🐱 Mèo",
      "danhSachLuaChon": ["🐱", "🐶", "🐰"],
      "thongBaoDung": "Tuyệt vời! Chuỗi lặp lại Mèo - Chó - Thỏ.",
      "thongBaoSai": "Chưa đúng, sau Thỏ sẽ quay lại con vật đầu tiên cơ mà!",
    },
    {
      "tieuDe": "Quy luật 4 bạn thú cưng",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐱 🐶 🐰 🐹 🐱 🐶 🐰  ❓",
      "docCauHoi":
          "Mèo, chó, thỏ, chuột hamsters. Lại đến mèo, chó, thỏ. Đố bé bạn nào xuất hiện tiếp theo?",
      "dapAnDung": "🐹",
      "tenDapAn": "🐹 Chuột hamster",
      "danhSachLuaChon": ["🐹", "🐱", "🐶"],
      "thongBaoDung":
          "Chính xác! Chuỗi lặp lại 4 bạn: Mèo - Chó - Thỏ - Hamster.",
      "thongBaoSai":
          "Chưa đúng rồi, bé nhìn lại vị trí bạn đứng sau bạn thỏ nhé!"
    },
    {
      "tieuDe": "Quy luật cặp đôi động vật",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐮 🐮 🐷 🐷 🐮 🐮  ❓",
      "docCauHoi":
          "Hai bạn bò sữa, hai bạn heo hồng, rồi lại hai bạn bò sữa. Tiếp theo là bạn nào bé ơi?",
      "dapAnDung": "🐷",
      "tenDapAn": "🐷 Báo hồng (Heo)",
      "danhSachLuaChon": ["🐷", "🐮", "🐔"],
      "thongBaoDung": "Giỏi quá! Các bạn đi theo từng cặp 2 Bò - 2 Heo.",
      "thongBaoSai":
          "Thử lại nào, sau cặp hai bạn bò sữa sẽ đến cặp bạn nào nhỉ?"
    },
    {
      "tieuDe": "Quy luật Bạn Mèo kẹp giữa",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐱 🐻 🐱 🐼 🐱 🐻 🐱  ❓",
      "docCauHoi":
          "Mèo, gấu nâu, mèo, gấu trúc, mèo, gấu nâu, mèo. Tiếp theo sẽ là bạn gấu nào?",
      "dapAnDung": "🐼",
      "tenDapAn": "🐼 Gấu trúc",
      "danhSachLuaChon": ["🐼", "🐻", "🐱"],
      "thongBaoDung":
          "Xuất sắc! Bạn mèo luôn đứng xen kẽ giữa gấu nâu và gấu trúc.",
      "thongBaoSai":
          "Chưa đúng, bé chú ý xem sau gấu nâu và mèo là đến gấu nào nhé!"
    },
    {
      "tieuDe": "Quy luật 5 bạn động vật hoang dã",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🦁 🐯 🐘 🦒 🐵 🦁 🐯 🐘  ❓",
      "docCauHoi":
          "Sư tử, hổ, voi, hươu cao cổ, khỉ. Lại đến sư tử, hổ, voi. Bạn tiếp theo là ai?",
      "dapAnDung": "🦒",
      "tenDapAn": "🦒 Hươu cao cổ",
      "danhSachLuaChon": ["🦒", "🐵", "🦁"],
      "thongBaoDung": "Tuyệt vời! Vòng lặp gồm 5 bạn động vật hoang dã.",
      "thongBaoSai":
          "Chưa chính xác, bạn nào đứng sau bạn voi trong chuỗi 5 bạn nhỉ?"
    },
    {
      "tieuDe": "Quy luật động vật nhịp điệu 2-1-2",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐸 🐸 🐥 🐝 🐝 🐥 🐸 🐸  ❓",
      "docCauHoi":
          "Hai bạn ếch, một bạn gà con, hai bạn ong, một bạn gà con. Lại đến hai bạn ếch. Tiếp theo là bạn nào?",
      "dapAnDung": "🐥",
      "tenDapAn": "🐥 Gà con",
      "danhSachLuaChon": ["🐥", "🐸", "🐝"],
      "thongBaoDung":
          "Thông minh lắm! Đứng giữa các cặp ếch và ong luôn là bạn gà con.",
      "thongBaoSai":
          "Thử lại xem, bạn gà con đứng ở vị trí xen kẽ giữa các cặp đấy!"
    },
    {
      "tieuDe": "Quy luật 4 loài chim",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🦅 🦉 🦆 🦜 🦅 🦉  ❓",
      "docCauHoi":
          "Đại bàng, cú mèo, vịt trời, vẹt. Lại đến đại bàng, cú mèo. Bạn tiếp theo là ai bé nhỉ?",
      "dapAnDung": "🦆",
      "tenDapAn": "🦆 Vịt trời",
      "danhSachLuaChon": ["🦆", "🦜", "🦅"],
      "thongBaoDung": "Chính xác! Chuỗi lặp lại 4 loài chim theo đúng thứ tự.",
      "thongBaoSai": "Chưa đúng, bạn nào đứng sau bạn cú mèo bé ơi?"
    },
    {
      "tieuDe": "Quy luật Ba chú thỏ so le",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐰 🐰 🐰 🦊 🐰 🐰 🐰  ❓",
      "docCauHoi":
          "Ba chú thỏ, một chú cáo. Lại đến ba chú thỏ. Tiếp theo là bạn nào bé ơi?",
      "dapAnDung": "🦊",
      "tenDapAn": "🦊 Chú cáo",
      "danhSachLuaChon": ["🦊", "🐰", "🐱"],
      "thongBaoDung": "Quá chuẩn! Phải có đủ ba chú thỏ rồi mới tới chú cáo.",
      "thongBaoSai": "Hãy đếm kỹ nhé, cần có đủ 3 chú thỏ đi liền nhau đấy!"
    },
    {
      "tieuDe": "Quy luật khu rừng vui vẻ",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐿️ 🦔 🦝 🦌 🐿️ 🦔 🦝  ❓",
      "docCauHoi":
          "Sóc, nhím, gấu trúc Mỹ, hươu. Lại đến sóc, nhím, gấu trúc Mỹ. Bạn tiếp theo là ai?",
      "dapAnDung": "🦌",
      "tenDapAn": "🦌 Bạn hươu",
      "danhSachLuaChon": ["🦌", "🐿️", "🦔"],
      "thongBaoDung": "Xuất sắc! Bạn hươu là bạn đứng thứ 4 trong chuỗi.",
      "thongBaoSai": "Sai rồi, bạn nào đứng sau gấu trúc Mỹ bé nhỉ?"
    },
    {
      "tieuDe": "Quy luật sinh vật biển",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐬 🐳 🦈 🐬 🐳  ❓",
      "docCauHoi":
          "Cá heo, cá voi, cá mập. Lại đến cá heo, cá voi. Đố bé tiếp theo sẽ là bạn cá nào?",
      "dapAnDung": "🦈",
      "tenDapAn": "🦈 Cá mập",
      "danhSachLuaChon": ["🦈", "🐬", "🐳"],
      "thongBaoDung": "Đúng rồi! Chuỗi lặp lại: Cá heo - Cá voi - Cá mập.",
      "thongBaoSai":
          "Chưa đúng, bạn cá nào đứng sau cá voi trong chuỗi đại dương nhỉ?"
    },
    {
      "tieuDe": "Quy luật tiếng kêu so le",
      "loaiQuyLuat": "CHUOI_DON",
      "chuoi": "🐔 🦆 🐔 🦆 🐔  ❓",
      "docCauHoi":
          "Gà trống, vịt, gà trống, vịt, gà trống. Tiếp theo là bạn nào?",
      "dapAnDung": "🦆",
      "tenDapAn": "🦆 Bạn vịt",
      "danhSachLuaChon": ["🦆", "🐔", "🐷"],
      "thongBaoDung": "Đúng rồi! Chuỗi lặp so le giữa Bạn Gà và Bạn Vịt.",
      "thongBaoSai": "Chưa đúng, bạn đứng trước là gà trống rồi bé ơi!"
    },
    // 2. DẠNG NÂNG CAO MỚI TÍCH HỢP
    {
      "tieuDe": "Quy luật xoay hướng",
      "loaiQuyLuat": "XOAY_HUONG",
      "chuoi": "⬆️ ➡️ ⬇️  ❓",
      "docCauHoi":
          "Mũi tên đang xoay tròn: Lên, Phải, Xuống. Đố bé tiếp theo mũi tên chỉ hướng nào?",
      "dapAnDung": "⬅️",
      "tenDapAn": "⬅️ Trái",
      "danhSachLuaChon": ["⬅️", "⬆️", "➡️"],
      "thongBaoDung": "Giỏi quá! Mũi tên xoay tròn theo chiều kim đồng hồ.",
      "thongBaoSai":
          "Chưa đúng rồi, bé hãy hình dung kim đồng hồ đang xoay nhé!",
    },
    {
      "tieuDe": "Quy luật vòng đời",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🥚 🐣 🐥  ❓",
      "docCauHoi":
          "Quả trứng nứt vỏ ra gà con. Gà con lớn lên thành con gì bé nhỉ?",
      "dapAnDung": "🐓",
      "tenDapAn": "🐓 Gà trống",
      "danhSachLuaChon": ["🐓", "🦆", "🕊️"],
      "thongBaoDung": "Xuất sắc! Gà con lớn lên sẽ thành gà trống.",
      "thongBaoSai":
          "Thử lại nhé, gà con sẽ lớn lên thành con gà trưởng thành đấy!",
    },
    {
      "tieuDe": "Vòng đời của Bươm Bướm",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🥚 🐛 📦  ❓",
      "docCauHoi":
          "Trứng nở thành sâu bướm, sâu bướm làm kén nhộng. Đố bé từ trong kén biến đổi thành con gì?",
      "dapAnDung": "🦋",
      "tenDapAn": "🦋 Bướm xinh",
      "danhSachLuaChon": ["🦋", "🐝", "🐞"],
      "thongBaoDung": "Chính xác! Nhộng xé kén hóa thành chú bướm rực rỡ.",
      "thongBaoSai":
          "Chưa đúng, từ trong kén sẽ chui ra một chú bướm xinh đẹp đấy!"
    },
    {
      "tieuDe": "Vòng đời của Chú Ếch",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🥚 🫧 🐟  ❓",
      "docCauHoi":
          "Trứng ếch dưới nước nở thành nòng nọc con. Nòng nọc rụng đuôi mọc chân biến thành con gì?",
      "dapAnDung": "🐸",
      "tenDapAn": "🐸 Chú ếch",
      "danhSachLuaChon": ["🐸", "🐢", "🐊"],
      "thongBaoDung": "Xuất sắc! Nòng nọc lớn lên sẽ biến thành chú ếch xanh.",
      "thongBaoSai":
          "Thử lại nhé, nòng nọc dưới nước lớn lên sẽ nhảy lên bờ làm chú ếch đấy!"
    },
    {
      "tieuDe": "Vòng đời của Cây Táo",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🫘 🌱 🌳 🌸  ❓",
      "docCauHoi":
          "Hạt gieo xuống đất nảy mầm thành cây, cây ra hoa. Sau khi hoa tàn sẽ kết thành gì?",
      "dapAnDung": "🍎",
      "tenDapAn": "🍎 Quả táo",
      "danhSachLuaChon": ["🍎", "🍊", "🍌"],
      "thongBaoDung": "Giỏi quá! Hoa tàn sẽ đậu thành những quả táo thơm ngon.",
      "thongBaoSai":
          "Chưa chính xác, hoa trên cây tàn đi sẽ kết thành quả ngọt bé nhé!"
    },
    {
      "tieuDe": "Vòng đời của Nước",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🌊 ☀️ ☁️  ❓",
      "docCauHoi":
          "Nước biển gặp nắng bốc hơi thành mây. Mây ngưng tụ ngợp tích tụ lại tạo thành hiện tượng gì?",
      "dapAnDung": "🌧️",
      "tenDapAn": "🌧️ Cơn mưa",
      "danhSachLuaChon": ["🌧️", "❄️", "🌪️"],
      "thongBaoDung": "Đúng rồi! Mây ngưng tụ lại rơi xuống thành mưa.",
      "thongBaoSai": "Thử lại nào, mây dày đặc trên trời sẽ gây ra mưa đấy!"
    },
    {
      "tieuDe": "Vòng đời của Chú Muỗi",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🥚 🪱 🫙  ❓",
      "docCauHoi":
          "Muỗi đẻ trứng đọng trong nước nở thành bọ gậy (lăng quăng), rồi hóa nhộng. Cuối cùng biến thành con gì?",
      "dapAnDung": "🦟",
      "tenDapAn": "🦟 Con muỗi",
      "danhSachLuaChon": ["🦟", "🪰", "🐝"],
      "thongBaoDung":
          "Chính xác! Nhộng muỗi trong nước sẽ bay lên thành con muỗi.",
      "thongBaoSai":
          "Chưa đúng, lăng quăng lớn lên sẽ thành con muỗi bay vo ve!"
    },
    {
      "tieuDe": "Vòng đời của Hoa Hướng Dương",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🌻 🍂 🫘 🌱  ❓",
      "docCauHoi":
          "Hoa hướng dương héo rơi hạt xuống đất. Hạt nảy mầm nhô lên thành gì bé nhỉ?",
      "dapAnDung": "🌻",
      "tenDapAn": "🌻 Hoa hướng dương",
      "danhSachLuaChon": ["🌻", "🌹", "🌷"],
      "thongBaoDung":
          "Tuyệt vời! Mầm cây lớn lên tiếp tục nở ra hoa hướng dương rực rỡ.",
      "thongBaoSai":
          "Chưa đúng, hạt hướng dương nảy mầm sẽ lớn thành bông hoa hướng dương mới!"
    },
    {
      "tieuDe": "Vòng đời của Bạn Ong",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🥚 🐛 🪺  ❓",
      "docCauHoi":
          "Ong chúa đẻ trứng trong tổ, trứng nở thành ấu trùng rồi hóa nhộng. Nhộng chui ra thành bạn gì?",
      "dapAnDung": "🐝",
      "tenDapAn": "🐝 Chú ong",
      "danhSachLuaChon": ["🐝", "🦋", "🐞"],
      "thongBaoDung":
          "Đúng rồi! Nhộng hoàn thiện biến thành chú ong chăm chỉ đi hút mật.",
      "thongBaoSai": "Sai rồi, chú ong nhỏ chui ra từ tổ ong bé nhé!"
    },
    {
      "tieuDe": "Vòng đời của Cây Lúa",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🌾 🌾 🍚  ❓",
      "docCauHoi":
          "Hạt giống mầm thành cây lúa chín vàng, mang xay xát thành gạo. Gạo nấu chín thành món gì ăn hàng ngày?",
      "dapAnDung": "🥣",
      "tenDapAn": "🥣 Bát cơm",
      "danhSachLuaChon": ["🥣", "🍞", "🎂"],
      "thongBaoDung": "Thông minh lắm! Gạo nấu chín thành bát cơm dẻo ngon.",
      "thongBaoSai":
          "Chưa chính xác, hạt gạo trắng ngần đem nấu lên sẽ thành bát cơm đấy!"
    },
    {
      "tieuDe": "Vòng đời của Rùa Biển",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🐢 🥚 🐣  ❓",
      "docCauHoi":
          "Rùa mẹ đẻ trứng trên bãi cát, trứng nở ra rùa con. Rùa con bò xuống biển lớn lên thành con gì?",
      "dapAnDung": "🐢",
      "tenDapAn": "🐢 Rùa biển to",
      "danhSachLuaChon": ["🐢", "🐊", "🦀"],
      "thongBaoDung":
          "Quá chuẩn! Rùa con tự bơi ra đại dương lớn lên thành rùa trưởng thành.",
      "thongBaoSai":
          "Thử lại nhé, rùa con lớn lên sẽ thành chú rùa biển trưởng thành!"
    },
    {
      "tieuDe": "Vòng đời của Bọ Rùa",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🥚 🐛 🍂  ❓",
      "docCauHoi":
          "Trứng bọ rùa đẻ trên lá nở thành ấu trùng, ấu trùng hóa nhộng bám trên lá. Nhộng lột xác thành con gì?",
      "dapAnDung": "🐞",
      "tenDapAn": "🐞 Bọ rùa",
      "danhSachLuaChon": ["🐞", "🪲", "🐝"],
      "thongBaoDung":
          "Xuất sắc! Lột xác xong sẽ thành chú bọ rùa cánh đỏ chấm đen xinh xắn.",
      "thongBaoSai":
          "Chưa đúng, nhộng lột xác biến thành con bọ rùa chấm đỏ đấy!"
    },
    {
      "tieuDe": "Vòng đời của Cây Dưa Hấu",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "⬛ 🌱 🌿 🟡  ❓",
      "docCauHoi":
          "Hạt dưa đen gieo xuống đất nảy mầm, bò dây leo ra hoa vàng. Hoa tàn kết thành quả gì ngọt mát?",
      "dapAnDung": "🍉",
      "tenDapAn": "🍉 Quả dưa hấu",
      "danhSachLuaChon": ["🍉", "🍈", "🍍"],
      "thongBaoDung":
          "Chính xác! Dây dưa hấu ra hoa vàng rồi đơm quả dưa hấu tròn xoe.",
      "thongBaoSai":
          "Chưa đúng rồi, hạt dưa hấu gieo trồng sẽ lớn lên cho ra quả dưa hấu!"
    },
    {
      "tieuDe": "Vòng đời của Bạn Chuồn Chuồn",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🥚 🦐 🌊  ❓",
      "docCauHoi":
          "Chuồn chuồn đẻ trứng xuống nước, nở thành ấu trùng sống dưới nước. Ấu trùng leo lên cành cây lột xác thành con gì?",
      "dapAnDung": "🚁",
      "tenDapAn": "🚁 Chuồn chuồn",
      "danhSachLuaChon": ["🚁", "🦋", "🐝"],
      "thongBaoDung":
          "Giỏi quá! Ấu trùng lột xác mọc cánh bay lên thành chuồn chuồn.",
      "thongBaoSai":
          "Chưa chính xác, từ dưới nước leo lên cành cây lột xác sẽ thành chú chuồn chuồn bay lượn!"
    },
    {
      "tieuDe": "Vòng đời của Cây Sồi",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🌰 🌱 🌳  ❓",
      "docCauHoi":
          "Hạt dẻ sồi rụng xuống đất nảy mầm lớn thành cây sồi cổ thụ. Cây sồi kết hạt cho ra gì?",
      "dapAnDung": "🌰",
      "tenDapAn": "🌰 Hạt dẻ sồi",
      "danhSachLuaChon": ["🌰", "🍎", "🥥"],
      "thongBaoDung":
          "Đúng rồi! Cây sồi trưởng thành lại tiếp tục cho ra những hạt dẻ sồi mới.",
      "thongBaoSai":
          "Sai rồi, cây sồi lớn lên lại kết hạt dẻ sồi rơi xuống đất đấy!"
    },
    {
      "tieuDe": "Vòng đời của Bạn Vịt",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🥚 🐣 🐥  ❓",
      "docCauHoi":
          "Trứng vịt nứt vỏ nở ra vịt con màu vàng. Vịt con bơi dưới nước lớn lên thành con gì?",
      "dapAnDung": "🦆",
      "tenDapAn": "🦆 Con vịt to",
      "danhSachLuaChon": ["🦆", "🐓", "🕊️"],
      "thongBaoDung":
          "Xuất sắc! Vịt con lớn lên sẽ thành con vịt trưởng thành biết bơi lội.",
      "thongBaoSai":
          "Chưa đúng, chú vịt con lớn lên sẽ thành con vịt trưởng thành!"
    },
    {
      "tieuDe": "Vòng đời của Bò Sữa",
      "loaiQuyLuat": "VONG_DOI",
      "chuoi": "🐮 🐄 🥛  ❓",
      "docCauHoi":
          "Bò mẹ sinh ra bê con. Bê con ăn cỏ lớn lên thành bò mẹ cho ra thức uống thơm ngon gì?",
      "dapAnDung": "🥛",
      "tenDapAn": "🥛 Ly sữa tươi",
      "danhSachLuaChon": ["🥛", "🧃", "☕"],
      "thongBaoDung":
          "Chính xác! Bò mẹ trưởng thành sẽ mang lại những ly sữa tươi bổ dưỡng.",
      "thongBaoSai":
          "Chưa đúng, cô bò sữa chăm chỉ sẽ vắt ra những ly sữa tươi ngon cho bé đấy!"
    },
    {
      "tieuDe": "Quy luật ma trận 2x2",
      "loaiQuyLuat": "MA_TRAN_2X2",
      "hang1": ["🔴", "🔵"],
      "hang2": ["🔵", "❓"],
      "docCauHoi":
          "Hàng trên có đỏ và xanh. Hàng dưới có xanh rồi, ô trống còn thiếu màu gì?",
      "dapAnDung": "🔴",
      "tenDapAn": "🔴 Đỏ",
      "danhSachLuaChon": ["🔴", "🔵", "🟡"],
      "thongBaoDung":
          "Thông minh lắm! Mỗi hàng và cột đều cần có đủ Đỏ và Xanh.",
      "thongBaoSai":
          "Chưa chính xác, nếu chọn Xanh thì hàng 2 sẽ bị lặp lại 2 màu Xanh!",
    },
    {
      "tieuDe": "Quy luật đối xứng",
      "loaiQuyLuat": "DOI_XUNG",
      "chuoi": "🍎 🥦 🌟 🥦  ❓",
      "docCauHoi":
          "Chuỗi soi gương qua ngôi sao kỳ diệu: Táo, súp lơ, ngôi sao, súp lơ. Tiếp theo là gì?",
      "dapAnDung": "🍎",
      "tenDapAn": "🍎 Quả táo",
      "danhSachLuaChon": ["🍎", "🥦", "🍌"],
      "thongBaoDung": "Chính xác! Chuỗi đối xứng cân bằng qua ngôi sao.",
      "thongBaoSai":
          "Chưa đúng, hãy nhìn hình quả táo đối xứng ở phía bên kia ngôi sao!",
    },
    {
      "tieuDe": "Quy luật tăng số lượng",
      "loaiQuyLuat": "SO_LUONG",
      "chuoi": "⭐ | ⭐⭐ | ⭐⭐⭐ |  ❓",
      "docCauHoi":
          "Một ngôi sao, hai ngôi sao, ba ngôi sao. Đố bé nhóm tiếp theo có mấy ngôi sao?",
      "dapAnDung": "⭐⭐⭐⭐",
      "tenDapAn": "⭐⭐⭐⭐ (4 Sao)",
      "danhSachLuaChon": ["⭐⭐⭐⭐", "⭐⭐", "⭐⭐⭐⭐⭐"],
      "thongBaoDung": "Quá chuẩn! Số lượng sao tăng dần từ 1, 2, 3 đến 4.",
      "thongBaoSai":
          "Thử lại nhé, số lượng ngôi sao đang tăng thêm 1 qua mỗi nhóm đấy!",
    },
  ];
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _khoiTaoGame();
  }
  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }
  // 2. Sửa dòng xáo trộn danh sách câu hỏi
  Future<void> _khoiTaoGame() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.5);
    danhSachCauHoiXaoTron =
    List<Map<String, dynamic>>.from(danhSachQuyLuatGoc)..shuffle();
    chiSoCauHienTai = 0;
    if (!mounted) return;
    _hienThiCauHoiMoi();
  }
  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }
  // 3. Sửa dòng xáo trộn đáp án
  void _hienThiCauHoiMoi() {
    if (!mounted) return;
    if (chiSoCauHienTai >= danhSachCauHoiXaoTron.length) {
      danhSachCauHoiXaoTron.shuffle();
      chiSoCauHienTai = 0;
    }
    var mau = danhSachCauHoiXaoTron[chiSoCauHienTai];
    Map<String, dynamic> cauHoiMoi = Map<String, dynamic>.from(mau);
    if (mau["danhSachLuaChon"] != null) {
      List<String> luaChonDaXaoTron =
          List<String>.from(mau["danhSachLuaChon"] ?? const <String>[]);
      luaChonDaXaoTron.shuffle();
      cauHoiMoi["danhSachLuaChon"] = luaChonDaXaoTron;
    }
    setState(() {
      cauHoiHienTai = cauHoiMoi;
      dangKhoaNut = false;
    });
    _noi(cauHoiMoi["docCauHoi"] ?? "");
  }
  // Xử lý chọn đáp án và ghi nhận lịch sử
  void _xuLyChon(String luaChonCuaBe, String dapAnDungThucTe, String thongBaoDung, String thongBaoSai) async {
    if (!mounted || dangKhoaNut) return;
    bool laDapAnDung = (luaChonCuaBe == dapAnDungThucTe);
    setState(() {
      dangKhoaNut = true;
      if (laDapAnDung) {
        _soCauDung++;
        soLanDienLienTiep++;
      } else {
        _soCauSai++;
        soLanDienLienTiep = 0;
      }
      String hienThiDe = cauHoiHienTai!["loaiQuyLuat"] == "MA_TRAN_2X2"
          ? "Ma trận 2x2"
          : (cauHoiHienTai!["chuoi"] ?? "");
      _lichSuLamBai.add(NhatKyQuyLuat(
        soThuTu: _lichSuLamBai.length + 1,
        tieuDe: cauHoiHienTai!["tieuDe"] ?? "Quy luật",
        deBai: hienThiDe,
        dapAnDung: dapAnDungThucTe,
        luaChonCuaBe: luaChonCuaBe,
        laDung: laDapAnDung,
      ));
    });
    if (laDapAnDung) {
      if (soLanDienLienTiep % 5 == 0) {
        _confettiController.play();
      }
      await _noi(thongBaoDung);
      await Future.delayed(const Duration(milliseconds: 3500));
      if (mounted) {
        chiSoCauHienTai++;
        _hienThiCauHoiMoi();
      }
    } else {
      await _noi(thongBaoSai);
      await Future.delayed(const Duration(milliseconds: 3500));
      if (mounted) {
        setState(() {
          dangKhoaNut = false;
        });
        _noi(cauHoiHienTai?["docCauHoi"] ?? "");
      }
    }
  }
  // Bảng hiển thị lịch sử làm bài chuẩn phong cách app học tập
  void _hienThiBangKiemTraLichSu() {
    int tongSoCau = _lichSuLamBai.length;
    double diemTichLuy = tongSoCau > 0 ? (_soCauDung / tongSoCau) * 10 : 0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assessment_rounded, color: Colors.purple, size: 26),
                  SizedBox(width: 8),
                  Text("Kết Quả Làm Bài", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6A1B9A))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _itemThongKe("Tổng câu", "$tongSoCau", Colors.blue.shade700),
                      _itemThongKe("Đúng", "$_soCauDung", Colors.green.shade700),
                      _itemThongKe("Sai", "$_soCauSai", Colors.red.shade600),
                      _itemThongKe("Điểm", "${diemTichLuy.toStringAsFixed(1)}đ", Colors.purple.shade700),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  tongSoCau == 0
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text("Bé chưa hoàn thành câu hỏi nào cả!", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lichSuLamBai.length,
                          itemBuilder: (context, index) {
                            var item = _lichSuLamBai[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: item.laDung ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.laDung ? Colors.green.shade200 : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Câu ${item.soThuTu}: ${item.tieuDe}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4E342E)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Đề: ${item.deBai} | Bé chọn: ${item.luaChonCuaBe} | Đúng: ${item.dapAnDung}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: item.laDung ? Colors.black87 : Colors.red.shade700,
                                            fontWeight: item.laDung ? FontWeight.normal : FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.laDung ? Colors.green.shade100 : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.laDung ? "Đúng ✓" : "Sai ✗",
                                      style: TextStyle(
                                        color: item.laDung ? Colors.green.shade800 : Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _itemThongKe(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (cauHoiHienTai == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5FFFA),
        body: Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent)),
      );
    }
    // 4. Sửa danh sách lựa chọn trong hàm build
    List<String> danhSachLuaChon =
        List<String>.from(
          cauHoiHienTai!["danhSachLuaChon"] ?? const <String>[],
        );
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _nutQuayLaiCam(
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Quy Luật Ẩn Phức Tạp",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _nutKiemTraCauHoi(
              onTap: () {
                _hienThiBangKiemTraLichSu();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _ngoiSaoVang(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "🔥 Chuỗi đúng liên tiếp: $soLanDienLienTiep",
                  style: const TextStyle(
                      fontSize: 1,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple),
                ),
                const SizedBox(height: 1),
                IconButton(
                  iconSize: 30,
                  color: Colors.purpleAccent,
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: () => _noi(cauHoiHienTai!["docCauHoi"]),
                ),
                const SizedBox(height: 1),
                Text(
                  (cauHoiHienTai!["tieuDe"] as String).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 1),
                Text(
                  cauHoiHienTai!["docCauHoi"] as String,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 1),
                _xayDungHienThiNoiDung(cauHoiHienTai!),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: danhSachLuaChon.map((luaChon) {
                    String dapAnDungThucTe = cauHoiHienTai!["dapAnDung"];
                    String thongBaoDung = cauHoiHienTai!["thongBaoDung"] ?? "Chính xác!";
                    String thongBaoSai = cauHoiHienTai!["thongBaoSai"] ?? "Thử lại nhé!";

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: dangKhoaNut
                          ? null
                          : () => _xuLyChon(luaChon, dapAnDungThucTe, thongBaoDung, thongBaoSai),
                      child: Text(
                        luaChon,
                        style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 35,
              gravity: 0.2,
              colors: const [
                Colors.purple,
                Colors.pink,
                Colors.orange,
                Colors.yellow,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutQuayLaiCam({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.yellow.shade700, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.grey.shade700,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _nutKiemTraCauHoi({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.purpleAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.list_alt_rounded,
              color: Colors.purple,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _ngoiSaoVang() {
    int tongSoCauDaLam = _lichSuLamBai.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 22,
          ),
          const SizedBox(width: 4),
          Text(
            "$tongSoCauDaLam",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8D6E63),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Sửa hai dòng lấy dữ liệu ma trận
  Widget _xayDungHienThiNoiDung(Map<String, dynamic> data) {
    if (data["loaiQuyLuat"] == "MA_TRAN_2X2") {
      List<dynamic> hang1 =
          data["hang1"] as List<dynamic>? ?? const <dynamic>[];

      List<dynamic> hang2 =
          data["hang2"] as List<dynamic>? ?? const <dynamic>[];

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purpleAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hang1.isNotEmpty ? hang1[0].toString() : "", style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 28),
                Text(hang1.length > 1 ? hang1[1].toString() : "", style: const TextStyle(fontSize: 32)),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(
                width: 110,
                child: Divider(
                    height: 1, thickness: 1.5, color: Colors.purpleAccent)),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hang2.isNotEmpty ? hang2[0].toString() : "", style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 28),
                Text(hang2.length > 1 ? hang2[1].toString() : "", style: const TextStyle(fontSize: 32)),
              ],
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Text(
        data["chuoi"] ?? "",
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// TRANG CÂN BẰNG TƯ DUY
class NhatKyCanBang {
  final int soThuTu;
  final String tieuDe;
  final String deBai;
  final dynamic dapAnDung;
  final dynamic luaChonCuaBe;
  final bool laDung;
  NhatKyCanBang({
    required this.soThuTu,
    required this.tieuDe,
    required this.deBai,
    required this.dapAnDung,
    required this.luaChonCuaBe,
    required this.laDung,
  });
}
class TrangCanBang extends StatefulWidget {
  const TrangCanBang({super.key});
  @override
  State<TrangCanBang> createState() => _TrangCanBangState();
}
class _TrangCanBangState extends State<TrangCanBang> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late ConfettiController _confettiController;
  int soLanDienLienTiep = 0;
  bool dangKhoaNut = false;
  String tenDangThachThuc = "";
  String deBaiHienThi = "";
  String chuoiDeDoc = "";
  String noiDungGiaiThich = "";
  dynamic dapAnDung;
  List<dynamic> danhSachLuaChon = [];
  dynamic soChonSai;
  // Quản lý lịch sử làm bài và điểm số
  final List<NhatKyCanBang> _lichSuLamBai = [];
  int _soCauDung = 0;
  int _soCauSai = 0;
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _khoiTaoGame();
  }
  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoGame() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.55);
    if (!mounted) return;
    _sinhCauHoiMoi();
  }
  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }
  void _sinhCauHoiMoi() {
    if (!mounted) return;
    int loaiDangBai = _random.nextInt(4);
    String tieuDeMoi = "";
    String deBaiMoi = "";
    String docMoi = "";
    String giaiThichMoi = "";
    dynamic dapAnMoi;
    List<dynamic> luaChonMoi = [];
    if (loaiDangBai == 0) {
      int soA = _random.nextInt(5) + 2;
      int soB = _random.nextInt(4) + 3;
      int soC = _random.nextInt(4) + 2;
      int tongPhai = soB + soC;
      int kq = tongPhai - soA;
      if (kq < 1) {
        kq = 3;
        soA = tongPhai - kq;
      }
      tieuDeMoi = "🔥 Thử Thách Cân Bằng Tổng (Dạng 1)";
      deBaiMoi = "?  +  $soA   =   $soB  +  $soC";
      docMoi =
          "Ô chấm hỏi cộng $soA bằng $soB cộng $soC. Đố bé ô chấm hỏi là mấy?";
      giaiThichMoi =
          "Vế phải $soB cộng $soC bằng $tongPhai. Vậy ô trống cộng $soA phải bằng $tongPhai, bé nhẩm xem mấy cộng $soA bằng $tongPhai nhé!";
      dapAnMoi = kq;
      Set<int> luaChonSet = {dapAnMoi};
      while (luaChonSet.length < 4) {
        int nhieu =
            dapAnMoi + (_random.nextBool() ? 1 : -1) * (_random.nextInt(3) + 1);
        if (nhieu >= 1 && nhieu <= 20)
          luaChonSet.add(nhieu);
        else
          luaChonSet.add(_random.nextInt(10) + 1);
      }
      luaChonMoi = luaChonSet.toList()..shuffle();
    } else if (loaiDangBai == 1) {
      int soA = _random.nextInt(4) + 1;
      int soB = _random.nextInt(4) + 1;
      int tongTrai = soA + soB;
      int soC = _random.nextInt(tongTrai - 1) + 1;
      int kq = tongTrai - soC;
      tieuDeMoi = "⚖️ Điền Ô Trống Vế Phải (Dạng 2)";
      deBaiMoi = "$soA  +  $soB   =   ?  +  $soC";
      docMoi =
          "$soA cộng $soB bằng ô chấm hỏi cộng $soC. Đố bé ô chấm hỏi là mấy?";
      giaiThichMoi =
          "Vế trái $soA cộng $soB bằng $tongTrai. Do hai vế bằng nhau nên vế phải cũng phải bằng $tongTrai. Bé tìm xem mấy cộng $soC bằng $tongTrai nhé!";
      dapAnMoi = kq;
      Set<int> luaChonSet = {dapAnMoi};
      while (luaChonSet.length < 4) {
        int nhieu =
            dapAnMoi + (_random.nextBool() ? 1 : -1) * (_random.nextInt(3) + 1);
        if (nhieu >= 1 && nhieu <= 20)
          luaChonSet.add(nhieu);
        else
          luaChonSet.add(_random.nextInt(10) + 1);
      }
      luaChonMoi = luaChonSet.toList()..shuffle();
    } else if (loaiDangBai == 2) {
      int soA = _random.nextInt(3) + 1;
      int hieuPhai = _random.nextInt(4) + 1;
      int soC = _random.nextInt(3) + 1;
      int soB = hieuPhai + soC;
      int kq = hieuPhai + soA;
      tieuDeMoi = "🚀 Thử Thách Cân Bằng Hiệu (Dạng 3)";
      deBaiMoi = "?  -  $soA   =   $soB  -  $soC";
      docMoi =
          "Ô chấm hỏi trừ $soA bằng $soB trừ $soC. Đố bé ô chấm hỏi là mấy?";
      giaiThichMoi =
          "Vế phải $soB trừ $soC bằng $hieuPhai. Vậy số ở ô trống trừ đi $soA cũng phải bằng $hieuPhai!";
      dapAnMoi = kq;
      Set<int> luaChonSet = {dapAnMoi};
      while (luaChonSet.length < 4) {
        int nhieu =
            dapAnMoi + (_random.nextBool() ? 1 : -1) * (_random.nextInt(3) + 1);
        if (nhieu >= 1 && nhieu <= 20)
          luaChonSet.add(nhieu);
        else
          luaChonSet.add(_random.nextInt(10) + 1);
      }
      luaChonMoi = luaChonSet.toList()..shuffle();
    } else {
      int soA = _random.nextInt(5) + 1;
      int soB = _random.nextInt(5) + 1;
      int soC = _random.nextInt(5) + 1;
      int soD = _random.nextInt(5) + 1;
      int tongTrai = soA + soB;
      int tongPhai = soC + soD;
      String dauDung = "=";
      if (tongTrai > tongPhai) {
        dauDung = ">";
      } else if (tongTrai < tongPhai) {
        dauDung = "<";
      }
      tieuDeMoi = "⭐ Thử Thách Điền Dấu (Dạng 4)";
      deBaiMoi = "($soA  +  $soB)   ?   ($soC  +  $soD)";
      docMoi =
          "So sánh tổng $soA cộng $soB với tổng $soC cộng $soD, bé điền dấu gì vào ô trống?";
      giaiThichMoi =
          "Tổng vế trái $soA cộng $soB bằng $tongTrai, còn tổng vế phải $soC cộng $soD bằng $tongPhai. Bé so sánh hai số này xem bên nào lớn hơn nhé!";
      dapAnMoi = dauDung;
      luaChonMoi = [">", "<", "="]..shuffle();
    }
    setState(() {
      tenDangThachThuc = tieuDeMoi;
      deBaiHienThi = deBaiMoi;
      chuoiDeDoc = docMoi;
      noiDungGiaiThich = giaiThichMoi;
      dapAnDung = dapAnMoi;
      danhSachLuaChon = luaChonMoi;
      dangKhoaNut = false;
      soChonSai = null;
    });
    _noi(docMoi);
  }
  void _xuLyChon(dynamic soChon) async {
    if (!mounted || dangKhoaNut) return;
    bool laDapAnDung = (soChon == dapAnDung);
    setState(() {
      dangKhoaNut = true;
      if (laDapAnDung) {
        _soCauDung++;
        soLanDienLienTiep++;
        soChonSai = null;
      } else {
        _soCauSai++;
        soLanDienLienTiep = 0;
        soChonSai = soChon;
      }
      // Ghi nhận lịch sử làm bài
      _lichSuLamBai.add(NhatKyCanBang(
        soThuTu: _lichSuLamBai.length + 1,
        tieuDe: tenDangThachThuc,
        deBai: deBaiHienThi,
        dapAnDung: dapAnDung,
        luaChonCuaBe: soChon,
        laDung: laDapAnDung,
      ));
    });
    if (laDapAnDung) {
      if (soLanDienLienTiep % 5 == 0) {
        _confettiController.play();
      }
      List<String> complimentList = [
        "Chính xác tuyệt vời!",
        "Quá đỉnh!",
        "Tuyệt vời ông mặt trời!",
        "Chuẩn không cần chỉnh!",
        "Xuất sắc quá đi!",
        "Quá thông minh!",
        "Làm tốt lắm!",
        "Không chê vào đâu được!",
        "Đúng là cao thủ!",
        "Phản xạ cực kỳ nhanh nhạy!"
      ];
      String randomCompliment =
          complimentList[_random.nextInt(complimentList.length)];
      await _noi(randomCompliment);
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        _sinhCauHoiMoi();
      }
    } else {
      await _noi("Chưa đúng rồi bé ơi! $noiDungGiaiThich");
      await Future.delayed(const Duration(milliseconds: 9000));
      if (mounted) {
        setState(() {
          dangKhoaNut = false;
        });
      }
    }
  }
  // Bảng hiển thị lịch sử làm bài
  void _hienThiBangKiemTraLichSu() {
    int tongSoCau = _lichSuLamBai.length;
    double diemTichLuy = tongSoCau > 0 ? (_soCauDung / tongSoCau) * 10 : 0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assessment_rounded, color: Colors.purple, size: 26),
                  SizedBox(width: 8),
                  Text("Kết Quả Làm Bài",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6A1B9A))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _itemThongKe(
                          "Tổng câu", "$tongSoCau", Colors.blue.shade700),
                      _itemThongKe("Đúng", "$_soCauDung", Colors.green.shade700),
                      _itemThongKe("Sai", "$_soCauSai", Colors.red.shade600),
                      _itemThongKe("Điểm",
                          "${diemTichLuy.toStringAsFixed(1)}đ", Colors.purple.shade700),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  tongSoCau == 0
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text("Bé chưa hoàn thành câu hỏi nào cả!",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lichSuLamBai.length,
                          itemBuilder: (context, index) {
                            var item = _lichSuLamBai[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: item.laDung
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.laDung
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Câu ${item.soThuTu}: ${item.tieuDe}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF4E342E)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Đề: ${item.deBai} | Bé chọn: ${item.luaChonCuaBe} | Đúng: ${item.dapAnDung}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: item.laDung
                                                ? Colors.black87
                                                : Colors.red.shade700,
                                            fontWeight: item.laDung
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.laDung
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.laDung ? "Đúng ✓" : "Sai ✗",
                                      style: TextStyle(
                                        color: item.laDung
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _itemThongKe(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
  // HÀM HIỂN THỊ TRANG NHÁP / HƯỚNG DẪN CHO BA MẸ
  void _moTrangNhapChoBaMe() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "📖 Trang Nháp & Hướng Dẫn Cho Ba Mẹ",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(thickness: 1.5),
                const SizedBox(height: 1),
                const Text(
                  "Trò chơi giúp bé rèn luyện tư duy cân bằng hai vế (Dấu bằng nghĩa là tổng giá trị hai bên phải bằng nhau). Dưới đây là phương pháp giải cho từng dạng:",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                _buildMucHuongDan("1. Dạng Cân Bằng Tổng (? + A = B + C)",
                    "• Bước 1: Tính tổng vế đầy đủ bên phải (B + C).\n• Bước 2: Lấy tổng đó trừ đi số A ở vế trái để ra ô trống (? = Tổng phải - A)."),
                _buildMucHuongDan("2. Dạng Điền Vế Phải (A + B = ? + C)",
                    "• Bước 1: Tính tổng vế đầy đủ bên trái (A + B).\n• Bước 2: Tìm số cộng với C để ra kết quả đó (? = Tổng trái - C)."),
                _buildMucHuongDan("3. Dạng Cân Bằng Hiệu (? - A = B - C)",
                    "• Bước 1: Tính kết quả vế phải (B - C).\n• Bước 2: Tìm số trừ đi A để ra kết quả vừa tính (? = Kết quả vế phải + A)."),
                _buildMucHuongDan(
                    "4. Dạng Điền Dấu So Sánh ((A + B) ? (C + D))",
                    "• Bước 1: Tính tổng vế trái (A + B).\n• Bước 2: Tính tổng vế phải (C + D).\n• Bước 3: So sánh hai tổng với nhau để điền dấu >, < hoặc =."),
                const SizedBox(height: 2),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildMucHuongDan(String tieuDe, String noiDung) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tieuDe,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            noiDung,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFA),
      // BỎ HẲN APPBAR CŨ, DÙNG CUSTOM APPBAR GỌN GÀNG BÊN TRONG BODY
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: Container(),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // HÀNG HEADER: NÚT QUAY LẠI - TIÊU ĐỀ - NÚT LỊCH SỬ & NGÔI SAO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _nutQuayLaiCam(
                        onTap: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Thử Thách Cân Bằng",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Row(
                        children: [
                          _nutKiemTraCauHoi(
                            onTap: () {
                              _hienThiBangKiemTraLichSu();
                            },
                          ),
                          const SizedBox(width: 8),
                          _ngoiSaoVang(),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  // NÚT MỞ TRANG NHÁP CHO BA MẸ
                  ElevatedButton.icon(
                    onPressed: _moTrangNhapChoBaMe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.purpleAccent, width: 1.5), // ✅ Đúng cú pháp
),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 20, color: Colors.purple),
                    label: const Text(
                      "Trang nháp / Hướng dẫn cho ba mẹ",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 1),

                  Text(
                    "🔥 Chuỗi đúng liên tiếp: $soLanDienLienTiep",
                    style: const TextStyle(
                        fontSize: 0,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  const SizedBox(height: 1),
                  IconButton(
                    iconSize: 31,
                    color: Colors.purpleAccent,
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: () => _noi(chuoiDeDoc),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tenDangThachThuc.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    chuoiDeDoc,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 1),

                  // KHUNG PHÉP TOÁN
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purpleAccent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      deBaiHienThi,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // CÁC NÚT ĐÁP ÁN GỌN GÀNG TRÊN HÀNG NGANG
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: danhSachLuaChon.map((luaChon) {
                      bool laSoVuaChonSai = (luaChon == soChonSai);
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: laSoVuaChonSai
                              ? Colors.orange.shade100
                              : Colors.purpleAccent,
                          foregroundColor: laSoVuaChonSai
                              ? Colors.orange.shade900
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: laSoVuaChonSai
                                ? BorderSide(
                                    color: Colors.orange.shade400, width: 2)
                                : BorderSide.none,
                          ),
                          elevation: 4,
                        ),
                        onPressed:
                            dangKhoaNut ? null : () => _xuLyChon(luaChon),
                        child: Text(
                          "$luaChon",
                          style: TextStyle(
                              fontSize: 22,
                              color: laSoVuaChonSai
                                  ? Colors.orange.shade900
                                  : Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 35,
              gravity: 0.2,
              colors: const [
                Colors.purple,
                Colors.pink,
                Colors.orange,
                Colors.yellow,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Nút quay lại hình tròn viền cam đồng bộ
  Widget _nutQuayLaiCam({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.yellow.shade700, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.grey.shade700,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  // Nút mở bảng lịch sử (icon cuốn sổ)
  Widget _nutKiemTraCauHoi({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.purpleAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.list_alt_rounded,
              color: Colors.purple,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  // Ngôi sao vàng góc phải kèm theo tổng số câu đã làm
  Widget _ngoiSaoVang() {
    int tongSoCauDaLam = _lichSuLamBai.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 22,
          ),
          const SizedBox(width: 4),
          Text(
            "$tongSoCauDaLam",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8D6E63),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= MODEL DỮ LIỆU CHO 2 DẠNG BÀI =================
class CauHoiGiaiMaNangCao {
  final String dong1; // Ví dụ: "🍎 + 🍎 = 8"
  final String dong2; // Ví dụ: "🍎 + ⭐ = 7"
  final String dong3; // Ví dụ: "⭐ + 🌸 = 6"
  final String hoiHinh; // Ví dụ: "🌸"
  final int dapAn; // Đáp án số cần tìm
  CauHoiGiaiMaNangCao({
    required this.dong1,
    required this.dong2,
    required this.dong3,
    required this.hoiHinh,
    required this.dapAn,
  });
}
class CauHoiTimSo {
  final String tieuDe;
  final List<String> danhSachDieuKien;
  final int dapAn;
  CauHoiTimSo({
    required this.tieuDe,
    required this.danhSachDieuKien,
    required this.dapAn,
  });
}
class NhatKyCauHoiNangCao {
  final int soThuTu;
  final String tenLoai;
  final bool laDung;
  final String cauHoi;
  final String dapAnBeChon;
  final String dapAnDung;
  NhatKyCauHoiNangCao({
    required this.soThuTu,
    required this.tenLoai,
    required this.laDung,
    required this.cauHoi,
    required this.dapAnBeChon,
    required this.dapAnDung,
  });
}
// ================= GIAO DIỆN CHÍNH =================
class TrangGiaiMaVaTimSo extends StatefulWidget {
  const TrangGiaiMaVaTimSo({super.key});
  @override
  State<TrangGiaiMaVaTimSo> createState() => _TrangGiaiMaVaTimSoState();
}
class _TrangGiaiMaVaTimSoState extends State<TrangGiaiMaVaTimSo> {
  bool _laDangGiaiMa = true;
  late final List<int> _shuffledGiaiMa = List.generate(_khoGiaiMaNangCao.length, (i) => i)..shuffle();
  late final List<int> _shuffledTimSo = List.generate(_khoTimSo.length, (i) => i)..shuffle();
  int _indexGiaiMa = 0;
  int _indexTimSo = 0;
  String _chuoiNhapBeChon = "";
  bool _dangXuLyDung = false;
  int _soLanDung = 0;
  String _thongBao = "";
  Color _mauThongBao = Colors.transparent;
  final List<NhatKyCauHoiNangCao> _lichSuLamBai = [];
  OverlayEntry? _overlayEntryHienTai;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _taoCauHoiMoi();
  }
  @override
  void dispose() {
    _ungDungGiaiPhongOverlay();
    super.dispose();
  }
  void _taoCauHoiMoi() {
    final random = Random();
    setState(() {
      _chuoiNhapBeChon = "";
      _dangXuLyDung = false;
      _laDangGiaiMa = random.nextBool();
    });
  }
  void _nhapSoHoacXoa(String kyTu) {
    if (_dangXuLyDung) return;

    setState(() {
      if (kyTu == "xoa") {
        if (_chuoiNhapBeChon.isNotEmpty) {
          _chuoiNhapBeChon = _chuoiNhapBeChon.substring(0, _chuoiNhapBeChon.length - 1);
        }
      } else {
        if (_chuoiNhapBeChon.length < 2) {
          _chuoiNhapBeChon += kyTu;
          int dapAnThucTe = _laDangGiaiMa 
              ? _khoGiaiMaNangCao[_shuffledGiaiMa[_indexGiaiMa]].dapAn 
              : _khoTimSo[_shuffledTimSo[_indexTimSo]].dapAn;
          
          if (_chuoiNhapBeChon.length == dapAnThucTe.toString().length) {
            _kiemTraKetQuaThucTe();
          }
        }
      }
    });
  }
  void _kiemTraKetQuaThucTe() {
    if (_chuoiNhapBeChon.isEmpty) return;
    int soBeChon = int.parse(_chuoiNhapBeChon);
    if (_laDangGiaiMa) {
      final cauHoi = _khoGiaiMaNangCao[_shuffledGiaiMa[_indexGiaiMa]];
      String chiTiet = "${cauHoi.dong1} | ${cauHoi.dong2} | ${cauHoi.dong3} | Hỏi ${cauHoi.hoiHinh}";
      if (soBeChon == cauHoi.dapAn) {
        _dangXuLyDung = true;
        _thongBaoDung("Giải Mã Hệ Ẩn", chiTiet, soBeChon.toString(), cauHoi.dapAn.toString());
      } else {
        _dangXuLyDung = true;
        _thongBaoSai("Giải Mã Hệ Ẩn", chiTiet, soBeChon.toString(), cauHoi.dapAn.toString());
      }
    } else {
      final cauHoi = _khoTimSo[_shuffledTimSo[_indexTimSo]];
      String chiTiet = cauHoi.danhSachDieuKien.join(" - ");
      if (soBeChon == cauHoi.dapAn) {
        _dangXuLyDung = true;
        _thongBaoDung("Tìm Số Thỏa Mãn", chiTiet, soBeChon.toString(), cauHoi.dapAn.toString());
      } else {
        _dangXuLyDung = true;
        _thongBaoSai("Tìm Số Thỏa Mãn", chiTiet, soBeChon.toString(), cauHoi.dapAn.toString());
      }
    }
  }
  void _hienThiBongBongOverlay() {
    _ungDungGiaiPhongOverlay();
    _overlayEntryHienTai = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black26,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                decoration: BoxDecoration(
                  color: _mauThongBao,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _mauThongBao.withOpacity(0.35),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_thongBao.contains('⭐') ? '⭐' : '💡', style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      _thongBao,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _thongBao.contains('⭐') ? 'Cùng thử câu tiếp theo nhé! 🎉' : 'Bé thử lại câu sau nhé! 💪',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntryHienTai!);
  }
  void _ungDungGiaiPhongOverlay() {
    _overlayEntryHienTai?.remove();
    _overlayEntryHienTai = null;
  }
  void _thongBaoDung(String loai, String chiTietCH, String chon, String dung) {
    if (!mounted) return;
    int soThuTuMoi = _lichSuLamBai.length + 1;
    _lichSuLamBai.add(NhatKyCauHoiNangCao(
      soThuTu: soThuTuMoi,
      tenLoai: loai,
      laDung: true,
      cauHoi: chiTietCH,
      dapAnBeChon: chon,
      dapAnDung: dung,
    ));
    setState(() {
      _soLanDung++;
      _thongBao = "⭐ Bé siêu quá! Đúng rồi!";
      _mauThongBao = Colors.green.shade600;
    });
    _hienThiBongBongOverlay();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _ungDungGiaiPhongOverlay();
      _chuyenCauHoiMoiTuDong();
    });
  }
  void _thongBaoSai(String loai, String chiTietCH, String chon, String dung) {
    if (!mounted) return;
    int soThuTuMoi = _lichSuLamBai.length + 1;
    _lichSuLamBai.add(NhatKyCauHoiNangCao(
      soThuTu: soThuTuMoi,
      tenLoai: loai,
      laDung: false,
      cauHoi: chiTietCH,
      dapAnBeChon: chon,
      dapAnDung: dung,
    ));
    setState(() {
      _thongBao = "Chưa đúng rồi bé ơi!";
      _mauThongBao = Colors.red.shade400;
    });
    _hienThiBongBongOverlay();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _ungDungGiaiPhongOverlay();
      _chuyenCauHoiMoiTuDong();
    });
  }
  void _chuyenCauHoiMoiTuDong() {
    setState(() {
      _chuoiNhapBeChon = "";
      _dangXuLyDung = false;
      if (_laDangDanCheoCheck()) {
        _indexGiaiMa = (_indexGiaiMa + 1) % _khoGiaiMaNangCao.length;
      } else {
        _indexTimSo = (_indexTimSo + 1) % _khoTimSo.length;
      }
      _laDangGiaiMa = Random().nextBool();
    });
  }
  bool _laDangDanCheoCheck() => _laDangGiaiMa;
  void _hienThiBangKiemTraLichSu() {
    int tongSoCau = _lichSuLamBai.length;
    int soCauDung = _lichSuLamBai.where((e) => e.laDung).length;
    int soCauSai = tongSoCau - soCauDung;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assessment_rounded, color: Colors.purple, size: 26),
                  SizedBox(width: 8),
                  Text("Kết Quả Làm Bài", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6A1B9A))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _itemThongKe("Tổng câu", "$tongSoCau", Colors.blue.shade700),
                    _itemThongKe("Đúng", "$soCauDung", Colors.green.shade700),
                    _itemThongKe("Sai", "$soCauSai", Colors.red.shade600),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                tongSoCau == 0
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text("Bé chưa hoàn thành câu hỏi nào cả!", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      )
                    : Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _lichSuLamBai.length,
                          itemBuilder: (context, index) {
                            var item = _lichSuLamBai[index];
                            return InkWell(
                              onTap: () {
                                // Bấm vào dòng nào sẽ hiện chi tiết câu hỏi đó để kiểm tra
                                _hienThiChiTietCauHoiModal(item);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: item.laDung ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: item.laDung ? Colors.green.shade200 : Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: item.laDung ? Colors.green : Colors.red,
                                            child: Text("${item.soThuTu}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 1),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.tenLoai, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4E342E))),
                                                Text("Bé chọn: ${item.dapAnBeChon} | Đúng: ${item.dapAnDung}", style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item.laDung ? Colors.green.shade100 : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.laDung ? "Đúng ✓" : "Sai ✗",
                                        style: TextStyle(
                                          color: item.laDung ? Colors.green.shade800 : Colors.red.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _hienThiChiTietCauHoiModal(NhatKyCauHoiNangCao item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Chi Tiết Câu #${item.soThuTu} (${item.tenLoai})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nội dung câu hỏi:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(item.cauHoi, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
              const SizedBox(height: 1),
              Text("Bé chọn: ${item.dapAnBeChon}", style: TextStyle(fontWeight: FontWeight.bold, color: item.laDung ? Colors.green.shade700 : Colors.red.shade700)),
              const SizedBox(height: 1),
              Text("Đáp án đúng: ${item.dapAnDung}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
  Widget _itemThongKe(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    String chuoiDung = _soLanDung.toString().padLeft(2, '0');
    final cauHoiGM = _khoGiaiMaNangCao[_shuffledGiaiMa[_indexGiaiMa]];
    final cauHoiTS = _khoTimSo[_shuffledTimSo[_indexTimSo]];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF8F4FC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _nutQuayLaiCam(onTap: () => Navigator.pop(context)),
              Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: Colors.purple, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    _laDangGiaiMa ? "🧩 Giải Mã Hệ Ẩn" : "🎯 Tìm Số Thỏa Mãn",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF6A1B9A)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _hienThiBangKiemTraLichSu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade600, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        chuoiDung,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.amber.shade900),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.amber, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: _laDangGiaiMa
                        ? _buildGiaoDienGiaiMaNangCao(cauHoiGM)
                        : _buildGiaoDienTimSo(cauHoiTS),
                  ),
                ),
                const SizedBox(height: 1),
                _buildBanPhimSoNgang(),
              ],
            ),
          ),
        ),
      ),
    );
  }
// ================= WIDGET GIỮ KHUNG NGOÀI MÀU VÀNG, BỎ KHUNG TRONG =================
Widget _buildGiaoDienGiaiMaNangCao(CauHoiGiaiMaNangCao q) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1), // Khung nền vàng bên ngoài
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFFFA000), width: 3), // Viền cam nổi bật
      boxShadow: [
        BoxShadow(
          color: Colors.amber.withOpacity(0.25), 
          blurRadius: 12, 
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Các dòng phép tính hiển thị trực tiếp trên nền vàng, không bọc khung con nữa
        Text(q.dong1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
        const SizedBox(height: 8),
        Text(q.dong2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
        const SizedBox(height: 8),
        Text(q.dong3, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
        const Divider(color: Colors.amber, thickness: 2, height: 24),
        // Dòng hỏi kèm Ô TRỐNG ĐỂ NHẬP SỐ
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hỏi  ${q.hoiHinh}  bằng bao nhiêu?",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF6A1B9A)),
            ),
            const SizedBox(width: 10),
            // Ô trống trắng có viền tím để bé bấm nhập số
            Container(
              constraints: const BoxConstraints(minWidth: 50, minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade700, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _chuoiNhapBeChon.isEmpty ? "?" : _chuoiNhapBeChon,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _chuoiNhapBeChon.isEmpty ? Colors.grey.shade400 : const Color(0xFF6A1B9A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ================= WIDGET GIAO DIỆN TÌM SỐ ĐÃ TINH CHỈNH GỌN GÀNG =================
Widget _buildGiaoDienTimSo(CauHoiTimSo q) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.amber.shade50, // Khung nền vàng ấm áp bên ngoài
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.amber.shade400, width: 3), // Viền cam vàng nổi bật
      boxShadow: [
        BoxShadow(
          color: Colors.amber.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề gợi ý tìm số
        Center(
          child: Text(
            q.tieuDe,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4E342E),
            ),
          ),
        ),
        const SizedBox(height: 1),
        // Danh sách các điều kiện hiển thị rõ ràng trên nền vàng
        ...q.danhSachDieuKien.map((dk) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
              Expanded(
                child: Text(
                  dk,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        )),
        const Divider(color: Colors.amber, thickness: 2, height: 1),
        // Dòng kết quả với ô trống nhập số
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Đó là số: ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(width: 1),
            Container(
              constraints: const BoxConstraints(minWidth: 50, minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade700, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _chuoiNhapBeChon.isEmpty ? "?" : _chuoiNhapBeChon,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _chuoiNhapBeChon.isEmpty ? Colors.grey.shade400 : const Color(0xFF6A1B9A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
  Widget _buildBanPhimSoNgang() {
    List<String> danhSachNut = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "xoa"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade200, width: 2),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: danhSachNut.map((kyTu) {
          bool laNutXoa = kyTu == "xoa";
          return SizedBox(
            width: 50,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: laNutXoa ? Colors.red.shade50 : Colors.purple.shade50,
                foregroundColor: laNutXoa ? Colors.red.shade700 : Colors.purple.shade800,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(
                  color: laNutXoa ? Colors.red.shade300 : Colors.purple.shade300,
                  width: 2,
                ),
                elevation: 2,
              ),
              onPressed: () => _nhapSoHoacXoa(kyTu),
              child: laNutXoa
                  ? const Icon(Icons.backspace_rounded, size: 20)
                  : Text(kyTu, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget _nutQuayLaiCam({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.yellow.shade700, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.yellow.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade700, size: 20),
          ),
        ),
      ),
    );
  }
  // ================= KHO 60 CÂU HỎI GIẢI MÃ NÂNG CAO (CHUẨN XÁC DÒNG CUỐI) =================
  final List<CauHoiGiaiMaNangCao> _khoGiaiMaNangCao = [
  CauHoiGiaiMaNangCao(dong1: "🍎 + 🍎 = 8", dong2: "🍎 + ⭐ = 7", dong3: "⭐ + 🌸 = 6", hoiHinh: "🌸", dapAn: 3),
  CauHoiGiaiMaNangCao(dong1: "🍦 + 🍦 = 6", dong2: "🍦 + 🍰 = 9", dong3: "🍰 + 🍬 = 12", hoiHinh: "🍬", dapAn: 6),
  CauHoiGiaiMaNangCao(dong1: "🐱 + 🐱 = 8", dong2: "🐱 + 🐟 = 12", dong3: "🐟 + 🦴 = 10", hoiHinh: "🦴", dapAn: 2),
  CauHoiGiaiMaNangCao(dong1: "⭐ + ⭐ = 10", dong2: "⭐ + 🌙 = 14", dong3: "🌙 + ☀️ = 19", hoiHinh: "☀️", dapAn: 10),
  CauHoiGiaiMaNangCao(dong1: "🚗 + 🚗 = 12", dong2: "🚗 + 🚲 = 15", dong3: "🚲 + 🛵 = 14", hoiHinh: "🛵", dapAn: 5),
  CauHoiGiaiMaNangCao(dong1: "🌳 + 🌳 = 4", dong2: "🌳 + 🍄 = 10", dong3: "🍄 + 🍃 = 15", hoiHinh: "🍃", dapAn: 7),
  CauHoiGiaiMaNangCao(dong1: "⚽ + ⚽ = 10", dong2: "⚽ + 🏀 = 13", dong3: "🏀 + 🏐 = 16", hoiHinh: "🏐", dapAn: 8),
  CauHoiGiaiMaNangCao(dong1: "🍬 + 🍬 = 14", dong2: "🍬 + 🍰 = 18", dong3: "🍰 + 🥛 = 20", hoiHinh: "🥛", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🐝 + 🐝 = 6", dong2: "🐝 + 🦋 = 11", dong3: "🦋 + 🌸 = 12", hoiHinh: "🌸", dapAn: 4),
  CauHoiGiaiMaNangCao(dong1: "🧸 + 🧸 = 16", dong2: "🧸 + 🐰 = 12", dong3: "🐰 + 🐥 = 14", hoiHinh: "🐥", dapAn: 10),
  CauHoiGiaiMaNangCao(dong1: "🦕 + 🦕 = 18", dong2: "🦕 + 🐉 = 20", dong3: "🐉 + 🦄 = 17", hoiHinh: "🦄", dapAn: 6),
  CauHoiGiaiMaNangCao(dong1: "🌵 + 🌵 = 8", dong2: "🌵 + 🌹 = 15", dong3: "🌹 + 🌷 = 18", hoiHinh: "🌷", dapAn: 7),
  CauHoiGiaiMaNangCao(dong1: "✏️ + ✏️ = 12", dong2: "✏️ + 📚 = 17", dong3: "📚 + 📖 = 20", hoiHinh: "📖", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🦀 + 🦀 = 10", dong2: "🦀 + 🦐 = 16", dong3: "🦐 + 🦑 = 22", hoiHinh: "🦑", dapAn: 13),
  CauHoiGiaiMaNangCao(dong1: "🏆 + 🏆 = 8", dong2: "🏆 + 🥇 = 13", dong3: "🥇 + 🚩 = 15", hoiHinh: "🚩", dapAn: 6),
  CauHoiGiaiMaNangCao(dong1: "🍉 + 🍉 = 14", dong2: "🍉 + 🍓 = 19", dong3: "🍓 + 🍇 = 20", hoiHinh: "🍇", dapAn: 8),
  CauHoiGiaiMaNangCao(dong1: "💎 + 💎 = 10", dong2: "💎 + 👑 = 18", dong3: "👑 + 💍 = 25", hoiHinh: "💍", dapAn: 12),
  CauHoiGiaiMaNangCao(dong1: "🚀 + 🚀 = 12", dong2: "🚀 + 🛸 = 15", dong3: "🛸 + 🪐 = 22", hoiHinh: "🪐", dapAn: 13),
  CauHoiGiaiMaNangCao(dong1: "🐦 + 🐦 = 6", dong2: "🐦 + 🐧 = 11", dong3: "🐧 + 🦜 = 17", hoiHinh: "🦜", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🐷 + 🐷 = 8", dong2: "🐷 + 🐮 = 14", dong3: "🐮 + 🐔 = 18", hoiHinh: "🐔", dapAn: 7),
  CauHoiGiaiMaNangCao(dong1: "🦁 + 🦁 = 14", dong2: "🦁 + 🐯 = 17", dong3: "🐯 + 🐵 = 16", hoiHinh: "🐵", dapAn: 6),
  CauHoiGiaiMaNangCao(dong1: "🥕 + 🥕 = 6", dong2: "🥕 + 🌽 = 12", dong3: "🌽 + 🥔 = 18", hoiHinh: "🥔", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🍄 + 🍄 = 10", dong2: "🍄 + 🍁 = 16", dong3: "🍁 + 🌰 = 20", hoiHinh: "🌰", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🕷️ + 🕷️ = 8", dong2: "🕷️ + 🐞 = 13", dong3: "🐞 + 🦗 = 16", hoiHinh: "🦗", dapAn: 7),
  CauHoiGiaiMaNangCao(dong1: "🔑 + 🔑 = 10", dong2: "🔑 + 📮 = 16", dong3: "📮 + 🔒 = 21", hoiHinh: "🔒", dapAn: 10),
  CauHoiGiaiMaNangCao(dong1: "⏰ + ⏰ = 12", dong2: "⏰ + 🛋️ = 17", dong3: "🛋️ + 🏮 = 20", hoiHinh: "🏮", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "☂️ + ☂️ = 8", dong2: "☂️ + 🌈 = 14", dong3: "🌈 + ☁️ = 18", hoiHinh: "☁️", dapAn: 7),
  CauHoiGiaiMaNangCao(dong1: "👕 + 👕 = 10", dong2: "👕 + 👖 = 15", dong3: "👖 + 👟 = 19", hoiHinh: "👟", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🌲 + 🌲 = 6", dong2: "🌲 + 🎁 = 13", dong3: "🎁 + 🎀 = 17", hoiHinh: "🎀", dapAn: 7),
  CauHoiGiaiMaNangCao(dong1: "🍞 + 🍞 = 8", dong2: "🍞 + 🌭 = 13", dong3: "🌭 + 🧀 = 18", hoiHinh: "🧀", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🐶 + 🐶 = 10", dong2: "🐶 + 🦊 = 15", dong3: "🦊 + 🐰 = 18", hoiHinh: "🐰", dapAn: 8),
  CauHoiGiaiMaNangCao(dong1: "🐼 + 🐼 = 12", dong2: "🐼 + 🐨 = 18", dong3: "🐨 + 🐵 = 20", hoiHinh: "🐵", dapAn: 8),
  CauHoiGiaiMaNangCao(dong1: "🦁 + 🦁 = 16", dong2: "🦁 + 🦓 = 19", dong3: "🦓 + 🦒 = 22", hoiHinh: "🦒", dapAn: 11),
  CauHoiGiaiMaNangCao(dong1: "🦆 + 🦆 = 8", dong2: "🦆 + 🦢 = 14", dong3: "🦢 + 🐧 = 16", hoiHinh: "🐧", dapAn: 6),
  CauHoiGiaiMaNangCao(dong1: "🐬 + 🐬 = 14", dong2: "🐬 + 🐳 = 20", dong3: "🐳 + 🦈 = 23", hoiHinh: "🦈", dapAn: 10),
  CauHoiGiaiMaNangCao(dong1: "🐢 + 🐢 = 6", dong2: "🐢 + 🐍 = 13", dong3: "🐍 + 🦎 = 18", hoiHinh: "🦎", dapAn: 8),
  CauHoiGiaiMaNangCao(dong1: "🍇 + 🍇 = 10", dong2: "🍇 + 🍈 = 17", dong3: "🍈 + 🍉 = 21", hoiHinh: "🍉", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🍊 + 🍊 = 8", dong2: "🍊 + 🍋 = 15", dong3: "🍋 + 🍌 = 18", hoiHinh: "🍌", dapAn: 7),
  CauHoiGiaiMaNangCao(dong1: "🍍 + 🍍 = 12", dong2: "🍍 + 🥭 = 18", dong3: "🥭 + 🍑 = 21", hoiHinh: "🍑", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🍒 + 🍒 = 10", dong2: "🍒 + 🍑 = 14", dong3: "🍑 + 🍓 = 16", hoiHinh: "🍓", dapAn: 7),
  CauHoiGiaiMaNangCao(dong1: "🍅 + 🍅 = 8", dong2: "🍅 + 🍆 = 13", dong3: "🍆 + 🥒 = 17", hoiHinh: "🥒", dapAn: 8),
  CauHoiGiaiMaNangCao(dong1: "🌽 + 🌽 = 14", dong2: "🌽 + 🥦 = 19", dong3: "🥦 + 🥬 = 22", hoiHinh: "🥬", dapAn: 10),
  CauHoiGiaiMaNangCao(dong1: "🍄 + 🍄 = 12", dong2: "🍄 + 🥜 = 16", dong3: "🥜 + 🌰 = 19", hoiHinh: "🌰", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🥐 + 🥐 = 6", dong2: "🥐 + 🥖 = 11", dong3: "🥖 + 🥨 = 16", hoiHinh: "🥨", dapAn: 8),
  CauHoiGiaiMaNangCao(dong1: "🥞 + 🥞 = 10", dong2: "🥞 + 🧇 = 16", dong3: "🧇 + 🧀 = 21", hoiHinh: "🧀", dapAn: 10),
  CauHoiGiaiMaNangCao(dong1: "🍔 + 🍔 = 14", dong2: "🍔 + 🍟 = 20", dong3: "🍟 + 🍕 = 24", hoiHinh: "🍕", dapAn: 11),
  CauHoiGiaiMaNangCao(dong1: "🍗 + 🍗 = 8", dong2: "🍗 + 🍖 = 15", dong3: "🍖 + 🌭 = 21", hoiHinh: "🌭", dapAn: 10),
  CauHoiGiaiMaNangCao(dong1: "🍿 + 🍿 = 10", dong2: "🍿 + 🍩 = 17", dong3: "🍩 + 🍪 = 21", hoiHinh: "🍪", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🍫 + 🍫 = 12", dong2: "🍫 + 🍬 = 18", dong3: "🍬 + 🍭 = 21", hoiHinh: "🍭", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🍮 + 🍮 = 6", dong2: "🍮 + 🍯 = 14", dong3: "🍯 + 🍼 = 20", hoiHinh: "🍼", dapAn: 13),
  CauHoiGiaiMaNangCao(dong1: "⚽ + ⚽ = 12", dong2: "⚽ + ⚾ = 17", dong3: "⚾ + 🎾 = 22", hoiHinh: "🎾", dapAn: 10),
  CauHoiGiaiMaNangCao(dong1: "🏀 + 🏀 = 14", dong2: "🏀 + 🏐 = 19", dong3: "🏐 + 🏉 = 23", hoiHinh: "🏉", dapAn: 11),
  CauHoiGiaiMaNangCao(dong1: "🎱 + 🎱 = 10", dong2: "🎱 + 🏓 = 16", dong3: "🏓 + 🏸 = 21", hoiHinh: "🏸", dapAn: 10),
  CauHoiGiaiMaNangCao(dong1: "🥊 + 🥊 = 8", dong2: "🥊 + 🛹 = 15", dong3: "🛹 + 🛼 = 19", hoiHinh: "🛼", dapAn: 8),
  CauHoiGiaiMaNangCao(dong1: "🎸 + 🎸 = 16", dong2: "🎸 + 🪕 = 21", dong3: "🪕 + 🎻 = 26", hoiHinh: "🎻", dapAn: 13),
  CauHoiGiaiMaNangCao(dong1: "🎨 + 🎨 = 10", dong2: "🎨 + 🎬 = 18", dong3: "🎬 + 🎤 = 22", hoiHinh: "🎤", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "🎧 + 🎧 = 12", dong2: "🎧 + 💻 = 20", dong3: "💻 + 📱 = 25", hoiHinh: "📱", dapAn: 11),
  CauHoiGiaiMaNangCao(dong1: "📷 + 📷 = 14", dong2: "📷 + 🔭 = 22", dong3: "🔭 + 🔬 = 27", hoiHinh: "🔬", dapAn: 12),
  CauHoiGiaiMaNangCao(dong1: "🔑 + 🔑 = 8", dong2: "🔑 + 🧰 = 17", dong3: "🧰 + 🔨 = 22", hoiHinh: "🔨", dapAn: 9),
  CauHoiGiaiMaNangCao(dong1: "👑 + 👑 = 12", dong2: "👑 + 💍 = 19", dong3: "💍 + 📿 = 24", hoiHinh: "📿", dapAn: 11),
];
  // ================= KHO 30 CÂU HỎI TÌM SỐ =================
  final List<CauHoiTimSo> _khoTimSo = [
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 10.", "Nhỏ hơn 20.", "Là số chẵn.", "Lấy số đó trừ 6 được 8."], dapAn: 14),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 5.", "Nhỏ hơn 15.", "Là số lẻ.", "Cộng với 3 thì bằng 10."], dapAn: 7),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 0.", "Nhỏ hơn 10.", "Là số chẵn.", "Nhân đôi lên bằng 8."], dapAn: 4),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 10.", "Nhỏ hơn 20.", "Trừ đi 5 thì bằng 8."], dapAn: 13),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 2.", "Nhỏ hơn 10.", "Cộng với 4 thì bằng 11."], dapAn: 7),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 15.", "Nhỏ hơn 20.", "Là số lẻ.", "Trừ đi 7 thì bằng 10."], dapAn: 17),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 6.", "Nhỏ hơn 12.", "Là số chẵn.", "Cộng với 2 thì bằng 10."], dapAn: 8),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 0.", "Nhỏ hơn 8.", "Trừ đi 2 thì bằng 3."], dapAn: 5),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 10.", "Nhỏ hơn 15.", "Là số chẵn.", "Cộng với 1 thì bằng 13."], dapAn: 12),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 12.", "Nhỏ hơn 18.", "Là số lẻ.", "Trừ đi 5 thì bằng 10."], dapAn: 15),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 1.", "Nhỏ hơn 9.", "Cộng với 5 thì bằng 12."], dapAn: 7),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 8.", "Nhỏ hơn 14.", "Là số chẵn.", "Trừ đi 4 thì bằng 6."], dapAn: 10),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 3.", "Nhỏ hơn 11.", "Cộng với 3 thì bằng 9."], dapAn: 6),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 14.", "Nhỏ hơn 20.", "Là số lẻ.", "Trừ đi 3 thì bằng 14."], dapAn: 17),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 0.", "Nhỏ hơn 7.", "Cộng với 4 thì bằng 9."], dapAn: 5),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 10.", "Nhỏ hơn 16.", "Là số chẵn.", "Trừ đi 2 thì bằng 10."], dapAn: 12),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 4.", "Nhỏ hơn 10.", "Cộng với 2 thì bằng 8."], dapAn: 6),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 13.", "Nhỏ hơn 19.", "Là số lẻ.", "Trừ đi 4 thì bằng 11."], dapAn: 15),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 2.", "Nhỏ hơn 8.", "Cộng với 3 thì bằng 8."], dapAn: 5),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 11.", "Nhỏ hơn 17.", "Là số chẵn.", "Trừ đi 3 thì bằng 11."], dapAn: 14),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 0.", "Nhỏ hơn 6.", "Cộng với 2 thì bằng 6."], dapAn: 4),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 16.", "Nhỏ hơn 20.", "Là số chẵn.", "Trừ đi 2 thì bằng 16."], dapAn: 18),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 5.", "Nhỏ hơn 11.", "Cộng với 1 thì bằng 8."], dapAn: 7),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 10.", "Nhỏ hơn 15.", "Là số lẻ.", "Trừ đi 2 thì bằng 11."], dapAn: 13),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 1.", "Nhỏ hơn 7.", "Cộng với 2 thì bằng 7."], dapAn: 5),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 12.", "Nhỏ hơn 18.", "Là số chẵn.", "Trừ đi 4 thì bằng 10."], dapAn: 14),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 3.", "Nhỏ hơn 9.", "Cộng với 2 thì bằng 7."], dapAn: 5),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 15.", "Nhỏ hơn 19.", "Là số lẻ.", "Trừ đi 3 thì bằng 14."], dapAn: 17),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 2.", "Nhỏ hơn 8.", "Cộng với 4 thì bằng 10."], dapAn: 6),
    CauHoiTimSo(tieuDe: "Tìm số bí mật:", danhSachDieuKien: ["Lớn hơn 10.", "Nhỏ hơn 16.", "Là số chẵn.", "Trừ đi 5 thì bằng 8."], dapAn: 13),
  ];
}
// MỤC KIỂM TRA & TÍCH LŨY SAO TƯ DUY NÂNG CAO (60 CÂU)
class TrangKiemTraNangCao60Cau extends StatefulWidget {
  const TrangKiemTraNangCao60Cau({super.key});
  @override
  State<TrangKiemTraNangCao60Cau> createState() =>
      _TrangKiemTraNangCao60CauState();
}
class _TrangKiemTraNangCao60CauState extends State<TrangKiemTraNangCao60Cau> {
  final FlutterTts flutterTts = FlutterTts();
  final Random _random = Random();
  late ConfettiController _confettiController;
  // 3 dạng bài nâng cao, mỗi dạng 20 câu = 60 câu tổng cộng
  final List<String> danhSachCacDangNangCao = [
    "me_cung_so",
    "quy_luat_an",
    "can_bang_so"
  ];
  int chiSoDangBaiHienTai = 0;
  int cauSoTrongDang = 0; // Từ 0 đến 19 (20 câu mỗi dạng)
  int tongSoCauDaLam = 0;
  final int tongSoCauHoi = 60;
  int soCauDung = 0;
  int soCauSai = 0;
  int soSaoTichLuy = 0; // Hệ thống tích lũy sao thưởng cho bé
  bool daHoanThanhBaiKiemTra = false;
  bool dangKhoaNut = false;
  final List<Map<String, dynamic>> danhSachCauSaiChiTiet = [];
  String tieuDeDangBai = "";
  String noiDungCauHoi = "";
  List<int> danhSachLuaChon = [];
  int dapAnDungSo = 0;
  String iconHienThi = "🚀";
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _khoiTaoTts();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }
  Future<void> _khoiTaoTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.52);
    if (!mounted) return;
    _taoCauHoiMoi();
  }
  Future<void> _noi(String noiDung) async {
    if (!mounted) return;
    await flutterTts.stop();
    if (!mounted) return;
    await flutterTts.speak(noiDung);
  }
  void _taoCauHoiMoi() {
    if (chiSoDangBaiHienTai >= danhSachCacDangNangCao.length) {
      setState(() {
        daHoanThanhBaiKiemTra = true;
        dangKhoaNut = true;
      });
      if (soCauDung >= 50) {
        _confettiController.play();
        _noi(
            "Tuyệt vời quá! Bé đã giành được tổng cộng $soSaoTichLuy ngôi sao vàng.");
      } else {
        _noi(
            "Bé đã hoàn thành 60 câu hỏi tư duy và tích lũy được $soSaoTichLuy ngôi sao.");
      }
      return;
    }
    String dangHienTai = danhSachCacDangNangCao[chiSoDangBaiHienTai];
    int soLuongLuaChon = (cauSoTrongDang < 5) ? 3 : 4;
    setState(() {
      dangKhoaNut = false;
      if (dangHienTai == "me_cung_so") {
        iconHienThi = "🧭";
        int loaiMeCung = _random.nextInt(7);
        if (loaiMeCung == 0) {
          tieuDeDangBai =
              "Phần 1: Mê cung tịnh tiến (${cauSoTrongDang + 1}/20)";
          int buocNhay = _random.nextInt(4) + 2;
          int s1 = _random.nextInt(8) + 1;
          int s2 = s1 + buocNhay;
          int s3 = s2 + buocNhay;
          dapAnDungSo = s3 + buocNhay;
          noiDungCauHoi = "Mê cung tịnh tiến đều: $s1 ➔ $s2 ➔ $s3 ➔ ?";
        } else if (loaiMeCung == 1) {
          tieuDeDangBai =
              "Phần 1: Mê cung dãy số chẵn (${cauSoTrongDang + 1}/20)";
          int s1 = (_random.nextInt(6) + 1) * 2;
          int s2 = s1 + 2;
          int s3 = s2 + 2;
          dapAnDungSo = s3 + 2;
          noiDungCauHoi = "Mê cung dãy số chẵn: $s1 ➔ $s2 ➔ $s3 ➔ ?";
        } else if (loaiMeCung == 2) {
          tieuDeDangBai =
              "Phần 1: Mê cung dãy số lẻ (${cauSoTrongDang + 1}/20)";
          int s1 = (_random.nextInt(6) * 2) + 1;
          int s2 = s1 + 2;
          int s3 = s2 + 2;
          dapAnDungSo = s3 + 2;
          noiDungCauHoi = "Mê cung dãy số lẻ: $s1 ➔ $s2 ➔ $s3 ➔ ?";
        } else if (loaiMeCung == 3) {
          tieuDeDangBai =
              "Phần 1: Mê cung quy luật nhân đôi (${cauSoTrongDang + 1}/20)";
          int s1 = _random.nextInt(4) + 1;
          int s2 = s1 * 2;
          int s3 = s2 * 2;
          dapAnDungSo = s3 * 2;
          if (dapAnDungSo > 40) dapAnDungSo = 16;
          noiDungCauHoi = "Mê cung nhân đôi: $s1 ➔ $s2 ➔ $s3 ➔ ?";
        } else if (loaiMeCung == 4) {
          tieuDeDangBai =
              "Phần 1: Mê cung bước lùi thông minh (${cauSoTrongDang + 1}/20)";
          int buocLui = _random.nextInt(3) + 2;
          int s1 = _random.nextInt(10) + 15;
          int s2 = s1 - buocLui;
          int s3 = s2 - buocLui;
          dapAnDungSo = s3 - buocLui;
          if (dapAnDungSo < 1) dapAnDungSo = 3;
          noiDungCauHoi = "Mê cung bước lùi đều: $s1 ➔ $s2 ➔ $s3 ➔ ?";
        } else if (loaiMeCung == 5) {
          tieuDeDangBai =
              "Phần 1: Mê cung nhịp điệu tăng dần (${cauSoTrongDang + 1}/20)";
          int s1 = _random.nextInt(4) + 1;
          int s2 = s1 + 2;
          int s3 = s2 + 3;
          dapAnDungSo = s3 + 4;
          noiDungCauHoi = "Mê cung nhịp điệu (+2, +3, +4): $s1 ➔ $s2 ➔ $s3 ➔ ?";
        } else {
          tieuDeDangBai =
              "Phần 1: Mê cung nhảy cóc cách đều (${cauSoTrongDang + 1}/20)";
          int buocNhay = 5;
          int s1 = _random.nextInt(5) + 1;
          int s2 = s1 + buocNhay;
          int s3 = s2 + buocNhay;
          dapAnDungSo = s3 + buocNhay;
          noiDungCauHoi = "Mê cung nhảy cóc (+5): $s1 ➔ $s2 ➔ $s3 ➔ ?";
        }
        Set<int> luaChon = {dapAnDungSo};
        while (luaChon.length < soLuongLuaChon) {
          int soNgauNhien = dapAnDungSo +
              (_random.nextBool() ? 1 : -1) * (_random.nextInt(4) + 1);
          if (soNgauNhien > 0 && soNgauNhien != dapAnDungSo)
            luaChon.add(soNgauNhien);
          else
            luaChon.add(_random.nextInt(25) + 1);
        }
        danhSachLuaChon = luaChon.toList()..shuffle();
        _noi(noiDungCauHoi);
      } else if (dangHienTai == "quy_luat_an") {
        iconHienThi = "🔮";
        tieuDeDangBai = "Phần 2: Giải Mã Mật Mã Ẩn (${cauSoTrongDang + 1}/20)";
        int loaiAn = _random.nextInt(4);
        if (loaiAn == 0) {
          int giaTriHinh = _random.nextInt(5) + 2;
          dapAnDungSo = giaTriHinh;
          int tongHaiHinh = giaTriHinh * 2;
          noiDungCauHoi = "Giải mã: 🌟 + 🌟 = $tongHaiHinh. Hỏi 🌟 bằng mấy?";
        } else if (loaiAn == 1) {
          int valA = _random.nextInt(4) + 2;
          int valB = _random.nextInt(5) + 3;
          int tong = valA + valB;
          dapAnDungSo = valB;
          noiDungCauHoi =
              "Mật mã: 🍎 + 🍌 = $tong. Biết 🍎 = $valA. Hỏi 🍌 = ?";
        } else if (loaiAn == 2) {
          int buocNhay = _random.nextInt(3) + 2;
          int s1 = _random.nextInt(5) + 2;
          int s2 = s1 + buocNhay;
          int s3 = s2 + buocNhay;
          dapAnDungSo = s3 + buocNhay;
          noiDungCauHoi =
              "Truy tìm ẩn số ❓: 🔷 ($s1) ➔ 🔷 ($s2) ➔ 🔷 ($s3) ➔ ❓";
        } else {
          int valX = _random.nextInt(4) + 2;
          int nhanVien = _random.nextInt(3) + 2;
          int tich = valX * nhanVien;
          dapAnDungSo = valX;
          noiDungCauHoi = "Mật mã nhân: 🍀 × $nhanVien = $tich. Hỏi 🍀 = ?";
        }
        Set<int> luaChon = {dapAnDungSo};
        while (luaChon.length < soLuongLuaChon) {
          int soNgauNhien = dapAnDungSo +
              (_random.nextBool() ? 1 : -1) * (_random.nextInt(4) + 1);
          if (soNgauNhien > 0 && soNgauNhien != dapAnDungSo) {
            luaChon.add(soNgauNhien);
          } else {
            luaChon.add(_random.nextInt(20) + 1);
          }
        }
        danhSachLuaChon = luaChon.toList()..shuffle();
        _noi(noiDungCauHoi);
      } else if (dangHienTai == "can_bang_so") {
        iconHienThi = "⚖️";
        tieuDeDangBai = "Phần 3: Cân bằng phép toán (${cauSoTrongDang + 1}/20)";
        int veTrai1 = _random.nextInt(8) + 2;
        int veTrai2 = _random.nextInt(6) + 1;
        int tongTrai = veTrai1 + veTrai2;
        int vePhai1 = _random.nextInt(tongTrai - 1) + 1;
        dapAnDungSo = tongTrai - vePhai1;
        // Hiển thị chuẩn toán học trên màn hình
        noiDungCauHoi = "$veTrai1 + $veTrai2 = $vePhai1 + ?";
        // Chuỗi phát âm ngắt quãng tự nhiên
        String noiDungDoc = "$veTrai1 cộng $veTrai2, bằng $vePhai1 cộng mấy?";
        Set<int> luaChon = {dapAnDungSo};
        while (luaChon.length < soLuongLuaChon) {
          int soNgauNhien = dapAnDungSo +
              (_random.nextBool() ? 1 : -1) * (_random.nextInt(4) + 1);
          if (soNgauNhien > 0 && soNgauNhien != dapAnDungSo)
            luaChon.add(soNgauNhien);
          else
            luaChon.add(_random.nextInt(15) + 1);
        }
        danhSachLuaChon = luaChon.toList()..shuffle();
        _noi(noiDungDoc);
      }
    });
  }

  void _xuLyKetQuaCauHoi(bool laDung, String chiTietCauHoi) {
    setState(() {
      dangKhoaNut = true;
      tongSoCauDaLam++;
      if (laDung) {
        soCauDung++;
        soSaoTichLuy += 1;
        _noi("Đúng rồi! Bé nhận được một ngôi sao vàng!");
      } else {
        soCauSai++;
        danhSachCauSaiChiTiet.add({"cau": chiTietCauHoi});
        _noi("Tiếc quá, chưa đúng rồi bé ơi!");
      }
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        cauSoTrongDang++;
        if (cauSoTrongDang >= 20) {
          cauSoTrongDang = 0;
          chiSoDangBaiHienTai++;
        }
      });
      _taoCauHoiMoi();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        title: Text("Kiểm Tra Tư Duy 60 Câu ⭐ $soSaoTichLuy Sao"),
        backgroundColor: Colors.purple,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          daHoanThanhBaiKiemTra
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🏆 TỔNG KẾT THỬ THÁCH 🏆",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple)),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 26),
                          const SizedBox(width: 8),
                          Text("Tổng số sao đạt được: $soSaoTichLuy sao",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange)),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text("Số câu đúng: $soCauDung / 60",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      Text("Số câu sai: $soCauSai / 60",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      const SizedBox(height: 15),
                      danhSachCauSaiChiTiet.isNotEmpty
                          ? Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("📝 Các câu cần ôn tập lại:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red)),
                                  const SizedBox(height: 1),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: danhSachCauSaiChiTiet.length,
                                      itemBuilder: (context, index) {
                                        var item = danhSachCauSaiChiTiet[index];
                                        return Card(
                                          child: ListTile(
                                            title: Text(item["cau"],
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Text("🌟 Tuyệt vời! Bé đạt điểm tuyệt đối!",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold)),
                      const SizedBox(height: 1),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12)),
                        onPressed: () {
                          setState(() {
                            chiSoDangBaiHienTai = 0;
                            cauSoTrongDang = 0;
                            tongSoCauDaLam = 0;
                            soCauDung = 0;
                            soCauSai = 0;
                            soSaoTichLuy = 0;
                            daHoanThanhBaiKiemTra = false;
                            danhSachCauSaiChiTiet.clear();
                          });
                          _taoCauHoiMoi();
                        },
                        child: const Text("Làm lại từ đầu",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Câu: ${tongSoCauDaLam + 1}/$tongSoCauHoi",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple)),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 22),
                              const SizedBox(width: 4),
                              Text(":$soSaoTichLuy sao",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                      fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      LinearProgressIndicator(
                        value: (tongSoCauDaLam + 1) / tongSoCauHoi,
                        backgroundColor: Colors.purple.shade100,
                        color: Colors.purple,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 1),
                      Text(tieuDeDangBai,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple)),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(iconHienThi,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 10),
                          IconButton(
                            iconSize: 30,
                            color: Colors.purple,
                            icon: const Icon(Icons.volume_up_rounded),
                            onPressed: () {
                              // Xử lý nút loa đọc lại đúng ngữ điệu tự nhiên cho từng dạng
                              String dangHienTai =
                                  danhSachCacDangNangCao[chiSoDangBaiHienTai];
                              if (dangHienTai == "can_bang_so") {
                                List<String> phanTich =
                                    noiDungCauHoi.split(" = ");
                                if (phanTich.length == 2) {
                                  String veTrai =
                                      phanTich[0].replaceAll(" + ", " cộng ");
                                  String vePhai = phanTich[1]
                                      .replaceAll(" + ?", " cộng mấy?");
                                  _noi("$veTrai, bằng $vePhai");
                                } else {
                                  _noi(noiDungCauHoi);
                                }
                              } else {
                                _noi(noiDungCauHoi);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          noiDungCauHoi,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: danhSachLuaChon.map((so) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 26, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: dangKhoaNut
                                ? null
                                : () {
                                    bool laDung = (so == dapAnDungSo);
                                    _xuLyKetQuaCauHoi(laDung,
                                        "$noiDungCauHoi (Đáp án đúng: $dapAnDungSo)");
                                  },
                            child: Text("$so",
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                Colors.red,
                Colors.purple,
                Colors.blue,
                Colors.yellow,
                Colors.pink,
                Colors.orange
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// TRANG GHÉP HÌNH
// 1. CLASS CẮT VIỀN RĂNG CƯA
class ManhGhepModel {
  final int index;
  final int hang;
  final int cot;
  bool daGhepDung;
  ManhGhepModel({
    required this.index,
    required this.hang,
    required this.cot,
    this.daGhepDung = false,
  });
}
class TrangGhepHinh extends StatefulWidget {
  const TrangGhepHinh({super.key});
  @override
  State<TrangGhepHinh> createState() => _TrangGhepHinhState();
}
class _TrangGhepHinhState extends State<TrangGhepHinh>
    with TickerProviderStateMixin {
  late FlutterTts _flutterTts;
  late ConfettiController _phaoHoaController;
  late AnimationController _shakeController;
  final Map<String, dynamic> duLieuChuDe = {
    "anhGoc": "assets/giangsinh.png",
    "soHang": 6,
    "soCot": 4,
  };
  final List<Map<String, dynamic>> _danhSachChuDe = [
    {"tenChuDe": "Giáng Sinh","anhGoc": "assets/giangsinh.png","soHang": 6,"soCot": 4,"mauSac": Colors.redAccent,},
    {"tenChuDe": "Gia Đình","mauSac": Colors.orangeAccent,"laThuMuc": true,
      "danhSachAnhCon": [
        {"tenAnh": "Bảo An","anhGoc": "assets/baoan.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Như Bình","anhGoc": "assets/nhubinh.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Gia Đình","anhGoc": "assets/giadinh.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Thắng Lê","anhGoc": "assets/thangle.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Bình An","anhGoc": "assets/binhan.png","soHang": 6,"soCot": 4,},
      ],
    },
    {
      "tenChuDe": "Thiên Nhiên",
      "mauSac": const ui.Color.fromARGB(255, 64, 163, 255),
      "laThuMuc": true,
      "danhSachAnhCon": [
        {"tenAnh": "Thiên Nhiên","anhGoc": "assets/thiennhien.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Động Vật 1","anhGoc": "assets/dongvat1.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Động Vật 2","anhGoc": "assets/dongvat2.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Động Vật 3","anhGoc": "assets/dongvat3.png","soHang": 6,"soCot": 4,},
      ],
    },
    {
      "tenChuDe": "LaBuBu Và Công Chúa",
      "mauSac": const ui.Color.fromARGB(255, 255, 64, 207),
      "laThuMuc": true,
      "danhSachAnhCon": [
        {"tenAnh": "LABUBU","anhGoc": "assets/labubu.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "LABUBU1","anhGoc": "assets/labubu1.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Công Chúa 1","anhGoc": "assets/congchua1.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Công Chúa 2","anhGoc": "assets/congchua2.png","soHang": 6,"soCot": 4,},
        {"tenAnh": "Công Chúa 3","anhGoc": "assets/congchua3.png","soHang": 6,"soCot": 4,},
      ],
    },
  ];
  String? _chuDeDangChon;
  String? _thuMucDangChon;
  bool _dangXemTruoc = false;
  int _giayDaTroi = 0;
  Timer? _timer;
  List<List<int>> _cacCanhNgang = [];
  List<List<int>> _cacCanhDoc = [];
  List<ManhGhepModel> _danhSachManhGhep = [];
  final Map<int, bool> _cacManhDaDung = {};
  @override
  void initState() {
    super.initState();
    _khoiTaoTTS();
    _phaoHoaController =
        ConfettiController(duration: const Duration(seconds: 5));
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }
  void _khoiTaoTTS() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.1);
  }
  Future<void> _phatGiongNoi(String noiDung) async {
    await _flutterTts.speak(noiDung);
  }
  @override
  void dispose() {
    _timer?.cancel();
    _flutterTts.stop();
    _phaoHoaController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  void _batDauChoi() {
    int soHang = duLieuChuDe["soHang"] as int;
    int soCot = duLieuChuDe["soCot"] as int;
    final random = Random();
    setState(() {
      _dangXemTruoc = false;
      _giayDaTroi = 0;
      _cacManhDaDung.clear();
      _cacCanhNgang = List.generate(soHang - 1,
          (h) => List.generate(soCot, (c) => random.nextBool() ? 1 : -1));
      _cacCanhDoc = List.generate(soHang,
          (h) => List.generate(soCot - 1, (c) => random.nextBool() ? 1 : -1));
      _danhSachManhGhep = List.generate(soHang * soCot, (index) {
        int h = index ~/ soCot;
        int c = index % soCot;
        return ManhGhepModel(
          index: index,
          hang: h,
          cot: c,
        );
      });
      _danhSachManhGhep.shuffle(random);
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _giayDaTroi++;
      });
    });
  }
  Widget _buildMotManhGhep(
      int h, int c, int tongSoHang, int tongSoCot, double oW, double oH) {
    double khungW = oW * tongSoCot;
    double khungH = oH * tongSoHang;
    double bumpSize = min(oW, oH) * 0.25;
    int canhTren = (h == 0) ? 0 : -_cacCanhNgang[h - 1][c];
    int canhDuoi = (h == tongSoHang - 1) ? 0 : _cacCanhNgang[h][c];
    int canhTrai = (c == 0) ? 0 : -_cacCanhDoc[h][c - 1];
    int canhPhai = (c == tongSoCot - 1) ? 0 : _cacCanhDoc[h][c];
    return SizedBox(
      width: oW + bumpSize * 2,
      height: oH + bumpSize * 2,
      child: ClipPath(
        clipper: PuzzlePieceClipper(
          canhTren: canhTren,
          canhPhai: canhPhai,
          canhDuoi: canhDuoi,
          canhTrai: canhTrai,
          bumpSize: bumpSize,
        ),
        child: Stack(
          children: [
            Positioned(
              left: -c * oW + bumpSize,
              top: -h * oH + bumpSize,
              width: khungW,
              height: khungH,
              child: Image.asset(
                duLieuChuDe["anhGoc"],
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_chuDeDangChon == null) return _buildMenu();
    if (_dangXemTruoc) return _buildManhHinhXemTruoc();
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.amber.shade50,
          appBar: AppBar(
            toolbarHeight: 36,
            backgroundColor: Colors.amber.shade50,
            elevation: 0,
            leading: Center(child: _nutQuayLaiChuan(context)),
            title: Text(
              "Chủ đề: $_chuDeDangChon",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            centerTitle: true,
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.brown.shade300, width: 1),
                    ),
                    child: Text(
                      "⏱️ $_giayDaTroi s",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(child: _buildManhHinhChoiGhep()),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _phaoHoaController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            numberOfParticles: 30,
            gravity: 0.1,
            colors: const [
              Colors.red,
              Colors.green,
              Colors.blue,
              Colors.orange,
              Colors.purple,
              Colors.pink
            ],
          ),
        ),
      ],
    );
  }
  Widget _nutQuayLaiChuan(BuildContext context) {
    return InkWell(
      onTap: () {
        _timer?.cancel();
        _phaoHoaController.stop();
        setState(() {
          if (_dangXemTruoc) {
            _dangXemTruoc = false;
            if (_thuMucDangChon != null) {
              _chuDeDangChon = null; // Về lại danh sách ảnh trong thư mục
            } else {
              _chuDeDangChon = null;
            }
          } else if (_chuDeDangChon != null) {
            // Đang trong màn hình chơi -> thoát ra menu/thư mục
            _chuDeDangChon = null;
          } else if (_thuMucDangChon != null) {
            // Đang ở trong thư mục con -> thoát ra menu tổng
            _thuMucDangChon = null;
          } else {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        });
      },
      child: Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    border: Border.all(
      color: Colors.amber, // Viền vàng bao khung
      width: 2.5,          // Độ dày viền
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: const Icon(
    Icons.arrow_back_rounded,
    color: Colors.brown,
    size: 26,
  ),
),
    );
  }
  Widget _buildMenu() {
    if (_thuMucDangChon != null) {
      final thuMuc =
          _danhSachChuDe.firstWhere((e) => e["tenChuDe"] == _thuMucDangChon);
      final List<dynamic> danhSachCon = thuMuc["danhSachAnhCon"];
      return Scaffold(
        backgroundColor: Colors.amber.shade100,
        appBar: AppBar(
          toolbarHeight: 45,
          backgroundColor: Colors.amber.shade100,
          elevation: 0,
          leading: Center(child: _nutQuayLaiChuan(context)),
          title: Text(
            "Thư mục: $_thuMucDangChon",
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: danhSachCon.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final anhCon = danhSachCon[index];
              return Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      duLieuChuDe["anhGoc"] = anhCon["anhGoc"];
                      duLieuChuDe["soHang"] = anhCon["soHang"];
                      duLieuChuDe["soCot"] = anhCon["soCot"];
                      _chuDeDangChon = anhCon["tenAnh"];
                      _dangXemTruoc = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Text(
                      "Bức tranh: ${anhCon["tenAnh"]} ❤️",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.amber.shade100,
      appBar: AppBar(
        toolbarHeight: 45,
        backgroundColor: Colors.amber.shade100,
        elevation: 0,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text(
          "Chọn Chủ Đề",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _danhSachChuDe.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final chuDe = _danhSachChuDe[index];
            bool laThuMuc = chuDe["laThuMuc"] ?? false;
            return Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (laThuMuc) {
                      _thuMucDangChon = chuDe["tenChuDe"];
                    } else {
                      duLieuChuDe["anhGoc"] = chuDe["anhGoc"];
                      duLieuChuDe["soHang"] = chuDe["soHang"];
                      duLieuChuDe["soCot"] = chuDe["soCot"];
                      _chuDeDangChon = chuDe["tenChuDe"];
                      _dangXemTruoc = true;
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: chuDe["mauSac"],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    "Chủ đề: ${chuDe["tenChuDe"]} ${laThuMuc ? "👨‍👩‍👧‍👦" : "🎄"}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildManhHinhXemTruoc() {
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      appBar: AppBar(
        toolbarHeight: 36,
        backgroundColor: Colors.amber.shade50,
        elevation: 0,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text(
          "Xem Tranh Mẫu",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        centerTitle: true,
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 350,
            height: 460,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(duLieuChuDe["anhGoc"], fit: BoxFit.fill),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Bé nhớ kỹ bức tranh mẫu này nhé!",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _batDauChoi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "BẮT ĐẦU GHÉP HÌNH",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildManhHinhChoiGhep() {
    int hang = duLieuChuDe["soHang"] as int;
    int cot = duLieuChuDe["soCot"] as int;
    int tongSoManh = hang * cot;
    double khungW = 320.0;
    double khungH = 480.0;
    double oW = khungW / cot;
    double oH = khungH / hang;
    double bumpSize = min(oW, oH) * 0.25;
    List<ManhGhepModel> manhChuaGhep =
        _danhSachManhGhep.where((m) => !m.daGhepDung).toList();
    List<ManhGhepModel> manhBenTrai = [];
    List<ManhGhepModel> manhBenPhai = [];
    for (int i = 0; i < manhChuaGhep.length; i++) {
      if (i % 2 == 0) {
        manhBenTrai.add(manhChuaGhep[i]);
      } else {
        manhBenPhai.add(manhChuaGhep[i]);
      }
    }
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildKhayManhGhep(
                  danhSach: manhBenTrai,
                  hang: hang,
                  cot: cot,
                  oW: oW,
                  oH: oH,
                  bumpSize: bumpSize,
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      double sineValue = sin(_shakeController.value * pi * 4);
                      double offsetVal =
                          _shakeController.isAnimating ? sineValue * 8.0 : 0.0;
                      return Transform.translate(
                        offset: Offset(offsetVal, 0),
                        child: child,
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Container(
                        width: khungW,
                        height: khungH,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade800,
                          border: Border.all(
                              color: Colors.brown.shade900, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          clipBehavior: Clip.none,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cot,
                            childAspectRatio: oW / oH,
                          ),
                          itemCount: tongSoManh,
                          itemBuilder: (context, index) {
                            int h = index ~/ cot;
                            int c = index % cot;
                            bool daDungDung = _cacManhDaDung[index] ?? false;
                            int canhTren =
                                (h == 0) ? 0 : -_cacCanhNgang[h - 1][c];
                            int canhDuoi =
                                (h == hang - 1) ? 0 : _cacCanhNgang[h][c];
                            int canhTrai =
                                (c == 0) ? 0 : -_cacCanhDoc[h][c - 1];
                            int canhPhai =
                                (c == cot - 1) ? 0 : _cacCanhDoc[h][c];
                            return DragTarget<int>(
                              onWillAcceptWithDetails: (details) => true,
                              onAcceptWithDetails: (details) {
                                int data = details.data;
                                if (data == index) {
                                  setState(() {
                                    _cacManhDaDung[data] = true;
                                    _danhSachManhGhep
                                        .firstWhere((m) => m.index == data)
                                        .daGhepDung = true;
                                  });
                                  bool daHoanThanh = _cacManhDaDung.values
                                          .where((v) => v == true)
                                          .length ==
                                      tongSoManh;
                                  if (daHoanThanh) {
                                    _timer?.cancel();
                                    _phaoHoaController.play();
                                    _hienThiDialogThangVaDoc();
                                  }
                                } else {
                                  _shakeController.forward(from: 0.0);
                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "❌ Sai vị trí rồi, bé tìm ô khác nhé! ❤️"),
                                      backgroundColor: Colors.redAccent,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              builder: (context, candidateData, rejectedData) {
                                if (daDungDung) {
                                  // ĐÃ SỬA: Đặt trực tiếp _buildMotManhGhep bên trong ô đích với kích thước gốc (oW, oH)
                                  return Align(
                                    alignment: Alignment.center,
                                    child: OverflowBox(
                                      maxWidth: oW + bumpSize * 2,
                                      maxHeight: oH + bumpSize * 2,
                                      child: _buildMotManhGhep(
                                          h, c, hang, cot, oW, oH),
                                    ),
                                  );
                                } else {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: -bumpSize,
                                        top: -bumpSize,
                                        child: CustomPaint(
                                          painter: PuzzleBorderPainter(
                                            canhTren: canhTren,
                                            canhPhai: canhPhai,
                                            canhDuoi: canhDuoi,
                                            canhTrai: canhTrai,
                                            bumpSize: bumpSize,
                                            borderColor: Colors.white30,
                                          ),
                                          child: ClipPath(
                                            clipper: PuzzlePieceClipper(
                                              canhTren: canhTren,
                                              canhPhai: canhPhai,
                                              canhDuoi: canhDuoi,
                                              canhTrai: canhTrai,
                                              bumpSize: bumpSize,
                                            ),
                                            child: Container(
                                              width: oW + bumpSize * 2,
                                              height: oH + bumpSize * 2,
                                              color: Colors.brown.shade700
                                                  .withOpacity(0.5),
                                              child: Center(
                                                child: Text(
                                                  "${index + 1}",
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.4),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildKhayManhGhep(
                  danhSach: manhBenPhai,
                  hang: hang,
                  cot: cot,
                  oW: oW,
                  oH: oH,
                  bumpSize: bumpSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKhayManhGhep({
    required List<ManhGhepModel> danhSach,
    required int hang,
    required int cot,
    required double oW,
    required double oH,
    required double bumpSize,
  }) {
    double scale = 0.85;
    double khayOW = oW * scale;
    double khayOH = oH * scale;
    double khayBump = bumpSize * scale;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.brown.shade100.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade300, width: 1.5),
      ),
      child: GridView.builder(
        clipBehavior: Clip.none,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: khayOW + khayBump * 2 + 2,
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
          childAspectRatio: (khayOW + khayBump * 1) / (khayOH + khayBump * 1),
        ),
        itemCount: danhSach.length,
        itemBuilder: (context, idx) {
          final manh = danhSach[idx];
          Widget pieceWidget = _buildMotManhGhep(
            manh.hang,
            manh.cot,
            hang,
            cot,
            khayOW,
            khayOH,
          );
          return Center(
            child: Draggable<int>(
              data: manh.index,
              dragAnchorStrategy: childDragAnchorStrategy,
              feedback: Material(
                color: Colors.transparent,
                child: _buildMotManhGhep(
                    manh.hang, manh.cot, hang, cot, khayOW, khayOH),
              ),
              childWhenDragging: Opacity(
                opacity: 0.2,
                child: pieceWidget,
              ),
              child: pieceWidget,
            ),
          );
        },
      ),
    );
  }
  void _hienThiDialogThangVaDoc() {
    String cauChuc =
        "Xuất sắc quá bé ơi! Bé đã hoàn thành xuất sắc bức tranh lắp ghép $_chuDeDangChon rồi! Tổng thời gian con hoàn thành là $_giayDaTroi giây.";
    _phatGiongNoi(cauChuc);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("🎉 XUẤT SẮC QUÁ BÉ ƠI! 🎉",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "Bé đã hoàn thành xuất sắc bức tranh lắp ghép $_chuDeDangChon rồi! ❤️",
                textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Text("⏱️ Tổng thời gian: $_giayDaTroi giây",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                _phaoHoaController.stop();
                Navigator.pop(context);
                setState(() {
                  _chuDeDangChon = null;
                  _thuMucDangChon = null;
                });
              },
              child: const Text("Chơi Lại Nhé"),
            ),
          ),
        ],
      ),
    );
  }
}
class PuzzlePieceClipper extends CustomClipper<Path> {
  final int canhTren;
  final int canhPhai;
  final int canhDuoi;
  final int canhTrai;
  final double bumpSize;
  PuzzlePieceClipper({
    required this.canhTren,
    required this.canhPhai,
    required this.canhDuoi,
    required this.canhTrai,
    required this.bumpSize,
  });
  @override
  Path getClip(Size size) {
    var path = Path();
    double w = size.width - bumpSize * 2;
    double h = size.height - bumpSize * 2;
    double p = bumpSize;
    path.moveTo(p, p);
    veCanhJigsaw(path, Offset(p, p), Offset(p + w, p), canhTren);
    veCanhJigsaw(path, Offset(p + w, p), Offset(p + w, p + h), canhPhai);
    veCanhJigsaw(path, Offset(p + w, p + h), Offset(p, p + h), canhDuoi);
    veCanhJigsaw(path, Offset(p, p + h), Offset(p, p), canhTrai);
    path.close();
    return path;
  }
  void veCanhJigsaw(Path path, Offset p1, Offset p2, int kieuCanh) {
    if (kieuCanh == 0) {
      path.lineTo(p2.dx, p2.dy);
      return;
    }
    double dx = p2.dx - p1.dx;
    double dy = p2.dy - p1.dy;
    double len = sqrt(dx * dx + dy * dy);
    double nx = -dy / len;
    double ny = dx / len;
    if (kieuCanh == -1) {
      nx = -nx;
      ny = -ny;
    }
    double tabSize = len * 0.22;
    Offset mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    Offset c1 = Offset(p1.dx + dx * 0.38, p1.dy + dy * 0.38);
    Offset c2 = Offset(p1.dx + dx * 0.62, p1.dy + dy * 0.62);
    Offset top = Offset(mid.dx + nx * tabSize, mid.dy + ny * tabSize);
    Offset cp1 = Offset(c1.dx - dx * 0.08 + nx * tabSize * 0.3,
        c1.dy - dy * 0.08 + ny * tabSize * 0.3);
    Offset cp2 = Offset(top.dx - dx * 0.25, top.dy - dy * 0.25);
    Offset cp3 = Offset(top.dx + dx * 0.25, top.dy + dy * 0.25);
    Offset cp4 = Offset(c2.dx + dx * 0.08 + nx * tabSize * 0.3,
        c2.dy + dy * 0.08 + ny * tabSize * 0.3);
    path.lineTo(c1.dx, c1.dy);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, top.dx, top.dy);
    path.cubicTo(cp3.dx, cp3.dy, cp4.dx, cp4.dy, c2.dx, c2.dy);
    path.lineTo(p2.dx, p2.dy);
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
class PuzzleBorderPainter extends CustomPainter {
  final int canhTren;
  final int canhPhai;
  final int canhDuoi;
  final int canhTrai;
  final double bumpSize;
  final Color borderColor;
  PuzzleBorderPainter({
    required this.canhTren,
    required this.canhPhai,
    required this.canhDuoi,
    required this.canhTrai,
    required this.bumpSize,
    this.borderColor = Colors.white30,
  });
  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    double w = size.width - bumpSize * 2;
    double h = size.height - bumpSize * 2;
    double p = bumpSize;
    path.moveTo(p, p);
    _veCanhJigsaw(path, Offset(p, p), Offset(p + w, p), canhTren);
    _veCanhJigsaw(path, Offset(p + w, p), Offset(p + w, p + h), canhPhai);
    _veCanhJigsaw(path, Offset(p + w, p + h), Offset(p, p + h), canhDuoi);
    _veCanhJigsaw(path, Offset(p, p + h), Offset(p, p), canhTrai);
    path.close();
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, paint);
  }
  void _veCanhJigsaw(Path path, Offset p1, Offset p2, int kieuCanh) {
    if (kieuCanh == 0) {
      path.lineTo(p2.dx, p2.dy);
      return;
    }
    double dx = p2.dx - p1.dx;
    double dy = p2.dy - p1.dy;
    double len = sqrt(dx * dx + dy * dy);
    double nx = -dy / len;
    double ny = dx / len;
    if (kieuCanh == -1) {
      nx = -nx;
      ny = -ny;
    }
    double tabSize = len * 0.22;
    Offset mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    Offset c1 = Offset(p1.dx + dx * 0.38, p1.dy + dy * 0.38);
    Offset c2 = Offset(p1.dx + dx * 0.62, p1.dy + dy * 0.62);
    Offset top = Offset(mid.dx + nx * tabSize, mid.dy + ny * tabSize);
    Offset cp1 = Offset(c1.dx - dx * 0.08 + nx * tabSize * 0.3,
        c1.dy - dy * 0.08 + ny * tabSize * 0.3);
    Offset cp2 = Offset(top.dx - dx * 0.25, top.dy - dy * 0.25);
    Offset cp3 = Offset(top.dx + dx * 0.25, top.dy + dy * 0.25);
    Offset cp4 = Offset(c2.dx + dx * 0.08 + nx * tabSize * 0.3,
        c2.dy + dy * 0.08 + ny * tabSize * 0.3);
    path.lineTo(c1.dx, c1.dy);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, top.dx, top.dy);
    path.cubicTo(cp3.dx, cp3.dy, cp4.dx, cp4.dy, c2.dx, c2.dy);
    path.lineTo(p2.dx, p2.dy);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// TRANG TRUYỆN CHO BÉ
class TrangChuyenKe extends StatelessWidget {
  const TrangChuyenKe({Key? key}) : super(key: key);
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text(
          "Góc Chuyện Kể Cho Bé",
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(200, 32, 178, 170), // Xanh ngọc mờ đồng bộ
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bé thích đọc truyện loại nào nhỉ? 👇",
              style: TextStyle(fontSize:0, fontWeight: FontWeight.bold, color: Colors.brown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 0),
            // Mục 1: Truyện Tranh
            _buildOptionCard(
              context: context,
              title: "TRUYỆN TRANH",
              subTitle: "Xem hình ảnh sinh động & nghe kể chuyện",
              icon: "🖼️",
              color: Colors.pinkAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrangDanhSachTruyenTranh()),
                );
              },
            ),
            const SizedBox(height: 15),
            // Mục 2: Truyện Kể Không Có Hình
            _buildOptionCard(
              context: context,
              title: "TRUYỆN KỂ",
              subTitle: "Truyện chữ rèn luyện trí tưởng tượng",
              icon: "📚",
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrangTruyenChu()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subTitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 50)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subTitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}

// TRUYỆN TRANH
class TrangDanhSachTruyenTranh extends StatelessWidget {
  const TrangDanhSachTruyenTranh({Key? key}) : super(key: key);
  final List<Map<String, dynamic>> danhSachTruyen = const [
    {
      "id": "tho_con_xin_loi",
      "ten": "Chú Thỏ Con Biết Nói Lời Xin Lỗi",
      "moTa": "Bài học bé nhỏ về sự dũng cảm nhận lỗi và nói lời xin lỗi chân thành.",
      "icon": "🐰",
      "mau": Colors.pink,
      "images": [
        "images/tho1.png",
        "images/tho2.png",
        "images/tho3.png",
        "images/tho4.png",
        "images/tho5.png",
        "images/tho6.png",
      ],
    },
    {
      "id": "cun_con_so_di_ngu",
      "ten": "Chú Cún Con Sợ Đi Ngủ",
      "moTa": "Câu chuyện vỗ về giấc ngủ, giúp bé bớt sợ bóng đêm.",
      "icon": "🐶",
      "mau": Colors.indigo,
      "images": [
        "images/cun1.png",
        "images/cun2.png",
        "images/cun3.png",
        "images/cun4.png",
        "images/cun5.png",
        "images/cun6.png",
      ],
    },
    {
      "id": "chim_sau_lang_nghe",
      "ten": "Chú Chim Sâu Học Cách Lắng Nghe",
      "moTa": "Lắng nghe để trưởng thành, thể hiện tình yêu thương và tôn trọng.",
      "icon": "🐦",
      "mau": Colors.blue,
      "images": [
        "images/chimse1.png",
        "images/chimse2.png",
        "images/chimse3.png",
        "images/chimse4.png",
        "images/chimse5.png",
        "images/chimse6.png",
      ],
    },
    {
      "id": "soc_nau_qua_tao",
      "ten": "Chú Sóc Nâu Và Quả Táo Khổng Lồ",
      "moTa": "Bài học ý nghĩa về sự đoàn kết, sẻ chia và tình bạn đẹp.",
      "icon": "🐿️",
      "mau": Colors.orange,
      "images": [
        "images/soc1.png",
        "images/soc2.png",
        "images/soc3.png",
        "images/soc4.png",
        "images/soc5.png",
        "images/soc6.png",
      ],
    },
    {
      "id": "nhim_tim_lai_nu_cuoi",
      "ten": "Chú Nhím Tìm Lại Nụ Cười",
      "moTa": "Học cách mở lòng, kết bạn và mang lại niềm vui cho mọi người xung quanh.",
      "icon": "🦔",
      "mau": Colors.brown,
      "images": [
        "images/nhim1.png",
        "images/nhim2.png",
        "images/nhim3.png",
        "images/nhim4.png",
        "images/nhim5.png",
        "images/nhim6.png",
      ],
    },
    {
      "id": "vit_con_hoc_cach_cam_on",
      "ten": "Chú Vịt Con Học Cách Cảm Ơn",
      "moTa": "Hiểu được lòng biết ơn và trân trọng sự giúp đỡ từ những người bạn.",
      "icon": "🦆",
      "mau": Colors.amber,
      "images": [
        "images/vit1.png",
        "images/vit2.png",
        "images/vit3.png",
        "images/vit4.png",
        "images/vit5.png",
        "images/vit6.png",
      ],
    },
    {
      "id": "khi_biet_sap_xep_do_choi",
      "ten": "Chú Khỉ Biết Sắp Xếp Đồ Chơi",
      "moTa": "Rèn luyện tính tự giác, ngăn nắp và gọn gàng sau khi chơi xong.",
      "icon": "🐒",
      "mau": Colors.deepOrange,
      "images": [
        "images/khi1.png",
        "images/khi2.png",
        "images/khi3.png",
        "images/khi4.png",
        "images/khi5.png",
        "images/khi6.png",
      ],
    },
    {
      "id": "meo_con_hoc_cach_trung_thuc",
      "ten": "Chú Mèo Con Học Cách Trung Thực",
      "moTa": "Bài học quý giá về việc luôn nói thật và nhận lỗi khi mắc sai lầm.",
      "icon": "🐱",
      "mau": Colors.purple,
      "images": [
        "images/meo1.png",
        "images/meo2.png",
        "images/meo3.png",
        "images/meo4.png",
        "images/meo5.png",
        "images/meo6.png",
        "images/meo7.png",
        "images/meo8.png",
      ],
    },
    {
      "id": "phiêu_lưu_cao_nho_se_chia",
      "ten": "Chuyến Phiêu Lưu Của Chú Cáo Nhỏ Học Cách Sẻ Chia",
      "moTa": "Khám phá thế giới và học cách chia sẻ yêu thương với mọi người.",
      "icon": "🦊",
      "mau": Colors.redAccent,
      "images": [
        "images/cao1.png",
        "images/cao2.png",
        "images/cao3.png",
        "images/cao4.png",
        "images/cao5.png",
        "images/cao6.png",
        "images/cao7.png",
        "images/cao8.png",
        "images/cao9.png",
        "images/cao10.png",
      ],
    },
    {
      "id": "vit_con_hoc_cach_giu_loi_hua",
      "ten": "Chú Vịt Con Học Cách Giữ Lời Hứa",
      "moTa": "Hiểu được tầm quan trọng của sự uy tín và giữ đúng lời hứa với bạn bè.",
      "icon": "🐤",
      "mau": Colors.green,
      "images": [
        "images/vitgiuloihua1.png",
        "images/vitgiuloihua2.png",
        "images/vitgiuloihua3.png",
        "images/vitgiuloihua4.png",
        "images/vitgiuloihua5.png",
        "images/vitgiuloihua6.png",
        "images/vitgiuloihua7.png",
        "images/vitgiuloihua8.png",
        "images/vitgiuloihua9.png",
        "images/vitgiuloihua10.png",
      ],
    },
    {
      "id": "chu_voi_con_hoc_cach_kien_nhan",
      "ten": "Chú Voi Con Học Cách Kiên Nhẫn",
      "moTa": "Học tính kiên nhẫn, không vội vàng trong mọi công việc hằng ngày.",
      "icon": "🐘",
      "mau": Colors.blueGrey,
      "images": [
        "images/voikiennhan1.png",
        "images/voikiennhan2.png",
        "images/voikiennhan3.png",
        "images/voikiennhan4.png",
        "images/voikiennhan5.png",
        "images/voikiennhan6.png",
        "images/voikiennhan7.png",
        "images/voikiennhan8.png",
        "images/voikiennhan9.png",
        "images/voikiennhan10.png",
      ],
    },
    {
      "id": "chu_khi_con_hoc_cach_chia_se_do_choi",
      "ten": "Chú Khỉ Con Học Cách Chia Sẻ Đồ Chơi",
      "moTa": "Hiểu được niềm vui khi biết chia sẻ đồ chơi cùng bạn bè.",
      "icon": "🐵",
      "mau": Colors.amberAccent,
      "images": [
        "images/khichiase1.png",
        "images/khichiase2.png",
        "images/khichiase3.png",
        "images/khichiase4.png",
        "images/khichiase5.png",
        "images/khichiase6.png",
        "images/khichiase7.png",
        "images/khichiase8.png",
        "images/khichiase9.png",
        "images/khichiase10.png",
      ],
    },
    {
      "id": "chu_tho_con_hoc_cach_lang_nghe_loi_khuyen",
      "ten": "Chú Thỏ Con Học Cách Lắng Nghe Lời Khuyên",
      "moTa": "Biết lắng nghe và tiếp thu những lời khuyên chân thành từ người lớn.",
      "icon": "🐰",
      "mau": Colors.pinkAccent,
      "images": [
        "images/tholangnghe1.png",
        "images/tholangnghe2.png",
        "images/tholangnghe3.png",
        "images/tholangnghe4.png",
        "images/tholangnghe5.png",
        "images/tholangnghe6.png",
        "images/tholangnghe7.png",
        "images/tholangnghe8.png",
        "images/tholangnghe9.png",
        "images/tholangnghe10.png",
      ],
    },
    {
    "id": "chu_cao_nho_va_bai_hoc_ve_su_cham_hoc",
    "ten": "Chú Cáo Nhỏ Và Bài Học Về Sự Chăm Học",
    "moTa": "Hiểu được tầm quan trọng của việc chăm chỉ học tập và không lười biếng.",
    "icon": "🦊",
    "mau": Colors.orangeAccent,
    "images": [
      "images/caohoc1.png",
      "images/caohoc2.png",
      "images/caohoc3.png",
      "images/caohoc4.png",
      "images/caohoc5.png",
      "images/caohoc6.png",
      "images/caohoc7.png",
      "images/caohoc8.png",
      "images/caohoc9.png",
      "images/caohoc10.png",
    ],
  },
  {
    "id": "rang_dep_nho_cham_danh_rang",
    "ten": "Răng Đẹp Nhờ Chăm Đánh Răng",
    "moTa": "Bài học thiết thực giúp bé hình thành thói quen vệ sinh răng miệng mỗi ngày.",
    "icon": "🦷",
    "mau": Colors.lightBlueAccent,
    "images": [
      "images/danhrang1.png",
      "images/danhrang2.png",
      "images/danhrang3.png",
      "images/danhrang4.png",
      "images/danhrang5.png",
      "images/danhrang6.png",
      "images/danhrang7.png",
      "images/danhrang8.png",
      "images/danhrang9.png",
      "images/danhrang10.png",
    ],
  },
  {
    "id": "voi_con_bo_bo_hoc_cach_binh_tinh",
    "ten": "Voi Con Bô Bô Học Cách Bình Tĩnh",
    "moTa": "Học cách kiềm chế cảm xúc, bình tĩnh xử lý mọi việc thay vì nóng vội.",
    "icon": "🐘",
    "mau": Colors.greenAccent,
    "images": [
      "images/binhtinh1.png",
      "images/binhtinh2.png",
      "images/binhtinh3.png",
      "images/binhtinh4.png",
      "images/binhtinh5.png",
      "images/binhtinh6.png",
      "images/binhtinh7.png",
      "images/binhtinh8.png",
      "images/binhtinh9.png",
      "images/binhtinh10.png",
    ],
  },
  {
    "id": "cuu_nho_va_long_trung_thuc",
    "ten": "Chú Cừu Nhỏ và Bài Học Về Lòng Trung Thực",
    "moTa": "Học cách luôn trung thực, nói sự thật và dũng cảm nhận lỗi khi làm sai.",
    "icon": "🐑",
    "mau": Colors.blueAccent,
    "images": [
      "images/cuunho1.png",
      "images/cuunho2.png",
      "images/cuunho3.png",
      "images/cuunho4.png",
      "images/cuunho5.png",
      "images/cuunho6.png",
      "images/cuunho7.png",
      "images/cuunho8.png",
      "images/cuunho9.png",
      "images/cuunho10.png",
    ],
  },
  {
    "id": "soc_nho_va_su_cham_chi",
    "ten": "Sóc Nhỏ và Bài Học Về Sự Chăm Chỉ & Chu Đáo",
    "moTa": "Hiểu được tầm quan trọng của việc chăm chỉ học tập, lao động và biết lắng nghe lời khuyên.",
    "icon": "🐿️",
    "mau": Colors.orangeAccent,
    "images": [
      "images/socnho1.png",
      "images/socnho2.png",
      "images/socnho3.png",
      "images/socnho4.png",
      "images/socnho5.png",
      "images/socnho6.png",
      "images/socnho7.png",
      "images/socnho8.png",
      "images/socnho9.png",
      "images/socnho10.png",
    ],
  },
  {
      "id": "cao_va_tho",
      "ten": "Cáo và Thỏ",
      "moTa": "Bài học về sự dũng cảm, lòng tốt cần tỉnh táo và tinh thần đoàn kết giúp đỡ bạn bè.",
      "icon": "🦊",
      "mau": Colors.orange,
      "images": [
        "images/caovatho1.png",
        "images/caovatho2.png",
        "images/caovatho3.png",
        "images/caovatho4.png",
        "images/caovatho5.png",
        "images/caovatho6.png",
        "images/caovatho7.png",
        "images/caovatho8.png",
        "images/caovatho9.png",
        "images/caovatho10.png",
        "images/caovatho11.png",
        "images/caovatho12.png"
      ]
    },
    {
      "id": "bo_xep_hinh_ky_dieu",
      "ten": "Bộ Xếp Hình Kỳ Diệu",
      "moTa": "Bài học về niềm vui khi chia sẻ đồ chơi, biết nhận lỗi, sửa lỗi và sức mạnh của sự đoàn kết.",
      "icon": "🧱",
      "mau": Colors.blue,
      "images": [
        "images/boxephinhkydieu1.png",
        "images/boxephinhkydieu2.png",
        "images/boxephinhkydieu3.png",
        "images/boxephinhkydieu4.png",
        "images/boxephinhkydieu5.png",
        "images/boxephinhkydieu6.png",
        "images/boxephinhkydieu7.png",
        "images/boxephinhkydieu8.png",
        "images/boxephinhkydieu9.png",
        "images/boxephinhkydieu10.png"
      ]
    },
    {
      "id": "ban_ho_con_le_phep",
      "ten": "Bạn Hổ Con Lễ Phép",
      "moTa": "Học hỏi những quy tắc chào hỏi và cách cư xử lễ phép khi sang nhà người lớn.",
      "icon": "🐯",
      "mau": Colors.orangeAccent,
      "images": [
        "images/holephep1.png",
        "images/holephep2.png",
        "images/holephep3.png",
        "images/holephep4.png",
        "images/holephep5.png",
        "images/holephep6.png",
        "images/holephep7.png",
        "images/holephep8.png",
        "images/holephep9.png",
        "images/holephep10.png",
        "images/holephep11.png",
        "images/holephep12.png",
      ],
    },
    {
      "id": "chiếc_bánh_kết_cục",
      "ten": "Chiếc Bánh Kết Cục",
      "moTa": "Hiểu được bài học quý giá về lòng trung thực và sự dũng cảm nhận lỗi.",
      "icon": "🐿️",
      "mau": Colors.brown,
      "images": [
        "images/chiecbanhketcuc1.png",
        "images/chiecbanhketcuc2.png",
        "images/chiecbanhketcuc3.png",
        "images/chiecbanhketcuc4.png",
        "images/chiecbanhketcuc5.png",
        "images/chiecbanhketcuc6.png",
        "images/chiecbanhketcuc7.png",
        "images/chiecbanhketcuc8.png",
        "images/chiecbanhketcuc9.png",
        "images/chiecbanhketcuc10.png",
        "images/chiecbanhketcuc11.png",
      ],
    },
    {
      "id": "hinh_dan_bi_mat",
      "ten": "Hình Dán Bí Mật",
      "moTa": "Bài học về sự trung thực, tôn trọng đồ dùng của người khác và dũng cảm nhận lỗi khi làm sai.",
      "icon": "🎨",
      "mau": Colors.orange,
      "images": [
        "images/hinhdanbimat1.png",
        "images/hinhdanbimat2.png",
        "images/hinhdanbimat3.png",
        "images/hinhdanbimat4.png",
        "images/hinhdanbimat5.png",
        "images/hinhdanbimat6.png",
        "images/hinhdanbimat7.png",
        "images/hinhdanbimat8.png",
        "images/hinhdanbimat9.png",
        "images/hinhdanbimat10.png",
        "images/hinhdanbimat11.png",
        "images/hinhdanbimat12.png"
      ],
    },
    {
      "id": "ga_con_nong_voi",
      "ten": "Bạn Gà Con Nóng Vội",
      "moTa": "Bài học về sự kiên nhẫn, bình tĩnh và biết nhờ sự giúp đỡ khi gặp khó khăn.",
      "icon": "🐥",
      "mau": Colors.yellow,
      "images": [
        "images/gaconnongvoi1.png",
        "images/gaconnongvoi2.png",
        "images/gaconnongvoi3.png",
        "images/gaconnongvoi4.png",
        "images/gaconnongvoi5.png",
        "images/gaconnongvoi6.png",
        "images/gaconnongvoi7.png",
        "images/gaconnongvoi8.png",
        "images/gaconnongvoi9.png",
        "images/gaconnongvoi10.png",
        "images/gaconnongvoi11.png",
        "images/gaconnongvoi12.png"
      ],
    },
    {
      "id": "chuyen_di_hai_qua",
      "ten": "Chuyến Đi Hái Quả Cừu Non",
      "moTa": "Bài học về việc vâng lời người lớn và tuân thủ các quy tắc an toàn.",
      "icon": "🐑",
      "mau": Colors.red,
      "images": [
        "images/cuunonhaiqua1.png",
        "images/cuunonhaiqua2.png",
        "images/cuunonhaiqua3.png",
        "images/cuunonhaiqua4.png",
        "images/cuunonhaiqua5.png",
        "images/cuunonhaiqua6.png",
        "images/cuunonhaiqua7.png",
        "images/cuunonhaiqua8.png",
        "images/cuunonhaiqua9.png",
        "images/cuunonhaiqua10.png",
        "images/cuunonhaiqua11.png"
      ],
    },
    {
      "id": "bi_mat_trong_hop_go",
      "ten": "Bí Mật Trong Hộp Gỗ",
      "moTa": "Bài học về việc lắng nghe lời dặn dò, tuân thủ quy tắc an toàn và không tò mò táy máy làm những việc nguy hiểm.",
      "icon": "🎁",
      "mau": Colors.brown,
      "images": [
        "images/bimattronghopgo1.png",
        "images/bimattronghopgo2.png",
        "images/bimattronghopgo3.png",
        "images/bimattronghopgo4.png",
        "images/bimattronghopgo5.png",
        "images/bimattronghopgo6.png",
        "images/bimattronghopgo7.png",
        "images/bimattronghopgo8.png",
        "images/bimattronghopgo9.png",
        "images/bimattronghopgo10.png",
        "images/bimattronghopgo11.png",
        "images/bimattronghopgo12.png"
      ],
    },
    {
    "id": "heo_nhan_loi",
    "ten": "Bạn Heo Con Biết Nhận Lỗi",
    "moTa": "Bài học về sự dũng cảm nhận lỗi và sửa sai sau khi làm hỏng đồ chơi của bạn.",
    "icon": "🐷",
    "mau": Colors.pinkAccent,
    "images": [
      "images/heonhanloi1.png",
      "images/heonhanloi2.png",
      "images/heonhanloi3.png",
      "images/heonhanloi4.png",
      "images/heonhanloi5.png",
      "images/heonhanloi6.png",
      "images/heonhanloi7.png",
      "images/heonhanloi8.png",
      "images/heonhanloi9.png",
      "images/heonhanloi10.png",
    ]
  },
  {
    "id": "hat_mam_ky_dieu",
    "ten": "Bạn Sóc Nhỏ Và Hạt Mầm Kỳ Diệu",
    "moTa": "Bài học về sự chăm chỉ, kiên trì chăm sóc mỗi ngày để gặt hái thành quả tốt đẹp.",
    "icon": "🌰",
    "mau": Colors.brown,
    "images": [
      "images/hatmamkydieu1.png",
      "images/hatmamkydieu2.png",
      "images/hatmamkydieu3.png",
      "images/hatmamkydieu4.png",
      "images/hatmamkydieu5.png",
      "images/hatmamkydieu6.png",
      "images/hatmamkydieu7.png",
      "images/hatmamkydieu8.png",
      "images/hatmamkydieu9.png",
      "images/hatmamkydieu10.png",
      "images/hatmamkydieu11.png"
    ]
  },
  {
    "id": "can_phong_gon_gang",
    "ten": "Căn Phòng Gọn Gàng Của Bạn Mèo",
    "moTa": "Bài học về việc tự giác dọn dẹp đồ chơi và giữ gìn sự gọn gàng, an toàn cho bản thân.",
    "icon": "🐱",
    "mau": Colors.blueAccent,
    "images": [
      "images/canphonggongang1.png",
      "images/canphonggongang2.png",
      "images/canphonggongang3.png",
      "images/canphonggongang4.png",
      "images/canphonggongang5.png",
      "images/canphonggongang6.png",
      "images/canphonggongang7.png",
      "images/canphonggongang8.png",
      "images/canphonggongang9.png",
      "images/canphonggongang10.png",
      "images/canphonggongang11.png"
    ]
  },
  {
    "id": "bao_luoi_an",
    "ten": "Bé Báo Lười Ăn",
    "moTa": "Bài học về việc chăm chỉ ăn uống, tập thể dục và giữ gìn sức khỏe cho bản thân.",
    "icon": "🐆",
    "mau": Colors.orangeAccent,
    "images": [
      "images/baoluoian1.png",
      "images/baoluoian2.png",
      "images/baoluoian3.png",
      "images/baoluoian4.png",
      "images/baoluoian5.png",
      "images/baoluoian6.png",
      "images/baoluoian7.png",
      "images/baoluoian8.png",
      "images/baoluoian9.png"
    ]
  },
  {
    "id": "mon_qua_cua_loi_cam_on",
    "ten": "Món Quà Của Lời Cảm Ơn",
    "moTa": "Bài học về sự lễ phép, biết nói lời cảm ơn chân thành khi nhận được sự giúp đỡ hoặc món quà từ người khác.",
    "icon": "🎁",
    "mau": Colors.pinkAccent,
    "images": [
      "images/monquacualoicamon1.png",
      "images/monquacualoicamon2.png",
      "images/monquacualoicamon3.png",
      "images/monquacualoicamon4.png",
      "images/monquacualoicamon5.png",
      "images/monquacualoicamon6.png",
      "images/monquacualoicamon7.png",
      "images/monquacualoicamon8.png",
      "images/monquacualoicamon9.png",
      "images/monquacualoicamon10.png",
      "images/monquacualoicamon11.png"
    ]
  },
  {
    "id": "su_tu_mo_mong",
    "ten": "Bạn Sư Tử Nhỏ Hay Mơ Mộng",
    "moTa": "Bài học về sự tập trung chú ý và kiên nhẫn đến cùng khi làm việc để đạt kết quả tuyệt vời.",
    "icon": "🦁",
    "mau": Colors.amberAccent,
    "images": [
      "images/sutumomong1.png",
      "images/sutumomong2.png",
      "images/sutumomong3.png",
      "images/sutumomong4.png",
      "images/sutumomong5.png",
      "images/sutumomong6.png",
      "images/sutumomong7.png",
      "images/sutumomong8.png",
      "images/sutumomong9.png",
      "images/sutumomong10.png",
      "images/sutumomong11.png"
    ]
  },
  {
    "id": "hamadoanket",
    "ten": "Bức Tranh Đoàn Kết Của Hai Anh Em Hà Mã",
    "moTa": "Bài học về sự đoàn kết, yêu thương, san sẻ và nhường nhịn lẫn nhau giữa anh chị em trong gia đình.",
    "icon": "🦛",
    "mau": Colors.purpleAccent,
    "images": [
      "images/hamadoanket1.png",
      "images/hamadoanket2.png",
      "images/hamadoanket3.png",
      "images/hamadoanket4.png",
      "images/hamadoanket5.png",
      "images/hamadoanket6.png",
      "images/hamadoanket7.png",
      "images/hamadoanket8.png",
      "images/hamadoanket9.png",
      "images/hamadoanket10.png",
      "images/hamadoanket11.png"
    ]
  },
  ];
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        toolbarHeight: 40,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text(
          "Góc Truyện Tranh Cho Bé",
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(200, 32, 178, 170),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView.builder(
          itemCount: danhSachTruyen.length,
          itemBuilder: (context, index) {
            final truyen = danhSachTruyen[index];
            Color mau = truyen["mau"];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrangDocChiTietTruyen(
                      tenTruyen: truyen["ten"],
                      danhSachAnh: List<String>.from(truyen["images"]),
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: mau, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: mau.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(truyen["icon"], style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            truyen["ten"],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mau),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            truyen["moTa"],
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: mau, size: 18),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
// 2. MÀN HÌNH ĐỌC TRUYỆN TRANH CHI TIẾT (LẬT NGANG XEM ẢNH FULLSCREEN)
class TrangDocChiTietTruyen extends StatefulWidget {
  final String tenTruyen;
  final List<String> danhSachAnh;
  const TrangDocChiTietTruyen({
    Key? key,
    required this.tenTruyen,
    required this.danhSachAnh,
  }) : super(key: key);
  @override
  State<TrangDocChiTietTruyen> createState() => _TrangDocChiTietTruyenState();
}

//TRUYỆN CHỮ
class _TrangDocChiTietTruyenState extends State<TrangDocChiTietTruyen> {
  final PageController _pageController = PageController();
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. PageView hiển thị ảnh full màn hình
          PageView.builder(
            controller: _pageController,
            itemCount: widget.danhSachAnh.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: Image.asset(
            widget.danhSachAnh[index],
            fit: BoxFit.fill, // Dùng fill để ảnh co giãn vừa khít toàn bộ màn hình, triệt tiêu hoàn toàn viền đen 2 bên
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  "Không tìm thấy ảnh: ${widget.danhSachAnh[index]}",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          // 2. Nút quay lại nổi ở góc trên bên trái
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            child: _nutQuayLaiChuan(context),
          ),
        ],
      ),
    );
  }
}
// 3. MÀN HÌNH DANH SÁCH TRUYỆN CHỮ & ÂM THANH MP3
class TrangTruyenChu extends StatelessWidget {
  const TrangTruyenChu({Key? key}) : super(key: key);
  // Danh sách truyện có gắn kèm file MP3 trong thư mục assets/audios/
  final List<Map<String, String>> danhSachTruyenChu = const [
    {
    "ten": "Cáo Và Thỏ",
    "moTa": "Câu chuyện cổ tích quen thuộc về chú Gà Trống dũng cảm giúp Thỏ đòi lại ngôi nhà.",
    "icon": "🦊",
    "audioPath": "audios/caovatho.mp3",
    "noiDung":
        "Ngày xửa ngày xưa, trong một khu rừng xanh tươi có con Cáo và con Thỏ. "
        "Cáo có một ngôi nhà làm bằng băng, còn Thỏ thì có một ngôi nhà làm bằng gỗ. "
        "Mùa xuân đến, ngôi nhà bằng băng của Cáo tan ra thành nước. Cáo liền sang nhà Thỏ xin tạm trú và sưởi ấm. "
        "Nhưng sau đó Cáo lại nổi lòng tham, đuổi Thỏ ra khỏi ngôi nhà gỗ. "
        "Thỏ rất buồn và vừa đi vừa khóc. Thỏ gặp chú Chó, gặp Bác Gấu nhưng ai cũng sợ Cáo hung dữ. "
        "Cuối cùng, Thỏ gặp chú Gà Trống dũng cảm vác hái trên vai. Gà Trống dũng mãnh cất tiếng hát khiêu chiến làm Cáo sợ hãi chạy mất. "
        "Thỏ lấy lại được căn nhà gỗ và sống hạnh phúc mãi mãi."
  },
  {
    "ten": "Hạt Giống Của Sự Trung Thực",
    "moTa": "Bài học quý giá về lòng trung thực luôn cao quý hơn mọi thành tích dối trá.",
    "icon": "🌱",
    "audioPath": "audios/hatgiongcuasutrungthuc.mp3",
    "noiDung":
        "Ngày xưa, ở một vương quốc nọ, vị vua già muốn tìm một người nối ngôi thật thà. Nhà vua phát cho mỗi em nhỏ trong làng một hạt giống hoa và dặn: "
        "– 'Ai trồng được chậu hoa đẹp nhất sau một năm sẽ là người nối ngôi ta.'\n"
        "Bé Chột háo hức mang hạt giống về, siêng năng tưới nước, xới đất mỗi ngày. Nhưng kỳ lạ thay, dù em chăm sóc kỹ đến đâu, hạt giống vẫn không chịu nảy mầm. Trong khi đó, các bạn xung quanh ai cũng tự hào khoe chậu hoa của mình đã ra những bông hoa rực rỡ sắc màu.\n"
        "Đến ngày hẹn, các bạn nhỏ mang những chậu hoa rực rỡ đến cung điện. Chỉ riêng Chột mang đến một chậu đất trống rỗng và bật khóc vì buồn bã.\n"
        "Nhà vua đi qua từng chậu hoa, mặt trầm ngâm. Đến khi dừng lại trước chậu đất của Chột, ngài mỉm cười hỏi nguyên do. Chột sụt sùi kể lại toàn bộ quá trình chăm sóc của mình. Lúc này, nhà vua dắt tay Chột lên ngai vàng và dâng cao chậu đất trống: "
        "– 'Tất cả hạt giống ta phát năm ngoái đều đã được luộc chín, không thể nào nảy mầm. Những chậu hoa rực rỡ kia là do sự gian dối. Chỉ có lòng trung thực của cậu bé này mới trồng được bông hoa quý giá nhất – bông hoa của sự thật.'\n"
        "Bài học cho bé: Lòng trung thực luôn quý giá hơn mọi thành tích dối trá. Hãy luôn dũng cảm nói sự thật, dù kết quả có ra sao."
  },
  {
    "ten": "Chú Thỏ Và Chiếc Ô Kỳ Diệu",
    "moTa": "Câu chuyện ấm áp về tình bạn và sự sẻ chia lúc khó khăn.",
    "icon": "☂️",
    "audioPath": "audios/chuthovachiecokydieu.mp3",
    "noiDung":
        "Trong khu rừng xanh, Thỏ Con có một chiếc ô màu vàng rất đẹp. Một ngày nọ, trời đổ mưa to. Thỏ Con nhanh chóng giương ô chạy về nhà.\n"
        "Trên đường đi, Thỏ thấy Nhím Thỏm đang run cầm cập dưới gốc cây vì ướt nhẹp. Thỏ Con không ngần ngại vẫy tay: "
        "– 'Nhím ơi, lại đây trú mưa cùng tớ nhé!'\n"
        "Một lúc sau, Thỏ lại gặp Sóc Nhỏ đang ôm chùm quả mọng loay hoay tìm chỗ trốn. Thỏ Con lại gọi: "
        "– 'Sóc ơi, vào đây cùng trú cho khỏi hỏng quả nhé!'\n"
        "Chiếc ô vốn nhỏ, nhưng khi ba bạn cùng đứng sát vào nhau, ôm chặt lấy nhau ấm áp, kỳ diệu thay, chiếc ô dường như xòe rộng ra vừa đủ che chở cho cả ba. Khi mưa tạnh, mặt trời hé rạng, ba bạn nhỏ cùng vui đùa và chia sẻ chùm quả mọng ngọt ngào.\n"
        "Bài học cho bé: Khi chúng ta biết sẻ chia và giúp đỡ bạn bè, niềm vui và tình yêu thương sẽ tự lan tỏa rộng lớn hơn, giống như chiếc ô kỳ diệu vậy."
  },
  {
    "ten": "Cây Sồi Nhỏ Và Cơn Bão",
    "moTa": "Học cách linh hoạt, nhẫn nại và kiên trì sẽ giúp vượt qua mọi khó khăn.",
    "icon": "🌳",
    "audioPath": "audios/caysoivaconbao.mp3",
    "noiDung":
        "Trong một khu rừng già, có một cây Sồi Nhỏ sống bên cạnh một cây Cổ Thụ to lớn, cành lá sum sê. Cây Sồi Nhỏ luôn tự ti vì thân mình mảnh dẻ, không thể che bóng mát rộng lớn như cây Cổ Thụ.\n"
        "Một đêm nọ, trận bão lớn nhất trong năm ập đến. Gió rít gào cuồng xé. Cây Cổ Thụ vì quá to lớn, thân cứng gồng mình chống lại sức gió nên cuối cùng bị gãy đôi cành lớn. Trong khi đó, Cây Sồi Nhỏ với thân mình dẻo dai biết nghiêng mình nương theo chiều gió.\n"
        "Sáng hôm sau, bão qua đi. Cây Sồi Nhỏ tuy mất vài chiếc lá nhưng vẫn đứng vững vàng. Cây Cổ Thụ mỉm cười nói với Sồi Nhỏ: "
        "– 'Cháu thấy không, sự dẻo dai và biết thích nghi đôi khi còn mạnh mẽ hơn cả sức mạnh thô ráp.'\n"
        "Bài học cho bé: Mỗi người đều có thế mạnh riêng. Học cách linh hoạt, nhẫn nại và kiên trì sẽ giúp con vượt qua mọi khó khăn trong cuộc sống."
  },
  {
    "ten": "Chiếc Áo Ấm Của Sóc Mẹ",
    "moTa": "Tình yêu thương vô bờ bến của cha mẹ dành cho con cái.",
    "icon": "🧶",
    "audioPath": "audios/chiecaoamapcuasocme.mp3",
    "noiDung":
        "Mùa đông lạnh giá tràn về khu rừng. Sóc Mẹ cùng Sóc Con cuộn tròn trong tổ chim câu cũ. Thấy Sóc Con run lên vì rét, Sóc Mẹ liền cởi chiếc áo bông duy nhất của mình đắp cho con.\n"
        "Mỗi khi gió bắc thổi qua kẽ lá, Sóc Mẹ lại xuýt xoa, nhưng nhìn thấy Sóc Con ngủ ngon lành và ấm áp, lòng Sóc Mẹ lại thấy ấm áp lạ kỳ. Sáng hôm sau, khi thức dậy, Sóc Con thấy mẹ bị sốt nhẹ. Sóc Con hiểu ra mọi chuyện, liền ôm lấy mẹ và đắp lại chiếc áo cho mẹ.\n"
        "Đúng lúc đó, các bạn chim sẻ, thỏ trắng biết chuyện đã mang đến nhiều lá khô mềm và lông vũ mịn để lót thêm cho tổ của hai mẹ con. Tổ nhỏ bỗng trở nên vô cùng ấm áp. Sóc Con nắm tay mẹ và nói: "
        "– Mẹ ơi, tình yêu của mẹ là chiếc áo ấm nhất đời con!\n"
        "Bài học cho bé: Tình yêu thương của cha mẹ dành cho con cái là vô bờ bến. Con hãy luôn biết yêu thương, chăm sóc và trân trọng cha mẹ của mình nhé."
  },
  {
    "ten": "Rùa Con Học Vẽ Bầu Trời",
    "moTa": "Đừng lo lắng nếu đi chậm, sự kiên trì sẽ mang lại kết quả tuyệt vời.",
    "icon": "🐢",
    "audioPath": "audios/ruaconhocvebautroi.mp3",
    "noiDung":
        "Rùa Con rất thích vẽ, nhưng tay chân cậu chậm chạp nên vẽ một bức tranh mất rất nhiều thời gian. Các bạn Chim Thông, Thỏ Rừng thường trêu đùa: "
        "– Rùa ơi, cậu vẽ chậm thế này thì bao giờ mới xong bầu trời rộng lớn?\n"
        "Rùa Con không nản lòng. Cậu tỉ mẩn vẽ từng đám mây, từng vệt nắng vàng qua từng ngày một. Trong khi các bạn khác mải mê chạy nhảy rồi bỏ dở những bức vẽ của mình, thì Rùa Con vẫn kiên trì từng chút một dưới gốc cây.\n"
        "Sau một tháng, Rùa Con hoàn thành bức tranh. Khi cậu mở bức tranh ra, tất cả các bạn trong rừng đều phải trầm trồ: Bầu trời của Rùa Con sống động, rực rỡ và chi tiết đến kỳ diệu, có cả ánh hoàng hôn tuyệt đẹp mà chưa ai từng vẽ được.\n"
        "Bài học cho bé: Đừng lo lắng nếu mình làm chậm hơn người khác. Chỉ cần con kiên trì, không bỏ cuộc và làm hết sức mình, con sẽ đạt được kết quả tuyệt vời nhất."
  },
  {
    "ten": "Bông Hoa Biết Nói Lời Cảm Ơn",
    "moTa": "Hãy luôn biết ơn và ghi nhớ sự giúp đỡ của những người bạn tốt.",
    "icon": "🌸",
    "audioPath": "audios/bonghoabietnoiloicamon.mp3",
    "noiDung":
        "Trong một khu vườn nhỏ, có một bông hoa Hồng Đỏ sắp bị héo rũ vì nắng gắt. Thấy vậy, chú Chú Ong Vàng siêng năng đã bay đi tìm những giọt sương đêm còn sót lại trên kẽ lá để mang về tưới cho hoa.\n"
        "Nhờ có những giọt nước mát lành của Ong Vàng, hoa Hồng Đỏ tươi tỉnh trở lại và xòe nở những cánh hoa rực rỡ. Để thể hiện lòng biết ơn, mỗi sáng sớm, hoa Hồng Đỏ lại đọng lại những giọt mật ngọt ngào nhất để tặng riêng cho Ong Vàng.\n"
        "Cả hai trở thành đôi bạn thân thiết, luôn giúp đỡ và dành những điều tốt đẹp nhất cho nhau suốt cả mùa hè.\n"
        "Bài học cho bé: Hãy luôn biết nói lời cảm ơn và ghi nhớ sự giúp đỡ của người khác. Lòng biết ơn sẽ giúp con có thêm những người bạn tốt và cuộc sống luôn tràn ngập niềm vui."
  },
  {
    "ten": "Chú Cáo Nhỏ Học Cách Tự Lập",
    "moTa": "Tự lập giúp con trưởng thành, dũng cảm và mạnh mẽ hơn mỗi ngày.",
    "icon": "🦊",
    "audioPath": "audios/chucaonhohoccachtulap.mp3",
    "noiDung":
        "Trong hang đá nhỏ, Cáo Nhỏ sống cùng mẹ và luôn được mẹ chuẩn bị sẵn thức ăn mỗi ngày. Một buổi sáng, Cáo Mẹ bị mệt và không thể ra ngoài. Cáo Nhỏ cảm thấy bụng đói cồn cào.\n"
        "Cáo Mẹ nhẹ nhàng nói: "
        "– Hôm nay con đã lớn rồi, hãy tự mình vào rừng tìm quả ngọt nhé.\n"
        "Ban đầu, Cáo Nhỏ rất sợ hãi và lo lắng. Khi bước vào rừng, chú vấp phải rễ cây, tìm nhầm quả chát. Nhưng chú không bỏ cuộc mà nhớ lại những lời mẹ dạy, cẩn thận quan sát các bạn chim tìm quả chín. Sau một hồi nỗ lực, Cáo Nhỏ đã hái được một giỏ quả chín mọng ngọt ngào mang về cho mẹ.\n"
        "Nhìn mẹ mỉm cười tự hào, Cáo Nhỏ nhận ra rằng tự mình làm được công việc không hề đáng sợ mà còn mang lại cảm giác rất tuyệt vời.\n"
        "Bài học cho bé: Tự lập và tự làm những việc nhỏ của mình sẽ giúp con trưởng thành, dũng cảm và mạnh mẽ hơn mỗi ngày."
  },
  {
    "ten": "Bài Học Của Chim Công Tự Phụ",
    "moTa": "Đừng bao giờ kiêu ngạo, vẻ đẹp nội tâm và lòng tốt mới là điều quan trọng.",
    "icon": "🦚",
    "audioPath": "audios/baihoccuachimcongtuphu.mp3",
    "noiDung":
        "Trong khu rừng ngát hương, Chim Công sở hữu bộ lông vô cùng rực rỡ. Công rất tự hào về vẻ đẹp của mình nên đi đâu cũng xòe đuôi khoe khoang và chê bai bộ lông xám xịt của Họa Mi.\n"
        "Một ngày nọ, một con Cáo hung dữ xuất hiện. Chim Công vì mải xòe bộ đuôi xòe xòa, nặng nề nên vướng vào bụi gai, không thể bay lên cây được. Thấy vậy, Họa Mi từ trên cành cao liền cất tiếng hót thật to và chuyền cành liên tục để đánh lạc hướng con Cáo, giúp Công có thời gian gỡ đuôi ra và trốn thoát.\n"
        "Khi nguy hiểm qua đi, Công xấu hổ xin lỗi Họa Mi vì đã từng xem thường bạn. Công hiểu ra rằng vẻ đẹp bên ngoài không quan trọng bằng tấm lòng tốt bụng và sự dũng cảm bên trong.\n"
        "Bài học cho bé: Mỗi người đều có điểm mạnh riêng. Đừng bao giờ kiêu ngạo hay coi thường người khác, mà hãy biết trân trọng và yêu thương bạn bè."
  },
  {
    "ten": "Sức Mạnh Của Sự Hợp Tác",
    "moTa": "Đoàn kết và hợp tác cùng nhau giúp vượt qua mọi khó khăn thử thách.",
    "icon": "🐜",
    "audioPath": "audios/sucmanhcuasuhoptac.mp3",
    "noiDung":
        "Mùa thu đến, gia đình nhà Kiến cần chuyển một hạt đậu rất to về tổ để tích trữ cho mùa đông. Kiến Anh cố sức đẩy nhưng hạt đậu quá nặng, không nhúc nhích. Kiến Em chạy đến giúp đẩy cùng, nhưng hạt đậu vẫn nằm yên trên mặt đất.\n"
        "Kiến Anh liền bò về tổ, cất tiếng gọi các bạn Kiến khác. Chẳng mấy chốc, một đàn Kiến đông đúc cùng nắm tay nhau, người đẩy phía sau, người kéo phía trước. Bằng sự nhịp nhàng và đồng lòng, hạt đậu to lớn đã được đưa về tổ an toàn trước khi cơn mưa rào ập đến.\n"
        "Tối hôm đó, cả gia đình nhà Kiến cùng quây quần bên hạt đậu thơm ngon và ăn mừng thành quả của cả tập thể.\n"
        "Bài học cho bé: Khi gặp việc khó khăn, nếu chúng ta biết đoàn kết và hợp tác cùng nhau thì mọi việc đều có thể hoàn thành dễ dàng."
  },
  {
    "ten": "Chú Thỏ Và Lòng Kiên Nhẫn",
    "moTa": "Kiên nhẫn là chìa khóa của thành công, không thể vội vàng mà có ngay được.",
    "icon": "🐇",
    "audioPath": "audios/chuthovalongkiennhan.mp3",
    "noiDung":
        "Thỏ Nâu rất muốn trồng được một cây củ cải đường thật to. Cậu gieo hạt xuống đất rồi cứ mỗi 10 phút lại chạy ra xới đất lên xem hạt đã nảy mầm chưa.\n"
        "Mèo Khoang thấy vậy liền bảo: "
        "– 'Thỏ Nâu ơi, hạt giống cần thời gian uống nước, tắm nắng và ngủ dưới đất ấm. Cậu cứ bới lên mãi thì làm sao cây lớn được?'\n"
        "Thỏ Nâu hiểu ra, cậu kiên nhẫn tưới nước mỗi sáng và nhẫn nại chờ đợi. Nhiều tuần trôi qua, từ mầm xanh nhỏ bé, một củ cải đường đỏ rực, to béo đã lớn lên trong sự reo hò hạnh phúc của Thỏ Nâu.\n"
        "Bài học cho bé: Lòng kiên nhẫn là chìa khóa của thành công. Có những việc cần thời gian và sự chăm chỉ, không thể vội vàng mà có kết quả ngay được."
  },
  {
    "ten": "Bài Học Của Dế Mèn Thích Khoe Khoang",
    "moTa": "Hãy biết lắng nghe và tôn trọng không gian của người xung quanh.",
    "icon": "🦗",
    "audioPath": "audios/baihoccuadementhichkhoekhoang.mp3",
    "noiDung":
        "Dế Mèn có một đôi càng đen bóng và tiếng gáy rất vang. Cậu luôn tự hào gáy thật to suốt cả ngày để mọi người phải chú ý đến mình, mặc cho bác Cú Gai đang cần ngủ ngày hay bạn Sâu Nhỏ đang giấu mình tránh kẻ thù.\n"
        "Một buổi chiều, tiếng gáy quá to của Dế Mèn đã thu hút một chú Chim Trĩ đói bụng. Chim Trĩ lao xuống định bắt Dế Mèn. May mắn thay, bạn Bọ Rùa đã kịp thời kéo Dế Mèn chui vào kẽ đá hẹp trốn thoát.\n"
        "Từ đó, Dế Mèn không còn gáy vô cớ để khoe khoang nữa. Cậu chỉ cất tiếng hát êm dịu vào những buổi tối mát trời để làm vui lòng xóm giềng.\n"
        "Bài học cho bé: Hãy biết lắng nghe và tôn trọng không gian của người xung quanh. Khoe khoang không đúng lúc có thể gây ra rắc rối cho chính mình."
  },
  {
    "ten": "Ngôi Nhà Bằng Rơm Và Lòng Tốt",
    "moTa": "Tấm lòng nhân ái, sẵn sàng sẻ chia khi người khác gặp khó khăn là điều quý giá.",
    "icon": "🏠",
    "audioPath": "audios/ngoinhabangromvalongtot.mp3",
    "noiDung":
        "Trong rừng có một cơn mưa tuyết đầu mùa rất lạnh. Chú Chuột Đồng nhỏ không có nhà, run rẩy gõ cửa nhà các bạn. Con Cáo từ chối vì sợ bẩn nhà, Cú Xám lắc đầu vì sợ làm phiền.\n"
        "Đến nhà Bạn Thỏ Xám, dù ngôi nhà bằng rơm của Thỏ rất nhỏ, Thỏ vẫn vui vẻ mở rộng cửa: "
        "– 'Vào đây đi bạn, nhà tớ không rộng nhưng đủ ấm cho cả hai chúng ta!'\n"
        "Thỏ chia sẻ từng chút củi khô và củ khoai nướng cho Chuột Đồng. Kỳ diệu thay, lòng tốt và hơi ấm của hai bạn nhỏ đã làm cho ngôi nhà rơm bé nhỏ trở nên ấm áp nhất cả khu rừng trong suốt mùa đông.\n"
        "Bài học cho bé: Tấm lòng nhân ái, sẵn sàng sẻ chia khi người khác gặp khó khăn chính là điều ấm áp và quý giá nhất."
  },
  {
    "ten": "Chú Chim Nhỏ Tìm Giọng Hát",
    "moTa": "Mỗi bé là một cá thể đặc biệt, đừng tự ti so sánh mình với người khác.",
    "icon": "🐦",
    "audioPath": "audios/chuchimnhotimgionghat.mp3",
    "noiDung":
        "Chú Chim Sâu sinh ra có giọng hót không trong trẻo bằng Sơn Ca, cũng không hót được nhiều giai điệu như Họa Mi. Chim Sâu buồn rầu, suốt ngày giấu mình trong kẽ lá không chịu cất tiếng.\n"
        "Một ngày nọ, khi bác Nông Dân đang lo lắng vì sâu phá hoại vườn rau, Chim Sâu đã chăm chỉ chuyền từ cành này sang cành khác bắt sạch sâu bọ. Khi công việc hoàn thành, Chim Sâu cất tiếng hát 'Líp chíp! Líp chíp!' giản dị để ăn mừng.\n"
        "Bác Nông Dân cùng các bạn nhỏ vỗ tay khen ngợi: 'Tiếng hót của Chim Sâu thật chăm chỉ và đáng yêu làm sao!'. Chim Sâu nhận ra tiếng hót của mình dù đơn sơ nhưng vẫn mang lại niềm vui cho mọi người.\n"
        "Bài học cho bé: Mỗi em bé đều là một cá thể duy nhất và đặc biệt. Đừng tự ti so sánh mình với người khác, hãy luôn tự tin thể hiện giá trị riêng của bản thân."
  },
  {
    "ten": "Bánh Mì Chia Đôi",
    "moTa": "Anh chị em trong gia đình cần biết nhường nhịn, yêu thương và sẻ chia.",
    "icon": "🍞",
    "audioPath": "audios/banhmichiadoi.mp3",
    "noiDung":
        "Hai anh em nhà Gấu Bông nhặt được một ổ bánh mì thơm phức ngoài đồng. Gấu Anh muốn phần to hơn vì mình lớn hơn, Gấu Em cũng muốn phần to vì mình nhỏ hơn cần ăn nhiều. Cả hai tranh giành làm ổ bánh mì rơi xuống đất.\n"
        "Lúc đó, Mèo Nhỏ đi qua nhẹ nhàng bảo: "
        "– 'Sao hai anh em không bẻ đôi ra, bạn nào ăn xong trước thì lần sau sẽ nhường bạn kia một chút?'\n"
        "Nghe lời Mèo Nhỏ, hai anh em bẻ đôi ổ bánh mì. Khi ăn cùng nhau, hai chú Gấu nhận ra bánh mì ngọt ngào hơn rất nhiều so với lúc cãi nhau. Cả hai ôm lấy nhau và hứa sẽ luôn nhường nhịn nhau từ nay về sau.\n"
        "Bài học cho bé: Anh chị em trong gia đình cần biết nhường nhịn, yêu thương và sẻ chia với nhau để nhà cửa luôn ngập tràn tiếng cười."
  },
  {
    "ten": "Hành Trình Đến Thung Lũng Trăng Sao",
    "moTa": "Lòng dũng cảm và sự tốt bụng giúp con vượt qua mọi nỗi sợ hãi.",
    "icon": "✨",
    "audioPath": "audios/hanhtrinhdenthunglungtrangsao.mp3",
    "noiDung":
        "Ngày xửa ngày xưa, ở ven một khu rừng ngát hương hoa lavender, có một chú Thỏ Bông nhỏ tên là Bơ. Bơ sống cùng bà trong một ngôi nhà gỗ ấm áp. Bơ rất thích ngắm bầu trời đêm, đặc biệt là những đêm trăng tròn sáng vạch qua vòm lá.\n"
        "Một buổi tối mùa thu, Bơ nhìn lên bầu trời và bỗng nhận ra Trăng Sao đêm nay thật mờ nhạt. Cả bầu trời như bị bao phủ bởi một lớp sương mù xám xịt. Đêm đó, một chú Đom Đóm Cụ lập lòe bay vào cửa sổ nhà Bơ, giọng thều thào:\n"
        "– 'Bơ ơi! Bông Hoa Ánh Sáng trên ngọn núi Mây Mờ đang bị héo hon. Nếu hoa tàn, trăng sao sẽ mất đi ánh sáng và khu rừng chúng ta sẽ chìm trong bóng tối vĩnh viễn.'\n"
        "Dù rất sợ đêm tối, Bơ vẫn quyết định đeo chiếc ba lô nhỏ, mang theo một bình nước mát và vài củ măng khô rồi lên đường.\n"
        "Trên đường đi, Bơ gặp bạn Rùa Con đang bị mắc kẹt dưới một cành cây gãy. Dù đang rất vội, Bơ vẫn dừng lại, dùng hết sức bình sinh đòn bẩy cành cây để cứu Rùa. Rùa Con cảm kích tặng Bơ một chiếc vỏ ốc thần: 'Khi nào gặp nguy hiểm, cậu hãy thổi chiếc ốc này nhé!'\n"
        "Đi tiếp vào sâu trong rừng thẳm, đường đi tối om và đầy gai góc. Bơ vừa đi vừa run, chân bị gai cào rát. Nhưng mỗi khi định quay đầu, chú lại nhớ đến lời dặn của bà về lòng dũng cảm. Đột nhiên, một con Cú Xám to lớn sà xuống chặn đường, đôi mắt đỏ ngầu. Bơ nhanh trí nhớ đến chiếc vỏ ốc, chú thổi một hơi thật mạnh. Âm thanh trong trẻo, vang dội của vỏ ốc vang lên khiến Cú Xám giật mình hoảng sợ bay mất.\n\n"
        "Cuối cùng, Bơ cũng leo lên đến đỉnh núi Mây Mờ. Bông Hoa Ánh Sáng lúc này chỉ còn lại một cánh hoa khép hờ, rũ rượi. Bơ nhanh chóng lấy bình nước mát mang theo tưới nhẹ lên gốc hoa và nhẹ nhàng cất tiếng hát ru mà bà vẫn thường hát cho chú nghe mỗi tối.\n"
        "Kỳ diệu thay! Nhờ giọt nước mát lành cùng tình yêu thương chân thành, Bông Hoa Ánh Sáng từ từ xòe nở, tỏa ra ánh hào quang vàng rực rỡ chiếu sáng khắp non trung. Bầu trời đêm bừng sáng trở lại, những ngôi sao lấp lánh như đang mỉm cười với Bơ.\n"
        "Khi Bơ trở về nhà, cả khu rừng đã đón mừng chú như một anh hùng nhỏ tuổi. Bơ ôm chầm lấy bà và hiểu rằng: Dũng cảm không phải là không biết sợ, mà là vẫn tiếp tục bước đi ngay cả khi lòng đầy sợ hãi.\n"
        "Bài học cho bé: Lòng dũng cảm, sự tốt bụng và tinh thần không bỏ cuộc sẽ giúp con vượt qua mọi nỗi sợ hãi để mang lại điều tốt đẹp cho bản thân và mọi người."
  },
  {
    "ten": "Chú Rồng Nhỏ Không Biết Phun Lửa",
    "moTa": "Mỗi người sinh ra đều có nét đặc biệt riêng, hãy tự tin vào chính mình.",
    "icon": "🐉",
    "audioPath": "audios/churongnhokhongbietphunlua.mp3",
    "noiDung":
        "Tại một thung lũng cao chót vót mây giăng, có một gia đình Rồng sinh sống. Các anh chị của Rồng Nhỏ Téppi đều có thể phun ra những dòng lửa đỏ rực rỡ để sưởi ấm hang đá hay nướng chín thức ăn. Thế nhưng Téppi lại rất đặc biệt: Mỗi khi chú há miệng cố gắng phun lửa, chỉ có những làn hơi nước mát lạnh và những bong bóng xà phòng phồng bay ra.\n"
        "Các bạn Rồng trong làng thường trêu chọc Téppi:\n"
        "– 'Rồng mà không biết phun lửa thì làm sao bảo vệ được vương quốc?'\n"
        "Téppi buồn lắm. Chú thường ngồi một mình bên bờ suối, nhìn bóng mình dưới nước và tự hỏi tại sao mình lại khác biệt với mọi người như vậy.\n"
        "Mùa đông năm đó tràn về, một cơn bão tuyết chưa từng có tàn phá thung lũng. Băng giá bao phủ khắp nơi, dập tắt tất cả các ngọn lửa. Các con Rồng lớn cố gắng phun lửa nhưng không khí quá khô và lạnh khiến cổ họng chúng bị đau rát, không thể tạo ra dù chỉ một đốm lửa nhỏ. Cả vương quốc Rồng bắt đầu run rẩy vì rét và nguy cơ bị đóng băng.\n"
        "Đúng lúc đó, mầm bệnh khô hạn bùng phát khiến các loài cây cối sưởi ấm bị héo khô. Téppi nhận ra mình phải làm gì đó. Chú bay đến từng khu vườn, há miệng và thổi ra những làn hơi nước mát lành, đong đầy dưỡng chất. Hơi nước của Téppi làm tan chảy băng giá một cách nhẹ nhàng, tưới mát cho cây cối bừng tỉnh sống lại.\n"
        "Chưa dừng lại ở đó, Téppi dùng những bong bóng khí kỳ diệu của mình bao bọc lấy các em rồng nhỏ, giữ cho hơi ấm bên trong không bị thoát ra ngoài.\n"
        "Nhờ có Téppi, cả thung lũng Rồng đã vượt qua trận bão tuyết khắc nghiệt an toàn. Vua Rồng tự tay trao cho Téppi chiếc vương miện kết bằng hoa tuyết và dâng lời khen ngợi trước toàn thể dân làng:\n"
        "– 'Téppi không phun ra lửa, nhưng chú sở hữu dòng nước của sự sống và trái tim ấm áp nhất thung lũng này!'\n"
        "Từ đó về sau, Téppi không còn tự ti về bản thân nữa. Chú tự hào vì sự khác biệt của mình đã mang lại sự sống và hạnh phúc cho gia đình.\n"
        "Bài học cho bé: Mỗi chúng ta sinh ra đều có những nét đặc biệt riêng. Con không cần phải giống hệt người khác mới trở nên giỏi giang hay có giá trị. Hãy luôn yêu thương và tự tin vào chính mình!"
  },
  {
    "ten": "Giọt Sương Rồng Và Bản Nhạc Của Khu Rừng Mơ",
    "moTa": "Sự kiên trì, lòng tốt và niềm đam mê sẽ giúp con sáng tạo nên điều kỳ diệu.",
    "icon": "🎵",
    "audioPath": "audios/giotsuongrongvabannhaccuakhurungmo.mp3",
    "noiDung":
        "Ở rìa một thung lũng xa xôi, nơi có những ngọn núi phủ đầy sương mù, có một chú Mèo Rừng nhỏ tên là Mây. Mây có một ước mơ rất lớn: chú muốn tham dự Lễ hội Âm nhạc Mùa Xuân của khu rừng. Thế nhưng, Mây lại không biết chơi bất kỳ chiếc đàn hay chiếc kèn nào. Các bạn Sóc thì gảy đàn guitar bằng vây lá, các bạn Chim Nhạn thì thổi sáo trúc líu lo, còn Mây chỉ biết đứng nhìn và ao ước.\n"
        "Một ngày nọ, Mây quyết định đi sâu vào Rừng Mơ để tìm một nhạc cụ cho riêng mình. Đi được một quãng xa, chú nghe thấy tiếng khóc thút thít bên dưới một gốc cây đại thụ. Đó là một bạn Sâu Nút Nhỏ đang bị mắc kẹt dưới chiếc lá phong khô nặng trịch. Không ngần ngại, Mây dùng đôi tay khéo léo nâng chiếc lá lên và đỡ Sâu Nút ra ngoài.\n"
        "Sâu Nút xúc động bảo:\n"
        "– 'Cảm ơn bạn Mây! Để trả ơn, tớ sẽ chỉ cho bạn một bí mật. Ở trên đỉnh Ngọn Đồi Rồng có một Cây Sương Ngũ Sắc. Nếu bạn thu thập đủ 7 giọt sương đọng trên lá cây ấy vào rạng sáng, bạn sẽ nghe thấy bản nhạc kỳ diệu nhất.'\n"
        "Mây cảm ơn Sâu Nút rồi tiếp tục vượt qua những con dốc ngoằn ngoèo. Chân chú mỏi rã rời, cái lạnh của sương đêm làm bộ lông chú ướt nhẹp, nhưng Mây vẫn kiên trì leo lên đỉnh đồi. Đúng lúc mặt trời vừa hé rạng, Mây nhìn thấy Cây Sương Ngũ Sắc đang lung linh tỏa sáng. Chú cẩn thận dùng chiếc lá cẩm tú cầu hứng lấy từng giọt sương tinh khiết.\n"
        "Khi giọt sương thứ 7 rơi vào lá, một điều kỳ diệu đã xảy ra: Giọt sương không đứng yên mà bắt đầu gõ 'tí tách, tí tách' lên mặt lá, tạo thành những âm thanh trong trẻo như tiếng chuông gió. Mây bắt đầu nhún nhảy và gõ nhẹ chiếc lá theo nhịp điệu của tim mình.\n"
        "Đến đêm Lễ hội Âm nhạc, khi Mây bước lên sân khấu với chiếc lá và những giọt sương, tất cả các con vật đều ngỡ ngàng. Âm thanh mộc mạc, êm dịu từ chiếc lá sương của Mây hòa cùng tiếng gió rừng đã tạo nên một bản hòa tấu xúc động nhất lễ hội năm đó. Mây nhận ra rằng, nhạc cụ tuyệt vời nhất chính là âm thanh đến từ sự kiên trì và trái tim chân thành.\n"
        "Bài học cho bé: Đừng nản lòng khi mình chưa tìm thấy tài năng ngay lập tức. Sự kiên trì, lòng tốt và niềm đam mê sẽ giúp con sáng tạo ra những điều tuyệt vời rất riêng của chính mình."
  },
  {
    "ten": "Nàng Tiên Cá Nhỏ Và Viên Ngọc Lòng Tốt",
    "moTa": "Lòng tốt và sự chân thành sẽ mang lại những phần thưởng kỳ diệu nhất.",
    "icon": "🧜‍♀️",
    "audioPath": "audios/nangtiencanhovavienngoclongtot.mp3",
    "noiDung":
        "Dưới đáy đại dương xanh thẫm có một vương quốc Thủy Tinh lộng lẫy, nơi sinh sống của Nàng Tiên Cá Nhỏ tên là Annea. Annea có một chiếc đuôi màu hồng ngọc lung linh. Trong vương quốc có một huyền thoại về 'Viên Ngọc Ước' – viên ngọc chỉ xuất hiện khi một ai đó làm được một việc tử tế mà không đòi hỏi bất kỳ điều gì đáp lại.\n"
        "Một ngày nọ, một trận động đất dưới đáy biển khiến ngọn Rạn San Hô Đỏ bị sụp đổ, đè lên lối vào hang động của gia đình Rùa Biển. Các chú rùa con bị kẹt bên trong, tiếng khóc vọng ra vô cùng tội nghiệp. Các cư dân thủy cung đều sợ hãi vì xung quanh ngọn rạn san hô vẫn còn nhiều đá gập ghềnh có thể sạt lở bất cứ lúc nào.\n"
        "Annea không suy nghĩ nhiều, cô liền bơi ngay đến hiện trường. Dù vỏ san hô sắc nhọn làm rách vài vảy cá trên chiếc đuôi xinh đẹp, Annea vẫn kiên nhẫn dùng từng ngón tay nhỏ nhắn di chuyển từng vảy đá. Cô nhẹ nhàng dỗ dành các bạn rùa con:\n"
        "– 'Đừng sợ nhé các bạn nhỏ, tớ sẽ đưa mọi người ra ngoài ngay!'\n"
        "Cùng lúc đó, Chú Cá Sấu Biển – một loài vật vốn bị cư dân đáy biển xa lánh vì vẻ ngoài xù xì – cũng bơi đến giúp Annea một tay. Bằng sức mạnh của mình, Cá Sấu Biển đã nâng tảng đá lớn nhất lên để Annea chui vào bế từng chú rùa con ra an toàn.\n"
        "Ngay khi chú rùa cuối cùng thoát khỏi hang, từ trong khe đá nứt bỗng tỏa ra một luồng ánh sáng xanh dịu nhẹ. Một viên ngọc trai khổng lồ phát sáng ngời ngời tự động bay về phía Annea và Cá Sấu Biển. Viên Ngọc Ước đã xuất hiện! Nhưng thay vì ước cho chiếc đuôi của mình hết đau hay trở nên đẹp hơn, Annea đã mỉm cười ước:\n"
        "– 'Ước gì tất cả cư dân trong đại dương luôn yêu thương, giúp đỡ lẫn nhau và không ai bị tổn thương nữa.'\n"
        "Viên ngọc tan ra thành muôn ngàn tia sáng ấm áp, chữa lành mọi vết thương cho Annea và biến Rạn San Hô trở lại vẻ đẹp rực rỡ ban đầu. Từ đó, người dân thủy cung không còn sợ hãi hay xua đuổi Cá Sấu Biển nữa, mà tất cả cùng nhau sống hòa thuận, hạnh phúc.\n"
        "Bài học cho bé: Lòng tốt không nằm ở vẻ bề ngoài. Khi con biết sẻ chia và giúp đỡ người khác bằng sự chân thành, con sẽ nhận lại tình yêu thương và những điều kỳ diệu nhất."
  },
  {
    "ten": "Chú Voi Con Và Chiếc Vòi Diệu Kỳ",
    "moTa": "Những điểm đặc biệt của bản thân có thể trở thành sức mạnh kỳ diệu.",
    "icon": "🐘",
    "audioPath": "audios/chuvoiconvachiecvoidieuky.mp3",
    "noiDung":
        "Ở vùng đồng cỏ savan bao la, chú Voi Con tên là Bo có một chiếc vòi dài hơn hẳn so với các bạn cùng lứa. Vì chiếc vòi quá dài, Bo thường xuyên bị vấp ngã khi bước đi, hoặc vô tình làm đổ những gáo nước mà mẹ vừa múc. Các bạn Voi khác thường cười nhạo Bo:\n"
        "– 'Bo ơi, cái vòi của cậu vướng víu quá, chẳng làm được việc gì cả!'\n"
        "Bo buồn lắm. Chú thường giấu chiếc vòi của mình vào sau tai và chui vào góc rừng ngồi khóc một mình. Voi Mẹ âu yếm xoa đầu Bo và bảo:\n"
        "– 'Mỗi phần trên cơ thể con đều là một món quà của tự nhiên. Rồi con sẽ thấy chiếc vòi này có ý nghĩa như thế nào.'\n"
        "Một mùa khô hạn kéo dài đè nặng lên đồng cỏ. Các ao hồ đều cạn kiệt nước, cây cối héo rũ. Đàn Voi phải di chuyển rất xa để tìm nguồn nước. Cuối cùng, chúng tìm thấy một hố nước sâu nằm dưới kẽ vách đá hẹp. Tuy nhiên, các con voi lớn với chiếc vòi ngắn thông thường không thể nào với tới mặt nước sâu phía dưới. Cả đàn bắt đầu mệt mỏi và kiệt sức vì khát.\n"
        "Lúc này, Bo tiến lại gần vách đá. Chú vươn chiếc vòi dài đặc biệt của mình xuống sâu qua kẽ nứt. Kìa! Đầu vòi của Bo đã chạm được vào dòng nước mát lạnh dưới lòng đất! Bo nhanh chóng hút đầy nước vào vòi rồi phun ngược lên cho mẹ, cho bác Voi Trưởng Đàn và tất cả các bạn nhỏ cùng uống.\n"
        "Chưa dừng lại ở đó, Bo còn dùng chiếc vòi dài khéo léo hái những chùm quả ngọt trên tận cành cao mà các bạn khác không với tới để chia cho mọi người.\n"
        "Cả đàn Voi tung hô Bo. Các bạn Voi nhỏ từng trêu chọc Bo nay lại vây quanh, trầm trồ khen ngợi chiếc vòi diệu kỳ. Bo mỉm cười hạnh phúc, ôm lấy mẹ và hiểu rằng những điều khác biệt trên cơ thể mình không phải là khuyết điểm, mà chính là một món quà vô giá.\n"
        "Bài học cho bé: Đừng bao giờ tự ti về những điểm đặc biệt hay khác biệt của bản thân. Hãy trân trọng chính mình, vì mỗi đặc điểm ấy đều có thể trở thành sức mạnh kỳ diệu giúp đỡ mọi người."
  },
  {
    "ten": "Bác Cú Sám Và Cuộc Thi Giải Đố Trong Rừng",
    "moTa": "Học cách dùng tư duy loại trừ và quan sát manh mối để tìm ra sự thật.",
    "icon": "🦉",
    "audioPath": "audios/baccusamvacuocthigiaidotrongrung.mp3",
    "noiDung":
        "Trong khu rừng Xanh Thẳm, các loài động vật thường tranh cãi xem ai là người thông minh nhất. Để giải quyết, bác Cú Sám – vị trượng lão uyên bác của khu rừng – liền mở một cuộc thi giải đố với ba chiếc hộp bí mật: Hộp Đỏ, Hộp Xanh và Hộp Vàng.\n\n"
        "Bác Cú treo ba tấm bảng gợi ý trước mặt các bạn nhỏ:\n"
        "– Trên hộp Đỏ viết: 'Món quà bí mật nằm ở trong hộp này.'\n"
        "– Trên hộp Xanh viết: 'Món quà bí mật không nằm ở trong hộp Đỏ.'\n"
        "– Trên hộp Vàng viết: 'Món quà bí mật không nằm ở trong hộp Xanh.'\n\n"
        "Bác Cú đố các bạn: 'Biết rằng trong ba câu trên, chỉ có duy nhất một câu là đúng, còn hai câu kia là sai. Đố các bạn tìm ra chiếc hộp nào chứa món quà?'\n\n"
        "Các bạn Sóc, Thỏ, Chồn gãi đầu suy nghĩ mãi mà không ra. Lúc này, chú Cáo Thông Minh bước lên, dùng tư duy loại trừ để phân tích:\n"
        "Nếu hộp Đỏ nói đúng, thì hộp Xanh (nói món quà không ở hộp Đỏ) sẽ thành nói sai. Nhưng hộp Vàng (nói món quà không ở hộp Xanh) cũng sẽ thành nói sai. Như vậy sẽ có hai câu sai, trái với điều kiện đề bài là chỉ có một câu đúng. Do đó, hộp Đỏ nói sai, và quà không nằm ở hộp Đỏ.\n\n"
        "Vì hộp Đỏ sai, nên câu của hộp Xanh ('Món quà không ở hộp Đỏ') trở thành câu đúng.\n"
        "Nếu hộp Xanh đúng, thì hộp Vàng (nói món quà không ở hộp Xanh) sẽ thành câu sai. Như vậy, ta có đúng một câu đúng duy nhất là hộp Xanh!\n\n"
        "Vậy món quà phải nằm ở đâu? Nếu hộp Đỏ sai (không có quà), hộp Xanh đúng (không có quà ở hộp Đỏ), thì món quà chắc chắn phải nằm ở hộp Vàng!\n\n"
        "Cáo Thông Minh chỉ tay vào hộp Vàng và mở nắp ra. Kìa! Bên trong là một chiếc huy hiệu hình ngôi sao sáng lấp lánh. Bác Cú Sám mỉm cười tán thưởng:\n"
        "– 'Giỏi lắm! Tư duy không phải là đoán mò, mà là biết quan sát các manh mối và loại trừ những điều vô lý để tìm ra sự thật.'\n\n"
        "Bài học cho bé: Khi gặp một bài toán hoặc rắc rối khó, đừng vội nản lòng hay đoán mò. Hãy chia nhỏ vấn đề, suy luận từng bước một (loại trừ những điều sai) để tìm ra đáp án chính xác nhất."
  },
  {
    "ten": "Ba Chú Cá Nhỏ Và Dòng Suối Cạn",
    "moTa": "Quan sát kỹ lưỡng và tìm giải pháp thông minh thay vì chỉ làm theo cảm tính hay chờ đợi.",
    "icon": "🐟",
    "audioPath": "audios/bachucanhovadongsuoican.mp3",
    "noiDung":
        "Ba chú cá nhỏ là Cá Đỏ, Cá Vàng và Cá Xanh cùng sống trong một khúc suối nông. Một hôm, mùa hè oi bức đến, dòng suối cạn nước dần, chỉ còn lại một vũng nước nhỏ xíu đủ chỗ cho một chú cá ở lại qua ngày, trong khi hai vũng nước lớn hơn nằm cách đó một khoảng đất khô ráo.\n\n"
        "Cá Đỏ vội vàng kêu lên:\n"
        "– 'Tớ sẽ bơi thẳng sang vũng nước bên trái vì nó gần nhất!' (Nhưng Cá Đỏ không kiểm tra xem vũng nước đó có bị thông với dòng nước lớn hay chỉ là một vũng tù sắp bốc hơi hết).\n"
        "Cá Vàng thì lo sợ, đứng im một chỗ khóc lóc và chờ đợi phép màu: 'Chắc trời sẽ đổ mưa thôi, tớ chẳng đi đâu cả!'\n"
        "Chỉ có Cá Xanh là bình tĩnh quan sát. Cậu nhận thấy vũng nước bên phải tuy ở xa hơn một chút, nhưng bên dưới có các mạch nước ngầm sủi bọt mát lạnh và có một con rạch nhỏ nối liền với hồ lớn an toàn. Tuy nhiên, đường đi qua vũng bên phải có một đoạn đất cạn phải vượt qua khéo léo.\n\n"
        "Cá Xanh bèn nghĩ ra cách: Cậu đợi lúc trời vừa râm mát, dùng đuôi búng mạnh để trượt nhanh qua đoạn đất cạn nhờ một lớp bùn ẩm, rồi bơi thẳng vào vũng nước có mạch ngầm mát lạnh.\n\n"
        "Vài ngày sau, vũng nước bên trái của Cá Đỏ cạn khô hoàn toàn, Cá Vàng cũng gặp nguy hiểm vì ngồi chờ đợi. Chỉ có Cá Xanh là bơi lội tung tăng, khỏe mạnh và an toàn trong hồ lớn.\n\n"
        "Bài học cho bé: Trước một khó khăn, việc chỉ làm theo cảm tính (chọn cái gần nhất) hay ngồi chờ đợi may mắn đều không hiệu quả. Hãy quan sát kỹ lưỡng, phân tích các lựa chọn và tìm ra giải pháp thông minh, an toàn nhất cho mình."
  },
  {
    "ten": "Chiếc Cân Bất Ngờ Của Thỏ Trưởng Thôn",
    "moTa": "Phương pháp chia nhỏ dữ liệu giúp giải quyết bài toán phức tạp một cách nhanh chóng.",
    "icon": "⚖️",
    "audioPath": "audios/chieccanbatngocuathotruongthon.mp3",
    "noiDung":
        "Trong khu rừng nọ, một bác thợ làm bánh mang đến cho Thỏ Trưởng Thôn 9 chiếc bánh quy thơm ngon. Bác thợ bảo rằng: Trong 9 chiếc bánh đó, có một chiếc bánh bị lỗi (nhẹ hơn các chiếc bánh còn lại vì người thợ vô tình cho thiếu bột).\n\n"
        "Thỏ Trưởng Thôn chỉ được phép dùng một chiếc cân đĩa thăng bằng cũ (không có quả cân, chỉ dùng để so sánh bên nặng bên nhẹ) và chỉ được cân tối đa 2 lần để tìm ra chính xác chiếc bánh nhẹ hơn.\n"
        "Các cử tọa trong làng xôn xao bàn tán. Có bạn bảo phải cân từng cái một, nhưng cân kiểu đó thì tốn tới 8 lần mới xong!\n\n"
        "Lúc đó, Thỏ Trưởng Thôn mỉm cười và áp dụng phương pháp chia nhỏ dữ liệu (chia ba) rất thông minh:\n"
        "– Lần cân thứ nhất: Thỏ chia 9 chiếc bánh thành 3 phần bằng nhau, mỗi phần 3 chiếc (gọi là Phần A, Phần B, Phần C). Thỏ lấy Phần A đặt lên đĩa cân bên trái và Phần B đặt lên đĩa cân bên phải:\n"
        "  + Nếu hai bên thăng bằng, nghĩa là chiếc bánh nhẹ hơn không nằm ở A hay B, mà nó chắc chắn nằm ở Phần C (3 chiếc còn lại).\n"
        "  + Nếu một bên nhẹ hơn, chiếc bánh nhẹ nằm ở phần bên đó. (Giả sử Phần A nhẹ hơn Phần B, vậy chiếc bánh lỗi nằm trong 3 chiếc của Phần A).\n"
        "– Lần cân thứ hai: Sau bước 1, Thỏ đã khoanh vùng được nhóm chứa bánh lỗi chỉ còn 3 chiếc. Thỏ lấy 2 chiếc bất kỳ trong nhóm 3 chiếc đó đặt lên hai đĩa cân:\n"
        "  + Nếu hai chiếc cân thăng bằng, chiếc bánh nhẹ hơn chính là chiếc bánh thứ 3 đang nằm ngoài bàn cân.\n"
        "  + Nếu đĩa nào nhẹ hơn, chiếc bánh lỗi chính là chiếc bánh nằm ở đĩa đó!\n\n"
        "Chỉ với 2 lần cân đúng luật, Thỏ Trưởng Thôn đã tìm ra chính xác chiếc bánh lỗi trước sự thán phục của tất cả mọi người trong rừng.\n\n"
        "Bài học cho bé: Khi giải quyết một bài toán phức tạp có quá nhiều lựa chọn, việc chia nhỏ vấn đề thành các nhóm (tư duy phân loại) sẽ giúp con tìm ra kết quả nhanh chóng và hiệu quả nhất."
  },
  {
    "ten": "Hạt Dẻ Nhỏ Và Mùa Đông Ấm Áp",
    "moTa": "Đừng buồn khi mình nhỏ bé, kiên nhẫn sẽ giúp con vươn lên mạnh mẽ.",
    "icon": "🌰",
    "audioPath": "audios/hatdenhovamuadongamap.mp3",
    "noiDung":
        "Trong một khu rừng già, Hạt Dẻ Nhỏ nằm ngoan ngoãn trong chiếc mũ gai xanh sần sùi. Các hạt dẻ khác trên cành đều lớn phổng phao và luôn tự hào khoe lớp vỏ nâu bóng mượt, chê Hạt Dẻ Nhỏ vừa bé lại vừa nằm khuất sau kẽ lá.\n\n"
        "Một ngày mùa thu, một cơn gió mạnh thổi qua khiến cành cây rung lắc dữ dội. Các hạt dẻ lớn vì quá kiêu hãnh và căng tròn nên đã bị rụng xuống đất cứng, bị các chú sóc gom nhặt mang đi mất. Riêng Hạt Dẻ Nhỏ vì nằm ở kẽ lá che khuất nên may mắn bám trụ lại được.\n\n"
        "Đến mùa đông, khi tuyết trắng phủ kín khu rừng, Hạt Dẻ Nhỏ được cành cây che chở và rụng xuống một lớp lá mục ấm áp. Khi mùa xuân đến, nhờ những giọt mưa xuân ngọt lành, lớp vỏ của Hạt Dẻ Nhỏ nứt ra và một mầm cây xanh non vươn lên mạnh mẽ. Vài năm sau, mầm cây ấy lớn lên thành một cây dẻ cao lớn, tỏa bóng mát cho cả một góc rừng và làm nơi trú ẩn cho các bạn chim nhỏ.\n\n"
        "Bài học cho bé: Đừng buồn khi mình nhỏ bé hay chưa bằng người khác. Kiên nhẫn và biết bảo vệ bản thân trước những thử thách sẽ giúp con vươn lên mạnh mẽ trong tương lai."
  },
  {
    "ten": "Ngọn Đèn Của Đom Đóm Nhỏ",
    "moTa": "Mỗi người đều có một ánh sáng và giá trị riêng biệt để giúp ích cho đời.",
    "icon": "✨",
    "audioPath": "audios/ngondencuadomdomnho.mp3",
    "noiDung":
        "Đom Đóm Nhỏ vừa mới lột xác và có chiếc đèn ở đuôi nhỏ xíu. Vào đêm hội ánh sáng đầu tiên của khu rừng, các anh chị lớn đều nhấp nháy những ánh hào quang rực rỡ, chiếu sáng cả một góc trời. Còn Đom Đóm Nhỏ chỉ phát ra được một ánh sáng mờ ảo, yếu ớt khiến chú vô cùng tủi thân và bay vào một góc tối ngồi khóc.\n\n"
        "Đúng lúc đó, Sóc Con đi lạc trong đêm tối đang vừa đi vừa run rẩy vì không tìm thấy đường về nhà. Rừng đêm đen kịt, các anh chị đom Đóm lớn vì mãi mải khoe ánh sáng trên cao nên không nhìn thấy Sóc Con đang loay hoay dưới những gốc cây rậm rạp.\n\n"
        "Đom Đóm Nhỏ nghe tiếng khóc liền bay lại gần. Dù ánh sáng của chú không chói lọi, nhưng vì bay sát mặt đất nên chú đã soi rõ từng hòn đá, từng chiếc rễ cây gập ghềnh, dẫn đường cho Sóc Con vượt qua lối mòn để về tận hang an toàn.\n\n"
        "Sóc Con ôm lấy Đom Đóm Nhỏ và cảm ơn rối rít:\n"
        "– 'Ánh sáng dịu dàng của bạn vừa vặn và tuyệt vời nhất để cứu tớ trong bóng tối!'\n\n"
        "Từ đó, Đom Đóm Nhỏ hiểu rằng ánh sáng của mình tuy nhỏ nhưng lại cực kỳ có ích đối với những ai đang cần sự giúp đỡ.\n\n"
        "Bài học cho bé: Mỗi người đều có một ánh sáng và giá trị riêng biệt. Đừng bao giờ tự ti, vì lòng tốt và sự chân thành của con luôn có ý nghĩa lớn lao đối với người khác."
  },
  {
    "ten": "Chiếc Lá Phong Đỏ Và Chuyến Phiêu Lưu Mùa Thu",
    "moTa": "Bước ra khỏi vùng an toàn giúp con khám phá thế giới rộng lớn và kỳ diệu.",
    "icon": "🍁",
    "audioPath": "audios/chieclaphongdovachuyenphieuluumuathu.mp3",
    "noiDung":
        "Trên ngọn cây phong già, chiếc lá Phong Đỏ rực rỡ đang buồn bã nhìn những chiếc lá xanh khác. Mùa thu đã đến, các anh chị lá lần lượt đổi sang màu vàng rồi rụng xuống để chuẩn bị cho những chuyến phiêu lưu mới, còn Phong Đỏ vẫn bám chặt lấy cành vì sợ hãi những điều chưa biết.\n\n"
        "Gió Thu dịu dàng thổi qua, ghé tai xoa nhẹ và thì thầm:\n"
        "– 'Đừng sợ hãi, lá ạ! Buông tay khỏi cành cũ không phải là kết thúc, mà là khởi đầu cho một hành trình bay lượn tuyệt đẹp.'\n\n"
        "Nghe lời Gió, Phong Đỏ hít một hơi thật sâu, thả lỏng và nhẹ nhàng buông mình vào không trung. Chú được Gió nâng lên, bay lượn qua những con suối róc rách, lướt qua những thảm cỏ xanh mướt và ngắm nhìn toàn cảnh khu rừng thu vàng óng từ trên cao. Cuối cùng, Phong Đỏ hạ cánh nhẹ nhàng xuống một dòng suối nhỏ, trở thành chiếc thuyền rơm xinh xắn đưa một chú Kiến con qua sông an toàn.\n\n"
        "Phong Đỏ mỉm cười khép lại chuyến đi, cảm thấy hạnh phúc vì cuộc đời mình đã thật trọn vẹn và ý nghĩa.\n\n"
        "Bài học cho bé: Thay đổi và bước ra khỏi vùng an toàn có thể hơi đáng sợ lúc đầu, nhưng đó là cách giúp con khám phá thế giới rộng lớn và học hỏi thêm nhiều điều kỳ diệu."
  },
];

  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        toolbarHeight: 50,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: const Text(
          "Góc Truyện Kể Cho Bé",
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView.builder(
          itemCount: danhSachTruyenChu.length,
          itemBuilder: (context, index) {
            final truyen = danhSachTruyenChu[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrangDocTruyenChuChiTiet(
                      tenTruyen: truyen["ten"]!,
                      noiDungTruyen: truyen["noiDung"]!,
                      audioPath: truyen["audioPath"]!, // Truyền đường dẫn MP3 sang màn hình chi tiết
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.teal.shade300, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(truyen["icon"]!, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            truyen["ten"]!,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            truyen["moTa"]!,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.teal, size: 18),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// MÀN HÌNH ĐỌC CHI TIẾT (PHÁT FILE MP3 TỪ THƯ MỤC AUDIOS)
class TrangDocTruyenChuChiTiet extends StatefulWidget {
  final String tenTruyen;
  final String noiDungTruyen;
  final String audioPath; // Nhận đường dẫn file MP3
  const TrangDocTruyenChuChiTiet({
    Key? key,
    required this.tenTruyen,
    required this.noiDungTruyen,
    required this.audioPath,
  }) : super(key: key);
  @override
  State<TrangDocTruyenChuChiTiet> createState() => _TrangDocTruyenChuChiTietState();
}
class _TrangDocTruyenChuChiTietState extends State<TrangDocTruyenChuChiTiet> {
  late final AudioPlayer _audioPlayer;
  final ScrollController _scrollController = ScrollController();
  bool _isPlaying = false;
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    // 1. QUAN TRỌNG: Chặn audioplayers tự động thêm chữ "assets/" vào trước
    _audioPlayer.audioCache = AudioCache(prefix: '');
    // Lắng nghe trạng thái phát nhạc khi chạy xong bài hát
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }
  Future<void> _togglePlayAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        // 2. Vì prefix đã rỗng, truyền thẳng đường dẫn "audios/tên_file.mp3" vào là chạy chính xác
        print("Đang phát đường dẫn: ${widget.audioPath}");
        await _audioPlayer.play(AssetSource(widget.audioPath));
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      print("Lỗi phát nhạc: $e");
      setState(() => _isPlaying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể phát file: $e")),
        );
      }
    }
  }
  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  Widget _nutQuayLaiChuan(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 20),
        onPressed: () {
          _audioPlayer.stop();
          Navigator.pop(context);
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF0E6),
      appBar: AppBar(
        toolbarHeight: 55,
        leading: Center(child: _nutQuayLaiChuan(context)),
        title: Text(
          widget.tenTruyen,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: InkWell(
                onTap: _togglePlayAudio,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isPlaying ? Colors.orange : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.orange, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: _isPlaying ? Colors.white : Colors.teal,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isPlaying ? "Tạm Dừng" : "Nghe Kể Chuyện",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isPlaying ? Colors.white : Colors.teal.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.teal.shade200, width: 2),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Text(
              widget.noiDungTruyen,
              style: const TextStyle(
                fontSize: 18,
                height: 1.6,
                color: Colors.brown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}