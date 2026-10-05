import 'package:flutter/material.dart';

import '../models/plant.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _species = TextEditingController();
  final _days = TextEditingController(text: '7');

  @override
  void dispose() {
    _nickname.dispose();
    _species.dispose();
    _days.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(Plant(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nickname: _nickname.text.trim(),
      species: _species.text.trim(),
      waterEveryDays: int.parse(_days.text),
      lastWatered: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Plant')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nickname,
              decoration: const InputDecoration(labelText: 'Nickname'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _species,
              decoration: const InputDecoration(labelText: 'Species'),
            ),
            TextFormField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Water every (days)'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1) ? 'Enter a number of days' : null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save plant')),
          ],
        ),
      ),
    );
  }
}
