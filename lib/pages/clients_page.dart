import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 importante para los inputFormatters
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clientsStream =
        FirebaseFirestore.instance.collection('users').snapshots();

    // 🎨 Colores de tu login
    const morado = Color(0xFFA18CD1);
    const azul = Color(0xFF758EB7);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  'Clientes',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: morado,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Cliente'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ClientDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: clientsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text('No hay clientes registrados.'));
                            }

                            final clients = snapshot.data!.docs
                                .map((doc) => Client.fromDoc(doc))
                                .toList();

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 24,
                                  horizontalMargin: 16,
                                  headingRowColor:
                                      MaterialStateProperty.all(morado),
                                  dataRowColor:
                                      MaterialStateProperty.resolveWith(
                                    (states) {
                                      if (states
                                          .contains(MaterialState.hovered)) {
                                        return azul.withOpacity(0.08);
                                      }
                                      return Colors.white;
                                    },
                                  ),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  dataTextStyle: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                  border: TableBorder(
                                    horizontalInside: BorderSide(
                                      color: morado.withOpacity(0.2),
                                      width: 0.7,
                                    ),
                                    verticalInside: BorderSide(
                                      color: morado.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Nombre')),
                                    DataColumn(label: Text('Teléfono')),
                                    DataColumn(label: Text('Email')),
                                    DataColumn(label: Text('Membresía')),
                                    DataColumn(label: Text('Estado Pago')),
                                    DataColumn(label: Text('Contenedores')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows: clients.map((client) {
                                    // 🎨 Color según estado de pago
                                    Color estadoColor;
                                    switch (client.estadoPago.toLowerCase()) {
                                      case 'pagado':
                                        estadoColor = Colors.green;
                                        break;
                                      case 'pendiente':
                                        estadoColor = Colors.amber;
                                        break;
                                      case 'cancelado':
                                        estadoColor = Colors.red;
                                        break;
                                      default:
                                        estadoColor = Colors.black87;
                                    }

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(client.nombre)),
                                        DataCell(Text(client.telefono)),
                                        DataCell(Text(client.email)),
                                        DataCell(Text(client.membresia)),
                                        DataCell(
                                          Text(
                                            client.estadoPago,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: estadoColor,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            client.contenedores.join(', '),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                color: morado,
                                                onPressed: () => showDialog(
                                                  context: context,
                                                  builder: (_) => ClientDialog(
                                                    docId: client.id,
                                                    existing: client,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                color: Colors.red[400],
                                                onPressed: () =>
                                                    _confirmDelete(
                                                        context, client.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    final usersRef = FirebaseFirestore.instance.collection('users');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
              '¿Eliminar este cliente? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await usersRef.doc(docId).delete();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente eliminado')),
                );
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// DIALOGO PARA CREAR O EDITAR CLIENTES
class ClientDialog extends StatefulWidget {
  final String? docId;
  final Client? existing;

  const ClientDialog({this.docId, this.existing, super.key});

  @override
  State<ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<ClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombreCtrl;
  late TextEditingController telCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController contenedoresCtrl;
  String membresia = 'mensual';
  String estadoPago = 'pagado';

  // 👉 cambia esto si quieres otro dominio
  static const String allowedDomain = '@gmail.com';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    telCtrl = TextEditingController(text: e?.telefono ?? '');
    emailCtrl = TextEditingController(text: e?.email ?? '');
    contenedoresCtrl =
        TextEditingController(text: e?.contenedores.join(', ') ?? '');
    membresia = e?.membresia ?? 'mensual';
    estadoPago = e?.estadoPago ?? 'pagado';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;
    final usersRef = FirebaseFirestore.instance.collection('users');

    const morado = Color(0xFFA18CD1);
    const azul = Color(0xFF758EB7);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Header tipo “card” con degradado
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  colors: [morado, azul],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Botón de cerrar
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEdit ? 'Editar cliente' : 'Nuevo cliente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Indicador de pasos “fake” para el estilo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stepDot(active: true),
                      const SizedBox(width: 8),
                      _stepDot(active: false),
                      const SizedBox(width: 8),
                      _stepDot(active: false),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // 🔹 Contenido del formulario
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),

                      // Teléfono con solo dígitos y 10 caracteres
                      TextFormField(
                        controller: telCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Requerido';
                          if (value.length != 10) {
                            return 'El teléfono debe tener 10 números';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // EMAIL con dominio restringido
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = v?.trim() ?? '';

                          if (value.isEmpty) {
                            return 'Requerido';
                          }

                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Correo electrónico no válido';
                          }

                          // Solo permitir un dominio específico
                          if (!value.toLowerCase().endsWith(
                                allowedDomain.toLowerCase(),
                              )) {
                            return 'Solo se permiten correos $allowedDomain';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: contenedoresCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contenedores (separados por coma)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: membresia,
                              decoration: const InputDecoration(
                                labelText: 'Membresía',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'mensual', child: Text('mensual')),
                                DropdownMenuItem(
                                    value: 'anual', child: Text('anual')),
                              ],
                              onChanged: (v) => setState(() {
                                membresia = v ?? 'mensual';
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: estadoPago,
                              decoration: const InputDecoration(
                                labelText: 'Estado de pago',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'pagado', child: Text('pagado')),
                                DropdownMenuItem(
                                    value: 'pendiente',
                                    child: Text('pendiente')),
                                DropdownMenuItem(
                                    value: 'cancelado',
                                    child: Text('cancelado')),
                              ],
                              onChanged: (v) => setState(() {
                                estadoPago = v ?? 'pagado';
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // 🔹 Botones inferiores tipo “Continue”
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: morado,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final contList = contenedoresCtrl.text
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();

                          final clientData = Client(
                            id: widget.docId ?? '',
                            nombre: nombreCtrl.text.trim(),
                            telefono: telCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            membresia: membresia,
                            estadoPago: estadoPago,
                            contenedores: contList,
                          );

                          try {
                            if (isEdit) {
                              await usersRef
                                  .doc(widget.docId)
                                  .update(clientData.toMap());
                            } else {
                              await usersRef.add(clientData.toMap());
                            }
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit
                                    ? 'Cliente actualizado'
                                    : 'Cliente creado'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Error al guardar')),
                            );
                          }
                        },
                        child: Text(isEdit ? 'Guardar' : 'Crear'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔸 Puntos del stepper superior (solo decorativo)
  Widget _stepDot({required bool active}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(active ? 1 : 0.6),
          width: 2,
        ),
        color: active ? Colors.white : Colors.transparent,
      ),
    );
  }
}
