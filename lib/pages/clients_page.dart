import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clientsStream =
        FirebaseFirestore.instance.collection('users').snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Clientes', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Cliente'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => ClientDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: clientsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No hay clientes registrados."));
                  }

                  final clients = snapshot.data!.docs;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Teléfono')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Membresía')),
                        DataColumn(label: Text('Estado Pago')),
                        DataColumn(label: Text('Contenedores')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: clients.map((doc) {
                        final data = doc.data()! as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text(data['nombre'] ?? '')),
                          DataCell(Text(data['telefono'] ?? '')),
                          DataCell(Text(data['email'] ?? '')),
                          DataCell(Text(data['membresia'] ?? '')),
                          DataCell(Text(data['estadoPago'] ?? '')),
                          DataCell(Text(
                              (data['contenedores'] as List<dynamic>?)
                                      ?.join(', ') ??
                                  '')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) =>
                                      ClientDialog(docId: doc.id, existing: data),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDelete(context, doc.id),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  );
                },
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
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                await usersRef.doc(docId).delete();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cliente eliminado')));
              },
              child: const Text('Eliminar'),
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
  final Map<String, dynamic>? existing;

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

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    nombreCtrl = TextEditingController(text: e?['nombre'] ?? '');
    telCtrl = TextEditingController(text: e?['telefono'] ?? '');
    emailCtrl = TextEditingController(text: e?['email'] ?? '');
    contenedoresCtrl = TextEditingController(
        text: (e?['contenedores'] as List<dynamic>?)?.join(', ') ?? '');
    membresia = e?['membresia'] ?? 'mensual';
    estadoPago = e?['estadoPago'] ?? 'pagado';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;
    final usersRef = FirebaseFirestore.instance.collection('users');

    return AlertDialog(
      title: Text(isEdit ? 'Editar Cliente' : 'Nuevo Cliente'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: telCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: contenedoresCtrl,
                decoration:
                    const InputDecoration(labelText: 'Contenedores (coma)'),
              ),
              DropdownButtonFormField<String>(
                value: membresia,
                items: const [
                  DropdownMenuItem(child: Text('mensual'), value: 'mensual'),
                  DropdownMenuItem(child: Text('anual'), value: 'anual'),
                ],
                onChanged: (v) => setState(() => membresia = v!),
                decoration: const InputDecoration(labelText: 'Membresía'),
              ),
              DropdownButtonFormField<String>(
                value: estadoPago,
                items: const [
                  DropdownMenuItem(child: Text('pagado'), value: 'pagado'),
                  DropdownMenuItem(child: Text('pendiente'), value: 'pendiente'),
                  DropdownMenuItem(child: Text('cancelado'), value: 'cancelado'),
                ],
                onChanged: (v) => setState(() => estadoPago = v!),
                decoration: const InputDecoration(labelText: 'Estado de Pago'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final contList = contenedoresCtrl.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();

            final data = {
              'nombre': nombreCtrl.text.trim(),
              'telefono': telCtrl.text.trim(),
              'email': emailCtrl.text.trim(),
              'membresia': membresia,
              'estadoPago': estadoPago,
              'contenedores': contList,
              'fechaRegistro': FieldValue.serverTimestamp(),
            };

            try {
              if (isEdit) {
                await usersRef.doc(widget.docId).update(data);
              } else {
                await usersRef.add(data);
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isEdit
                      ? 'Cliente actualizado'
                      : 'Cliente creado')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al guardar')));
            }
          },
          child: Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
