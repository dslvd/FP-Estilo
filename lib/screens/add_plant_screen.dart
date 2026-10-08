import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant.dart';
import '../providers/plant_provider.dart';

/// "Add Plant" screen, which doubles as the edit form.
///
/// When it is opened with a [Plant] in `ModalRoute.arguments` it pre-fills the
/// fields and saves over that plant; opened with no argument it creates a new
/// one. This is the Create and Update half of the app's CRUD.
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

  Plant? _editing;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editing != null) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Plant) {
      _editing = arg;
      _nickname.text = arg.nickname;
      _species.text = arg.species;
      _days.text = arg.waterEveryDays.toString();
    }
  }

  @override
  void dispose() {
    _nickname.dispose();
    _species.dispose();
    _days.dispose();
    super.dispose();
  }

  bool get _isEditing => _editing != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<PlantProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final nickname = _nickname.text.trim();
    final species = _species.text.trim();
    final days = int.parse(_days.text.trim());

    if (_isEditing) {
      await provider.update(
        _editing!.copyWith(
          nickname: nickname,
          species: species,
          waterEveryDays: days,
        ),
      );
    } else {
      await provider.add(
        Plant(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          nickname: nickname,
          species: species,
          waterEveryDays: days,
          lastWatered: DateTime.now(),
        ),
      );
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? '$nickname updated' : '$nickname added to your plants',
          ),
        ),
      );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Plant' : 'New Plant')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('About this plant'),
            TextFormField(
              controller: _nickname,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                helperText: 'What you call it at home',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Give your plant a nickname';
                if (value.length > 40) return 'Keep it under 40 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _species,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Species (optional)',
                helperText: 'e.g. Monstera deliciosa',
                prefixIcon: Icon(Icons.science_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Water every (days)',
                helperText: 'Between 1 and 365 days',
                prefixIcon: Icon(Icons.water_drop_outlined),
              ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null) return 'Enter a whole number of days';
                if (n < 1) return 'Must be at least 1 day';
                if (n > 365) return 'Must be 365 days or fewer';
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isEditing ? 'Save changes' : 'Save plant'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small private helper so the form reads as labelled groups.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
