import 'dart:math';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

void main() => runApp(const FlipPhoneLauncher());

class FlipPhoneLauncher extends StatelessWidget {
  const FlipPhoneLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // ignore: invalid_use_of_private_member
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double rotationOffset = 0.0;
  Offset? lastDrag;

  final List<String> allowedPackages = [
    'com.android.dialer',
    'com.google.android.dialer',
    'com.android.messaging',
    'com.google.android.apps.messaging',
    'com.android.camera',
    'com.google.android.GoogleCamera',
    'com.android.camera2',
    'com.android.deskclock',
    'com.google.android.deskclock',
    'com.android.settings',
    'com.google.android.calendar',
    'com.android.calculator2',
  ];

  List<Widget> cachedIcons = [];
  List<Application> apps = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/flipPhone.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha((0.6 * 255).toInt()),
              BlendMode.darken,
            ),
          ),
        ),
        child: FutureBuilder<List<Application>>(
          future: DeviceApps.getInstalledApplications(
            includeSystemApps: true,
            includeAppIcons: true,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            apps = snapshot.data!
                .where((app) => allowedPackages.contains(app.packageName))
                .toList();

            apps.sort((a, b) => a.appName.compareTo(b.appName));

            if (cachedIcons.isEmpty) {
              cachedIcons = apps.map((app) {
                Widget icon = const Icon(Icons.apps, size: 60, color: Colors.white);
                if (app is ApplicationWithIcon) {
                  icon = Image.memory(app.icon, width: 60, height: 60);
                }
                return RepaintBoundary(
                  child: GestureDetector(
                    onTap: () => DeviceApps.openApp(app.packageName),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withAlpha((0.65 * 255).toInt()),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: Center(child: icon),
                    ),
                  ),
                );
              }).toList();
            }

            return LayoutBuilder(builder: (context, constraints) {
              final centerX = constraints.maxWidth / 2;
              final centerY = constraints.maxHeight / 2;
              final radius = min(centerX, centerY) * 0.7;
              final step = 2 * pi / cachedIcons.length;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) => lastDrag = details.localPosition,
                onPanUpdate: (details) {
                  if (lastDrag == null) return;
                  final dx = details.localPosition.dx - lastDrag!.dx;
                  setState(() {
                    rotationOffset += dx * 0.01;
                  });
                  lastDrag = details.localPosition;
                },
                onPanEnd: (_) => lastDrag = null,
                child: Stack(
                  children: [
                    for (int i = 0; i < cachedIcons.length; i++)
                      Positioned(
                        left: centerX + radius * cos(i * step + rotationOffset) - 48,
                        top: centerY + radius * sin(i * step + rotationOffset) - 48,
                        child: cachedIcons[i],
                      ),
                  ],
                ),
              );
            });
          },
        ),
      ),
    );
  }
}
