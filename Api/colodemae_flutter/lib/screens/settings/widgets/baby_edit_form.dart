import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../models/baby.dart';

/// Formulário de edição do nome e da data de nascimento do bebê (RF02).
class BabyEditForm extends StatefulWidget {
  const BabyEditForm(
      {super.key,
      required this.baby,
      required this.onSave,
      required this.onCancel});

  final Baby? baby;
  final ValueChanged<Baby> onSave;
  final VoidCallback onCancel;

  @override
  State<BabyEditForm> createState() => _BabyEditFormState();
}

class _BabyEditFormState extends State<BabyEditForm> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.baby?.name ?? '');
  late DateTime _birthDate = widget.baby?.birthDate ?? DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(now.year - 2, now.month, now.day);
    final initialDate = _birthDate.isBefore(firstDate)
        ? firstDate
        : _birthDate.isAfter(today)
            ? today
            : _birthDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nome do bebê',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary),
          ),
          const SizedBox(height: 16),
          Text('Data de nascimento',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.textMuted)),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: palette.border2, width: 1.5),
              ),
              child: Text(
                formatDateBr(_birthDate),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    widget.onSave(Baby(
                      name: name.isEmpty ? widget.baby?.name ?? '' : name,
                      birthDate: _birthDate,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
