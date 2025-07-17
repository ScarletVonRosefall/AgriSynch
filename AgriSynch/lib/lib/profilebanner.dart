import 'package:flutter/material.dart';

void
main() {
  runApp(
    MaterialApp(
      home: ProfileBanner(),
    ),
  );
}

class ProfileBanner
    extends
        StatelessWidget {
  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Banner',
        ),
      ),
      body: Center(
        child: Container(
          width: 170,
          height: 300,
          color: Colors.blue,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dalangin, Kim Adriel M.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  '📞0992-219-7221',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '📨22-07942@g.batstate-u.edu.ph',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
