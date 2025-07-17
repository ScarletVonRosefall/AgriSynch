import 'package:flutter/material.dart';

class ProfilePage
    extends
        StatelessWidget {
  const ProfilePage({
    Key? key,
  }) : super(
         key: key,
       );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(
              height: 24,
            ),
            Text(
              'Name:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 6,
            ),
            Text(
              'Farmer Name',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
              ),
            ),
            SizedBox(
              height: 18,
            ),
            Text(
              'Email:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 6,
            ),
            Text(
              'farmer@email.com',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
