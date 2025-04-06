import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db_service.dart';
import '../theme/theme.dart';

class AddEmployeeDialog extends StatefulWidget {
  final bool embed;
  const AddEmployeeDialog({super.key, this.embed = false});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController profitPercentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> availableRoles = [];
  String? selectedRole;

  bool get selectedRoleGetsPercent {
    final role = availableRoles.firstWhere(
      (r) => r['role'] == selectedRole,
      orElse: () => {'getsPercent': false},
    );
    return role['getsPercent'] == true;
  }

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('customRolesJson');
    if (saved != null) {
      availableRoles = List<Map<String, dynamic>>.from(json.decode(saved));
    } else {
      availableRoles = [
        {'role': 'Employee', 'getsPercent': false},
        {'role': 'Manager', 'getsPercent': true},
        {'role': 'Owner', 'getsPercent': true},
      ];
    }

    setState(() {
      selectedRole = availableRoles.first['role'];
    });
  }

  Future<bool> isDuplicateName(String name) async {
    final allEmployees = await LocalDBService.getAllWorkers();
    final input = name.toLowerCase().trim();
    return allEmployees.any(
      (e) => (e['name'] as String).toLowerCase().trim() == input,
    );
  }

  Future<void> saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final bool duplicate = await isDuplicateName(name);
    if (duplicate) {
      if (context.mounted) {
        AppTheme.showErrorSnackbar(
          context,
          "❌ This employee name already exists.",
        );
      }
      return;
    }

    final double salary = double.parse(salaryController.text.trim());
    final String id = const Uuid().v4();

    final employeeData = {
      'id': id,
      'name': name,
      'salary': salary,
      'role': selectedRole,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (selectedRoleGetsPercent) {
      final double profitPercent =
          double.tryParse(profitPercentController.text.trim()) ?? 0;
      employeeData['profitPercent'] = profitPercent;
    }

    try {
      await LocalDBService.addWorker(employeeData);
      if (!context.mounted) return;
      if (!widget.embed) Navigator.of(context).pop();
      AppTheme.showSuccessSnackbar(context, "✅ Employee saved successfully!");
    } catch (e) {
      AppTheme.showErrorSnackbar(context, "❌ Failed to save employee: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFBF9F6), Color(0xFFF4EFE7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 520,
            margin: const EdgeInsets.symmetric(vertical: 40),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    "👤 Add New Employee",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Fill the employee’s details below 👇",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 28),

                  // Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Name',
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter name'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  // Salary
                  TextFormField(
                    controller: salaryController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Salary',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter salary';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    icon: const Icon(Icons.arrow_drop_down),
                    items:
                        availableRoles
                            .map(
                              (r) => DropdownMenuItem<String>(
                                value: r['role'],
                                child: Text(r['role']),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (val) =>
                            setState(() => selectedRole = val ?? selectedRole),
                  ),
                  const SizedBox(height: 16),

                  // Profit %
                  if (selectedRoleGetsPercent)
                    TextFormField(
                      controller: profitPercentController,
                      decoration: const InputDecoration(
                        labelText: 'Profit % (optional)',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!widget.embed)
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: saveEmployee,
                          icon: const Text("➕", style: TextStyle(fontSize: 18)),
                          label: const Text("Add"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
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
      ),
    );

    return widget.embed
        ? content
        : Dialog(insetPadding: const EdgeInsets.all(40), child: content);
  }
}
