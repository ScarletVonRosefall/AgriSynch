import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AgriSynchLoginPage extends StatefulWidget {
  const AgriSynchLoginPage({super.key});

  @override
  State<AgriSynchLoginPage> createState() => _AgriSynchLoginPageState();
}

class _AgriSynchLoginPageState extends State<AgriSynchLoginPage> {
  final storage = FlutterSecureStorage();

  Future<bool> checkCredentials(String email, String password) async {
    final storedEmail = await storage.read(key: 'email');
    final storedPassword = await storage.read(key: 'password');
    return email == storedEmail && password == storedPassword;
  }

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final ValueNotifier<bool> isLoading = ValueNotifier(false);
    final ValueNotifier<bool> showPassword = ValueNotifier(false);

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
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Sign in to continue",
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
                      "Log in",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      "Email",
                      emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: showPassword,
                      builder: (context, value, child) {
                        return _inputField(
                          "Password",
                          passController,
                          obscure: !value,
                          suffixIcon: IconButton(
                            icon: Icon(
                              value ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () => showPassword.value = !value,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isLoading,
                        builder: (context, loading, child) {
                          return ElevatedButton(
                            onPressed: loading
    ? null
    : () async {
        final email = emailController.text.trim();
        final pass = passController.text.trim();

        if (email.isEmpty || pass.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter both email and password.")),
          );
          return;
        }

        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter a valid email address.")),
          );
          return;
        }

        isLoading.value = true;
        await Future.delayed(const Duration(seconds: 1));
        isLoading.value = false;

        // Read stored credentials and compare
        final storedEmail = (await storage.read(key: 'email'))?.trim();
        final storedPassword = (await storage.read(key: 'password'))?.trim();

        if (email == storedEmail && pass == storedPassword) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid email or password.")),
          );
        }
      },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4D3E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/recover',
                        ),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
