import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String nombre;
  final String telefono;
  final String email;
  final String membresia;
  final String estadoPago;
  final List<String> contenedores;

  Client({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.membresia,
    required this.estadoPago,
    required this.contenedores,
  });

  factory Client.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      telefono: data['telefono'] ?? '',
      email: data['email'] ?? '',
      membresia: data['membresia'] ?? 'mensual',
      estadoPago: data['estadoPago'] ?? 'pagado',
      contenedores: List<String>.from(data['contenedores'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'membresia': membresia,
      'estadoPago': estadoPago,
      'contenedores': contenedores,
    };
  }
}
