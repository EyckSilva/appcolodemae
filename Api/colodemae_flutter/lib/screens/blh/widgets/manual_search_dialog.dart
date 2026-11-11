import 'package:flutter/material.dart';

const brazilStates = [
  'AC',
  'AL',
  'AP',
  'AM',
  'BA',
  'CE',
  'DF',
  'ES',
  'GO',
  'MA',
  'MT',
  'MS',
  'MG',
  'PA',
  'PB',
  'PR',
  'PE',
  'PI',
  'RJ',
  'RN',
  'RS',
  'RO',
  'RR',
  'SC',
  'SP',
  'SE',
  'TO'
];

class ManualSearchDialog extends StatefulWidget {
  const ManualSearchDialog({super.key});
  @override
  State<ManualSearchDialog> createState() => _ManualSearchDialogState();
}

class _ManualSearchDialogState extends State<ManualSearchDialog> {
  final _form = GlobalKey<FormState>();
  final _city = TextEditingController();
  String? _state;
  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Buscar por cidade e estado'),
        content: SingleChildScrollView(
            child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                      controller: _city,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Informe a cidade.'
                          : null),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Estado (UF)'),
                      items: [
                        for (final state in brazilStates)
                          DropdownMenuItem(value: state, child: Text(state))
                      ],
                      onChanged: (value) => _state = value,
                      validator: (value) =>
                          value == null ? 'Selecione o estado.' : null),
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(
                      context, (city: _city.text.trim(), state: _state!));
                }
              },
              child: const Text('Buscar')),
        ],
      );
}
