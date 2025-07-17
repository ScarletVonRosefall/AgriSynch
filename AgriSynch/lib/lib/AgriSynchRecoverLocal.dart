import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AgriSynchRecoverLocal extends StatelessWidget {
  const AgriSynchRecoverLocal({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final newPassController = TextEditingController();
    final storage = FlutterSecureStorage();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
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
                        color: Color(0xFF1DBF73),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.asset(
                      'assets/logo.png',
                      height: 100,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00A862),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
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
                    const SizedBox(height: 16),
                    const Text(
                      "Enter your registered email and a new password to reset your account.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _inputField("Email", emailController),
                    const SizedBox(height: 16),
                    _inputField("New Password", newPassController, obscure: true),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          final enteredEmail = emailController.text.trim();
                          final newPass = newPassController.text.trim();
                          final storedEmail = (await storage.read(key: 'email'))?.trim();

                          if (enteredEmail.isEmpty || newPass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill in all fields.")),
                            );
                            return;
                          }

                          if (enteredEmail != storedEmail) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Email not found.")),
                            );
                            return;
                          }

                          await storage.write(key: 'password', value: newPass);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Password reset successful!")),
                          );
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Reset Password",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFD9F2E6),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}