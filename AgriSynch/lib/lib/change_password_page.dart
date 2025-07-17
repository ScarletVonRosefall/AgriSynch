import 'package:flutter/material.dart';

class ChangePasswordPage
    extends
        StatefulWidget {
  const ChangePasswordPage({
    Key? key,
  }) : super(
         key: key,
       );

  @override
  State<
    ChangePasswordPage
  >
  createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends
        State<
          ChangePasswordPage
        > {
  final _formKey =
      GlobalKey<
        FormState
      >();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed!',
          ),
        ),
      );
      Navigator.of(
        context,
      ).pop();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          24.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 24,
              ),
              const Text(
                'New Password',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureNew = !_obscureNew,
                    ),
                  ),
                ),
                validator:
                    (
                      value,
                    ) {
                      if (value ==
                              null ||
                          value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length <
                          6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
              ),
              const SizedBox(
                height: 18,
              ),
              const Text(
                'Confirm Password',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirm = !_obscureConfirm,
                    ),
                  ),
                ),
                validator:
                    (
                      value,
                    ) {
                      if (value ==
                              null ||
                          value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value !=
                          _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
              ),
              const SizedBox(
                height: 28,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  child: const Text(
                    'Change Password',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
