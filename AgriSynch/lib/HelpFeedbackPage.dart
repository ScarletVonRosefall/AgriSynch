import 'package:flutter/material.dart';

class HelpFeedbackPage
    extends
        StatelessWidget {
  const HelpFeedbackPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final nameController = TextEditingController();
    final messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Feedback',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Let us know how we can help or what feedback you have!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Your Name",
                filled: true,
                fillColor: const Color(
                  0xFFE6F2F2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Your Message",
                filled: true,
                fillColor: const Color(
                  0xFFE6F2F2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final message = messageController.text.trim();

                  if (name.isEmpty ||
                      message.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please fill in all fields.",
                        ),
                      ),
                    );
                    return;
                  }

                  // You can hook this up to Firestore, email, or whatever later
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Feedback submitted! Thank you.",
                      ),
                    ),
                  );
                  Navigator.pop(
                    context,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF1B4D3E,
                  ),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
