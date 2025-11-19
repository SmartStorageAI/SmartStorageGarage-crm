import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/container.dart';
import '../models/client.dart';

class ContainersPage extends StatelessWidget {
  const ContainersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final containersStream =
        FirebaseFirestore.instance.collection('containers').snapshots();
    final usersRef = FirebaseFirestore.instance.collection('users');
    final containersRef = FirebaseFirestore.instance.collection('containers');

    // 🎨 Colores fijos para esta página
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
                  'Contenedores',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: morado,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Contenedor'),
                  onPressed: () async {
                    final usersSnapshot = await usersRef.get();
                    final clients = usersSnapshot.docs
                        .map((d) => Client.fromDoc(d).nombre)
                        .toList();

                    showDialog(
                      context: context,
                      builder: (_) => ContainerDialog(clients: clients),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: containersStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text(
                                      'No hay contenedores registrados.'));
                            }

                            final containers = snapshot.data!.docs
                                .map((doc) => ContainerModel.fromDoc(doc))
                                .toList();

                            return SingleChildScrollView(
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
                                  DataColumn(label: Text('Cliente')),
                                  DataColumn(label: Text('Tamaño')),
                                  DataColumn(label: Text('Ocupado')),
                                  DataColumn(label: Text('Acciones')),
                                ],
                                rows: containers.map((container) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(container.nombre)),
                                      DataCell(Text(container.cliente)),
                                      DataCell(Text(container.size)),
                                      DataCell(
                                        IconButton(
                                          tooltip: container.status
                                              ? 'Marcar como libre'
                                              : 'Marcar como ocupado',
                                          icon: Icon(
                                            container.status
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: container.status
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          onPressed: () async {
                                            await containersRef
                                                .doc(container.id)
                                                .update({
                                              'status': !container.status,
                                            });
                                          },
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              color: morado,
                                              onPressed: () async {
                                                final usersSnapshot =
                                                    await usersRef.get();
                                                final clients =
                                                    usersSnapshot.docs
                                                        .map((d) =>
                                                            Client.fromDoc(d)
                                                                .nombre)
                                                        .toList();

                                                showDialog(
                                                  context: context,
                                                  builder: (_) =>
                                                      ContainerDialog(
                                                    clients: clients,
                                                    docId: container.id,
                                                    existing: container,
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              color: Colors.red[400],
                                              onPressed: () =>
                                                  _confirmDelete(context,
                                                      container.id),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
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
    final containersRef =
        FirebaseFirestore.instance.collection('containers');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
              '¿Eliminar este contenedor? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await containersRef.doc(docId).delete();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contenedor eliminado')),
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

/// DIALOGO PARA CREAR O EDITAR CONTENEDORES
class ContainerDialog extends StatefulWidget {
  final List<String> clients;
  final String? docId;
  final ContainerModel? existing;

  const ContainerDialog({
    required this.clients,
    this.docId,
    this.existing,
    super.key,
  });

  @override
  State<ContainerDialog> createState() => _ContainerDialogState();
}

class _ContainerDialogState extends State<ContainerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombreCtrl;
  late TextEditingController sizeCtrl;
  String? cliente;
  bool status = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    sizeCtrl = TextEditingController(text: e?.size ?? '');
    cliente = e?.cliente;
    status = e?.status ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    final containersRef =
        FirebaseFirestore.instance.collection('containers');
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
            // 🔹 Header con degradado (igual que en clientes)
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
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEdit ? 'Editar contenedor' : 'Nuevo contenedor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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

            // 🔹 Formulario
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
                          labelText: 'Nombre del contenedor',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sizeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tamaño (ej. 4m x 3m)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🔽 Dropdown de cliente SIN tipos nulos para evitar error
                      DropdownButtonFormField<String>(
                        value: cliente ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Cliente asignado',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Sin cliente'),
                          ),
                          ...widget.clients.map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            cliente =
                                (value == null || value.isEmpty) ? null : value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '¿Está ocupado?',
                            style: TextStyle(fontSize: 14),
                          ),
                          Switch(
                            value: status,
                            activeColor: morado,
                            onChanged: (v) => setState(() => status = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🔹 Botones inferiores
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

                          final data = ContainerModel(
                            id: widget.docId ?? '',
                            nombre: nombreCtrl.text.trim(),
                            cliente: cliente ?? '',
                            size: sizeCtrl.text.trim(),
                            status: status,
                          );

                          try {
                            if (isEdit) {
                              await containersRef
                                  .doc(widget.docId)
                                  .update(data.toMap());
                            } else {
                              await containersRef.add(data.toMap());
                            }

                            // Actualizar contenedores en la colección de users
                            if (cliente != null && cliente!.isNotEmpty) {
                              final clientDoc = await usersRef
                                  .where('nombre', isEqualTo: cliente)
                                  .get();
                              if (clientDoc.docs.isNotEmpty) {
                                final clientId = clientDoc.docs.first.id;
                                await usersRef.doc(clientId).update({
                                  'contenedores': [nombreCtrl.text.trim()],
                                });
                              }
                            }

                            if (!mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit
                                    ? 'Contenedor actualizado'
                                    : 'Contenedor creado'),
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

  // 🔸 Puntitos del “stepper” (decorativo)
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
