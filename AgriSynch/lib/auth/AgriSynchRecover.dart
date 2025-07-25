import 'package:flutter/material.dart';

class AgriSynchRecoverPage
    extends
        StatelessWidget {
  const AgriSynchRecoverPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final emailController = TextEditingController();

    return Scaffold(
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
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.pop(
                  context,
                ),
              ),

              const SizedBox(
                height: 16,
              ),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Forgot Your Password?",
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
                      "Account Recovery",
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
                      "Forgot your password? Enter your email and we'll send you a code to reset it.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _inputField(
                      "Email",
                      emailController,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/verify',
                        ),
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
                              20,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Send Recovery Code",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Center(
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white,
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
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(
          0xFFD9F2E6,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            20,
          ),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
