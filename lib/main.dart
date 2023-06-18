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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.black));
  await SystemChrome.setEnabledSystemUIMode(
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
    title: Text((locale.languageCode=='ko' ? '트랜서2' : 'Trancer2'),
        style: const TextStyle(
            color: Colors.white38, fontSize: 18, fontWeight: FontWeight.bold)),
    automaticallyImplyLeading: false,
    elevation: 0,
    backgroundColor: Colors.black,
    foregroundColor: Colors.black,
      actions: <Widget>[
        IconButton(onPressed: () {_launchUrl();}, icon: const Icon(Icons.question_mark, color: Colors.white38)),
        IconButton(onPressed: () {
          locale.languageCode=='ko' ? Share.share(subject: '트랜서2','입면 & 창의력 – https://zendoclab.github.io/trancer2/#/') : Share.share(subject: 'Trancer2','Hypnagogia & Creativity – https://zendoclab.github.io/trancer2/#/');
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
  late Locale locale;
  bool _isStarted = false;
  bool _isPlaying = true;
  bool firstBeep = false;
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
          print("$beepStopTime");
          print("$fivesec");
          print("$firstBeep");
          if(_isStarted && !beepStopped) { fivesec += 1; }
          if (fivesec >= 3) {
            if ((rand.nextInt(5) == 1) && firstBeep) {
              // 여기에서 컨트롤러 고/스탑 by 셰이크
              setState(() {
                beepStopped = true;
              });
            }
            firstBeep = true;
          }

          if (beepStopTime == 30) {
            // 깨우기
            if(forNight) {
                await player.play(AssetSource('alarm.mp3'),
                mode: PlayerMode.mediaPlayer, volume: 1.0); }
            else {
              Wakelock.toggle(enable: false);
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            }
          }

          controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
          if (beepStopped == true && _isStarted) {
            setState(() {
              if(beepStopTime<30) {
              beepStopTime += 1; }
            });
          }
          if (fivesec >= 3) {
            if (beepStopped == false) {
              if(_isStarted) { await player.play(AssetSource('beep.wav'),
                  mode: PlayerMode.lowLatency, volume: _val); }
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

    detector = ShakeDetector.autoStart(onPhoneShake: () async {
      setState(() {
        beepStopped = false;
        beepStopTime = 0;
        if (controller.status == AnimationStatus.dismissed) {
          controller.forward();
        }
        shaken = 50;
      });
      if(_isStarted) {await player.play(AssetSource('beep.wav'),
          mode: PlayerMode.lowLatency, volume: _val); }
      // detector.stopListening();
    },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 1.04,
    );
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
        body: SingleChildScrollView(
            child:SafeArea(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text(locale.languageCode=='ko' ? "자면서 비프음 관찰하기" : "Observing Beeps While Sleeping",
                          style: TrTextStyle('body')),

                      const SizedBox(height: 8.0),
                      _isStarted ? ElevatedButton(onPressed: () {
                        setState(() {
                          _isStarted = !_isStarted;
                          beepStopped = false;
                          beepStopTime = 0;
                          fivesec = 0;
                          player.stop();
                        });
                      },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black12, shape: const CircleBorder(),
                        ),
                        child:
                        const Icon(Icons.stop, color: Colors.teal, size: 50),
                      ) : ElevatedButton(onPressed: () {
                        setState(() {
                          _isStarted = !_isStarted;
                        });
                      },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black12, shape: const CircleBorder(),
                        ),
                          child:
                          const Icon(Icons.play_arrow, color: Colors.teal, size: 50),
                          ),


                      Card(
                          color: Colors.black12,
                          margin: const EdgeInsets.all(12.0),
                          child: ListTile(
                            leading: forNight
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
                                locale.languageCode=='ko' ? '깨우기 알람' : 'WakeUp Alarm',
                                style: TrTextStyle('body')),
                          )),
                      _isStarted ?
                      Card(
                          color: Colors.black12,
                          margin: const EdgeInsets.all(12.0),
                          child: ListTile(
                            leading:
                            const Icon(Icons.music_note, color: Colors.teal, size: 20),
                            title: Text(
                                beepStopped
                                    ? locale.languageCode=='ko' ? "비프음 중단됨" : "Beep is STOPPED"
                                    : locale.languageCode=='ko' ? "비프음 진행중" : "Beep is ONGOING",
                                style: TrTextStyle('body')),
                          )) : const Text(""),
                      _isStarted ?
                      Card(
                          color: Colors.black12,
                          margin: const EdgeInsets.all(12.0),
                          child: ListTile(
                            leading: const Icon(Icons.timer, color: Colors.teal, size: 20),
                            title: Text(
                                !beepStopped
                                    ? locale.languageCode=='ko' ? "비프음이 중단되면 폰을 흔드세요. 다시 진행!" : "Shake the phone when the beep stops. Go Again!"
                                    : forNight ? locale.languageCode=='ko' ? '${30 - beepStopTime} ' +
                                     "초 뒤 깨우기 알람이 시작됩니다. 흔드세요!" : 'Atfer ${30 - beepStopTime}s, ' + "Wakeup Alarm will starts. Shake!" :
                                locale.languageCode=='ko' ? '${30 - beepStopTime} ' +
                                    "초 뒤 앱이 종료 됩니다. 흔드세요!" : 'Atfer ${30 - beepStopTime}s, ' + "App will closes. Shake!",
                                style: TrTextStyle('body')),
                          )) : const Text(""),
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
                    ])))) );
  }
}
