import 'package:flutter/material.dart';
import 'theme_helper.dart';
import 'feedback_service.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _themeNotifier = ThemeNotifier();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  String _feedbackCategory = 'General';
  int _messageChars = 0;
  bool _isSubmitting = false;

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
    nameController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    // keep controllers in state so text persists while editing
    messageController.addListener(() {
      if (mounted) {
        setState(() {
        _messageChars = messageController.text.length;
      });
      }
    });

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
            // Category dropdown
            Text(
              'Category',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: ThemeHelper.getTextColor(isDarkMode),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeHelper.getInputFillColor(isDarkMode),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _feedbackCategory,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'General', child: Text('General Question/Comment')),
                  DropdownMenuItem(value: 'Bug Report', child: Text('Bug Report')),
                  DropdownMenuItem(value: 'Feature Request', child: Text('Feature Request')),
                  DropdownMenuItem(value: 'Technical Support', child: Text('Technical Support')),
                  DropdownMenuItem(value: 'Account Issues', child: Text('Account Issues')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _feedbackCategory = value ?? 'General';
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 5,
              maxLength: 500,
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
            const SizedBox(height: 8),
            // character counter aligned to the right
            Row(
              children: [
                const Spacer(),
                Text(
                  '$_messageChars/500',
                  style: TextStyle(
                    color: ThemeHelper.getSecondaryTextColor(isDarkMode),
                    fontFamily: 'Poppins',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Right-aligned Send Feedback button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
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

                          setState(() {
                            _isSubmitting = true;
                          });

                          final success = await FeedbackService.submitFeedback(
                            feedback: message,
                            category: _feedbackCategory,
                          );

                          setState(() {
                            _isSubmitting = false;
                          });

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Feedback submitted! Thank you."),
                                backgroundColor: Color(0xFF00C853),
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to send feedback. Please try again."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "Send Feedback",
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
