import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock/wakelock.dart';
import 'package:shake/shake.dart';
import 'dart:io' show Platform;
import 'package:flutter/animation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.black));
  SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
  bool enable = true;
  Wakelock.toggle(enable: enable);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trancer',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 25, 35, 26),
        primarySwatch: Colors.blue,
        primaryColor: Colors.black,
        hintColor: Colors.black,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Trancer'),
    );
  }
}

final Uri _url = Uri.parse('https://zendoclab.blogspot.com/2023/06/trancer-web-hypnagogia-creativity.html');

Future<void> _launchUrl() async {
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}


AppBar trAppBar(context) {
  Locale locale = View.of(context).platformDispatcher.locale;
  return AppBar(
    bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4.0),
        child: Container(
          color: Colors.white12,
          height: 2.0,
        )),
    centerTitle: false,
    title: Text((locale.languageCode=='ko' ? '트랜서' : 'Trancer'),
        style: const TextStyle(
            color: Colors.white38, fontSize: 18, fontWeight: FontWeight.bold)),
    automaticallyImplyLeading: false,
    elevation: 0,
    backgroundColor: Colors.black,
    foregroundColor: Colors.black,
      actions: <Widget>[
        IconButton(onPressed: () {_launchUrl();}, icon: const Icon(Icons.question_mark, color: Colors.white38)),
        IconButton(onPressed: () {
          locale.languageCode=='ko' ? Share.share('트랜서 – 입면 & 창의력 – https://zendoclab.github.io/trancer2/#/') : Share.share('Trancer – Hypnagogia & Creativity – https://zendoclab.github.io/trancer2/#/');
        }, icon: const Icon(Icons.share, color: Colors.white38))
      ]);
}

