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

    const primaryColor = Color(0xFF7E57C2); // morado
    const accentColor = Color(0xFF42A5F5); // azul

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  'Contenedores',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
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
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                                      "No hay contenedores registrados."));
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
                                    MaterialStateProperty.all(primaryColor),
                                dataRowColor:
                                    MaterialStateProperty.resolveWith(
                                  (states) {
                                    if (states
                                        .contains(MaterialState.hovered)) {
                                      return accentColor.withOpacity(0.08);
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
                                    color: primaryColor.withOpacity(0.2),
                                    width: 0.7,
                                  ),
                                  verticalInside: BorderSide(
                                    color: primaryColor.withOpacity(0.1),
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
                                      // ----- Botón interactivo OCUPADO -----
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
                                            // Cambia el booleano en Firestore
                                            await containersRef
                                                .doc(container.id)
                                                .update({
                                              'status': !container.status,
                                            });
                                            // El StreamBuilder se recarga solo
                                          },
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              color: primaryColor,
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
                                              onPressed: () => _confirmDelete(
                                                  context, container.id),
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
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                await containersRef.doc(docId).delete();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contenedor eliminado')));
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

  const ContainerDialog(
      {required this.clients, this.docId, this.existing, super.key});

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

    const primaryColor = Color(0xFF7E57C2);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Editar Contenedor' : 'Nuevo Contenedor',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
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
                controller: sizeCtrl,
                decoration: const InputDecoration(labelText: 'Tamaño'),
              ),
              DropdownButtonFormField<String>(
                value: cliente,
                items: [null, ...widget.clients]
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c ?? 'Sin cliente'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => cliente = v),
                decoration: const InputDecoration(labelText: 'Cliente'),
              ),
              SwitchListTile(
                title: const Text('Ocupado'),
                value: status,
                onChanged: (v) => setState(() => status = v),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                await containersRef.doc(widget.docId).update(data.toMap());
              } else {
                await containersRef.add(data.toMap());
              }

              // Actualizar contenedores en la colección de users
              if (cliente != null && cliente!.isNotEmpty) {
                final clientDoc =
                    await usersRef.where('nombre', isEqualTo: cliente).get();
                if (clientDoc.docs.isNotEmpty) {
                  final clientId = clientDoc.docs.first.id;
                  await usersRef.doc(clientId).update({
                    'contenedores': [nombreCtrl.text.trim()],
                  });
                }
              }

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isEdit
                      ? 'Contenedor actualizado'
                      : 'Contenedor creado')));
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
