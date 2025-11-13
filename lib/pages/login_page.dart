import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onGoToSignup;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    required this.onGoToSignup,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      widget.onLoginSuccess();
    } on FirebaseAuthException catch (e) {
      String msg = switch (e.code) {
        'user-not-found' => 'Usuario no encontrado.',
        'wrong-password' => 'Contraseña incorrecta.',
        'invalid-email' => 'Correo inválido.',
        _ => 'Error: ${e.message}',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const morado = Color(0xFFA18CD1);
    const azul = Color(0xFF758EB7);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            return Container(
              margin: const EdgeInsets.all(20),
              height: 520,
              width: isMobile ? double.infinity : 900,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 🔹 LADO IZQUIERDO: FORMULARIO
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: azul,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text("¿No tienes cuenta? "),
                                  GestureDetector(
                                    onTap: widget.onGoToSignup,
                                    child: const Text(
                                      "Crea tu cuenta",
                                      style: TextStyle(
                                          color: morado,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              // 🔹 Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                  'Correo electrónico',
                                  Icons.email,
                                ),
                                validator: (v) {
                                  if (v == null || !v.contains('@')) {
                                    return 'Introduce un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // 🔹 Contraseña
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: _inputDecoration(
                                  'Contraseña',
                                  Icons.lock,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() =>
                                        _isPasswordVisible =
                                            !_isPasswordVisible),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              // 🔹 Botón de Login
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: azul,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Text(
                                          "LOGIN",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 🔹 LADO DERECHO: Bienvenida
                  if (!isMobile)
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [morado, azul],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(20),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Smart Storage Garage",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 25),
                                // 🔹 LOGO debajo del texto
                                Image.asset(
                                  'assets/logo.png', // <-- cambia a la ruta de tu logo
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF758EB7)),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF758EB7), width: 2),
      ),
    );
  }

  Widget _socialButton({required IconData icon, required Color color}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