TextStyle TrTextStyle(String textType) {
  return textType == 'title'
      ? const TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    color: Color.fromARGB(255, 51, 161, 59),
  )
      : const TextStyle(
    fontSize: 20.0,
    color: Color.fromARGB(255, 51, 161, 59),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

late ShakeDetector detector;
final player = AudioPlayer();
int isShaking = 0;
bool forNight = true;

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  bool _isPlaying = true;
  bool beepStopped = false;
  int beepStopTime = 0;
  int shaken = 0;
  int fivesec = 3;

  @override
  void initState() {
    super.initState();

    Random rand = Random();

    controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    animation = Tween<double>(begin: 0, end: 100).animate(controller)
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          print("$beepStopped");
          print("$fivesec");
          fivesec += 1;
          if (fivesec >= (forNight ? 5 : 4)) {
            if (rand.nextInt((forNight ? 7 : 5)) == 1) {
              // 여기에서 컨트롤러 고/스탑 by 셰이크
              setState(() {
                beepStopped = true;
              });
            }
          }

          if (beepStopTime == 30) {
            // 깨우기
            await player.play(AssetSource('lib/alarm.mp3'),
                mode: PlayerMode.mediaPlayer, volume: 1.0);
          }

          if (beepStopTime == 60) {
            // 앱종료
            controller.stop();
            detector.stopListening();
            Wakelock.toggle(enable: false);
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }

          controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
          if (beepStopped == true) {
            setState(() {
              beepStopTime += 1;
            });
          }
          if (fivesec >= (forNight ? 5 : 4)) {
            if (beepStopped == false) {
              await player.play(AssetSource('lib/beep.wav'),
                  mode: PlayerMode.lowLatency, volume: _val);
            }

            fivesec = 0;
          }
          //SystemSound.play(SystemSoundType.click);

        }
      })
      ..addStatusListener((state) {})
      ..addListener(() {
        if (shaken > 0) {
          shaken -= 1;
        } else if (shaken == 0) {
          setState(() {});
        }
      });
    controller.forward();

    detector = ShakeDetector.autoStart(onPhoneShake: () {
      setState(() {
        beepStopped = false;
        beepStopTime = 0;
        if (controller.status == AnimationStatus.dismissed) {
          controller.forward();
        }
        shaken = 50;
      });
      // detector.stopListening();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    detector.stopListening();
    super.dispose();
    player.dispose();
  }

  double _val = 0.5;
  // Timer? timer;

  @override
  Widget build(BuildContext context) {

    Locale locale = View.of(context).platformDispatcher.locale;
    return Scaffold(
        appBar: trAppBar(context),
        body: SafeArea(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text(locale.languageCode=='ko' ? "비프음을 관찰하는\n당신을 관찰하세요" : "Observe Yourself\nwho Observe Beep",
                          style: TrTextStyle('title')),
                      Text(locale.languageCode=='ko' ? "마음챙김" : "Be Mindful",
                          style: TrTextStyle('body')),
                      Card(
                          color: Colors.black12,
                          margin: const EdgeInsets.all(12.0),
                          child: ListTile(
                            leading:
                            const Icon(Icons.music_note, color: Colors.teal, size: 20),
                            title: Text(
                                beepStopped
                                    ? locale.languageCode=='ko' ? "비프음 중단" : "Beep is OFF"
                                    : locale.languageCode=='ko' ? "비프음 진행" : "Beep is ON",
                                style: TrTextStyle('body')),
                          )),
                      Card(
                          color: Colors.black12,
                          margin: const EdgeInsets.all(12.0),
                          child: ListTile(
                            leading: const Icon(Icons.timer, color: Colors.teal, size: 20),
                            title: Text(
                                !beepStopped
                                    ? locale.languageCode=='ko' ? "비프음 중단이 60초 이상 되면, 앱은 자동으로 종료됩니다" : "App closes automatically, If Beep is OFF for 60 seconds"
                                    : locale.languageCode=='ko' ? '${30 - beepStopTime} ' +
                                     "초 남았습니다 앱종료까지, 비프음을 진행하려면 기기를 살짝 흔들어요" : '${60 - beepStopTime} ' + "seconds Remain Before App closes, Shake Device A Little To Continue",
                                style: TrTextStyle('body')),
                          )),
                      Card(
                          color: Colors.black12,
                          margin: const EdgeInsets.all(12.0),
                          child: ListTile(
                            leading: const Icon(Icons.waves, color: Colors.teal, size: 20),
                            title: Text(
                                shaken == 0
                                    ? ''
                                    : locale.languageCode=='ko' ? "흔들기 감지됨" : "Shake is Detected",
                                style: TrTextStyle('body')),
                          )),
                      const Divider(
                        // height: 100,
                        thickness: 1,
                        color: Color.fromARGB(255, 51, 161, 59),
                      ),
                      Card(
                          color: Colors.black12,
                          margin: const EdgeInsets.all(12.0),
                          child: ListTile(
                            leading: !forNight
                                ? const Icon(Icons.wb_sunny_rounded,
                                color: Colors.teal, size: 20)
                                : const Icon(Icons.nightlight_round,
                                color: Colors.teal, size: 20),
                            trailing: Switch(
                              value: forNight,
                              onChanged: (value) {
                                setState(() {
                                  forNight = value;
                                });
                              },
                              activeTrackColor: Colors.lightGreenAccent,
                              activeColor: Colors.green,
                            ),
                            title: Text(
                                forNight
                                    ? locale.languageCode=='ko' ? '밤' : 'Night'
                                    : locale.languageCode=='ko' ? '낮' : 'Day',
                                style: TrTextStyle('body')),
                          )),
                      Card(
                          color: Colors.black12,
                          margin: const EdgeInsets.all(12.0),
                          child: ListTile(
                              leading:
                              const Icon(Icons.volume_down, color: Colors.teal, size: 20),
                              title: Slider(
                                  label: locale.languageCode=='ko' ? '볼륨' : 'volume',
                                  value: _val,
                                  min: 0,
                                  max: 1,
                                  divisions: 100,
                                  onChanged: (val) {
                                    _val = val;
                                    setState(() {});
                                    /*
                if (timer != null) {
                  timer!.cancel();
                }
                //use timer for the smoother sliding
                timer = Timer(Duration(milliseconds: 200), () {

                });
                 */
                                    print("val:${val}");
                                  }))),
                    ]))));
  }
}
