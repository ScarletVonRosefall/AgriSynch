import 'package:flutter/material.dart';
import 'theme_helper.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final nameController = TextEditingController();
    final messageController = TextEditingController();

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: ThemeHelper.getHeaderColor(isDarkMode),
        foregroundColor: Colors.white,
        title: const Text(
          'Help & Feedback',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Let us know how we can help or what feedback you have!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: ThemeHelper.getTextColor(isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: ThemeHelper.getTextColor(isDarkMode),
              ),
              decoration: InputDecoration(
                labelText: "Your Name",
                labelStyle: TextStyle(
                  color: ThemeHelper.getSecondaryTextColor(isDarkMode),
                ),
                filled: true,
                fillColor: ThemeHelper.getInputFillColor(isDarkMode),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 5,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: ThemeHelper.getTextColor(isDarkMode),
              ),
              decoration: InputDecoration(
                labelText: "Your Message",
                labelStyle: TextStyle(
                  color: ThemeHelper.getSecondaryTextColor(isDarkMode),
                ),
                filled: true,
                fillColor: ThemeHelper.getInputFillColor(isDarkMode),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final message = messageController.text.trim();

                  if (name.isEmpty || message.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill in all fields."),
                      ),
                    );
                    return;
                  }

                  // You can hook this up to Firestore, email, or whatever later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Feedback submitted! Thank you."),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
