import 'dart:math';
import 'package:flutter/material.dart';

bool
_isDarkMode = false;

class VerifyPage
    extends
        StatefulWidget {
  const VerifyPage({
    super.key,
  });

  @override
  State<
    VerifyPage
  >
  createState() => _VerifyPageState();
}

class _VerifyPageState
    extends
        State<
          VerifyPage
        > {
  late List<
    TextEditingController
  >
  codeControllers;
  late String sentCode;

  @override
  Widget build(
    BuildContext context,
  ) {
    // Controllers for code input
    codeControllers = List.generate(
      4,
      (
        _,
      ) => TextEditingController(),
    );

    final theme = _isDarkMode
        ? ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(
              0xFF388E3C,
            ),
            scaffoldBackgroundColor: const Color(
              0xFF232D23,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(
                0xFF2E473B,
              ),
              foregroundColor: Colors.white,
              elevation: 2,
              iconTheme: IconThemeData(
                color: Color(
                  0xFFB2FF59,
                ),
              ),
              titleTextStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(
                  0xFFB2FF59,
                ),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(
                0xFF2E473B,
              ),
              hintStyle: TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    12,
                  ),
                ),
                borderSide: BorderSide.none,
              ),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(
                0xFF388E3C,
              ),
              secondary: Color(
                0xFFB2FF59,
              ),
              background: Color(
                0xFF232D23,
              ),
              surface: Color(
                0xFF2E473B,
              ),
              onPrimary: Colors.white,
              onSecondary: Color(
                0xFF232D23,
              ),
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: const Color(
              0xFF388E3C,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(
                0xFF388E3C,
              ),
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(
                0xFFD9F2E6,
              ),
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    12,
                  ),
                ),
                borderSide: BorderSide.none,
              ),
            ),
          );
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Verify',
            style: TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
              ),
              tooltip: 'Toggle Dark Mode',
              onPressed: () {
                setState(
                  () {
                    _isDarkMode = !_isDarkMode;
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 16,
                ),
                // Display the sent code at the top
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? const Color(
                              0xFFB2FF59,
                            ).withOpacity(
                              0.15,
                            )
                          : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Text(
                      'Code sent: $sentCode',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode
                            ? const Color(
                                0xFFB2FF59,
                              )
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        "Verify Your Email",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        "AgriSynch",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          color: Color(
                            0xFF1DBF73,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Image.asset(
                        'assets/logo.png',
                        height: 100,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF00A862,
                    ),
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                  ),
                  padding: const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Account Verification",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        "Please enter the 4 digit code sent to Your Email",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (
                            index,
                          ) {
                            return SizedBox(
                              width: 60,
                              child: TextField(
                                controller: codeControllers[index],
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(
                                    0xFFD9F2E6,
                                  ),
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(
                              () {
                                sentCode = _generateRandomCode();
                              },
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'New code sent: $sentCode',
                                ),
                                duration: const Duration(
                                  seconds: 2,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Resend Code",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            final code = codeControllers
                                .map(
                                  (
                                    c,
                                  ) => c.text,
                                )
                                .join();
                            if (code ==
                                sentCode) {
                              Navigator.pushNamed(
                                context,
                                '/home',
                              );
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Verified!",
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Invalid code",
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFD9F2E6,
                            ),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                            ),
                          ),
                          child: const Text(
                            "Verify",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    codeControllers = List.generate(
      4,
      (
        _,
      ) => TextEditingController(),
    );
    sentCode = _generateRandomCode();
  }

  @override
  void dispose() {
    for (var c in codeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _generateRandomCode() {
    final rand = Random();
    return List.generate(
      4,
      (
        _,
      ) => rand
          .nextInt(
            10,
          )
          .toString(),
    ).join();
  }
}
