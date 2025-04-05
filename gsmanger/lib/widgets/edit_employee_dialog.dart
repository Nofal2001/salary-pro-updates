import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_db_service.dart';
import '../theme/theme.dart';

class EditEmployeeDialog extends StatefulWidget {
  final Map<String, dynamic> worker;
  final VoidCallback onSaved;

  const EditEmployeeDialog({
    super.key,
    required this.worker,
    required this.onSaved,
  });

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController salaryController;
  late TextEditingController profitPercentController;

  List<Map<String, dynamic>> customRoles = [];
  String role = 'Employee';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.worker['name']);
    salaryController = TextEditingController(
      text: widget.worker['salary'].toString(),
    );
    profitPercentController = TextEditingController(
      text: (widget.worker['profitPercent'] ?? '').toString(),
    );
    role = widget.worker['role'];
    loadRoles();
  }

  Future<void> loadRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('customRolesJson');

    if (saved != null) {
      customRoles = List<Map<String, dynamic>>.from(json.decode(saved));
    } else {
      customRoles = [
        {'role': 'Employee', 'getsPercent': false},
        {'role': 'Manager', 'getsPercent': true},
        {'role': 'Owner', 'getsPercent': true},
      ];
    }

    setState(() {
      // in case old role doesn't exist in the updated role list
      final found = customRoles.any((r) => r['role'] == role);
      if (!found) role = customRoles.first['role'];
    });
  }

  bool roleGetsPercent(String roleName) {
    final match = customRoles.firstWhere(
      (r) => r['role'] == roleName,
      orElse: () => {'getsPercent': false},
    );
    return match['getsPercent'] == true;
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedEmployee = {
      'id': widget.worker['id'],
      'name': nameController.text.trim(),
      'salary': double.parse(salaryController.text.trim()),
      'role': role,
      'profitPercent':
          roleGetsPercent(role)
              ? double.tryParse(profitPercentController.text) ?? 0
              : null,
      'createdAt': widget.worker['createdAt'],
    };

    final db = await LocalDBService.database;
    await db.update(
      'workers',
      updatedEmployee,
      where: 'id = ?',
      whereArgs: [widget.worker['id']],
    );

    if (!context.mounted) return;
    Navigator.pop(context);
    widget.onSaved(); // refresh main screen
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(40),
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "✏️ Edit Employee",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Employee Name'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: salaryController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Salary',
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value == null || double.tryParse(value) == null
                              ? 'Invalid number'
                              : null,
                ),
                const SizedBox(height: 12),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items:
                      customRoles
                          .map(
                            (r) => DropdownMenuItem<String>(
                              value: r['role'],
                              child: Text(r['role']),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => role = value ?? role),
                ),
                const SizedBox(height: 12),

                // Profit % Field (only if role getsPercent)
                if (roleGetsPercent(role))
                  Column(
                    children: [
                      TextFormField(
                        controller: profitPercentController,
                        decoration: const InputDecoration(
                          labelText: 'Profit %',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("❌ Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: saveChanges,
                      icon: const Text("💾", style: TextStyle(fontSize: 18)),
                      label: const Text("Save Changes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
