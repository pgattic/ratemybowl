import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  final List<String> _credits = [
    "Idea & \nChief Architect\nPreston Corless",
    "Project Lead\nRyan Brinton",
    "Back-End\nEthan Alvey",
    "UI Lead\nKeaton Folsom",
    "Front-End\nJisu Song",
    "Fullstack\nEthan Wait",
  ];

  final List<String> _urls = [
    "https://github.com/pgattic",
    "https://github.com/ryanmbrinton",
    "https://github.com/alveyE",
    "https://github.com/folskeat",
    "https://github.com/bobibobab",
    "https://github.com/ethanwait25",
  ];

  int _visibleCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset("assets/videos/cute_roll.mp4");

    _controller.initialize().then((_) {
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      _controller.play();
      _controller.setLooping(false);

      _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
        if (!mounted) return;

        if (_visibleCount < _credits.length) {
          setState(() {
            _visibleCount++;
          });
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = screenHeight / 700;

    return Scaffold(
      backgroundColor: const Color(0xFF12BBFD),
      appBar: AppBar(title: const Text("The Tinkle Thinkers")),
      body: Center(
        child: _isInitialized
            ? Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  Column(
                    children: [
                      const Spacer(flex: 4),
                      // Always keep the widgets in the tree, only animate opacity
                      ...List.generate(_credits.length, (index) {
                        return Column(
                          children: [
                            AnimatedOpacity(
                              opacity: index < _visibleCount ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: GestureDetector(
                                onTap: () => _openUrl(_urls[index]),
                                child: Text(
                                  _credits[index],
                                  style: TextStyle(
                                    color: const Color.fromARGB(
                                      255,
                                      150,
                                      150,
                                      150,
                                    ),
                                    fontSize: 14 * scaleFactor,
                                    decoration: TextDecoration.underline,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            // Fixed spacing, does not depend on _visibleCount
                            SizedBox(height: screenHeight * 0.05),
                          ],
                        );
                      }),
                      const Spacer(flex: 3),
                    ],
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
