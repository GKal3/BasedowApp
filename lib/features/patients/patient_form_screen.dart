import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/patient.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/form_error_box.dart';
import '../../shared/widgets/navy_app_bar.dart';
import '../../theme/app_colors.dart';
import 'patients_controller.dart';

/// Form per creare un paziente, oppure modificarlo se [patientId] è valorizzato.
class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key, this.patientId});

  final String? patientId;

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _nascita = TextEditingController();
  final _note = TextEditingController();
  DateTime? _dob;
  Patient? _editing;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.patientId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.patientId;
    if (id != null) {
      final p = ref.read(patientProvider(id));
      if (p != null) {
        _editing = p;
        _nome.text = p.nome;
        _cognome.text = p.cognome;
        _note.text = p.note;
        _dob = p.dataNascita;
        _nascita.text = p.dataNascita == null ? '' : formatDate(p.dataNascita);
      }
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _cognome.dispose();
    _nascita.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 40, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _nascita.text = formatDate(picked);
      });
    }
  }

  Future<void> _save() async {
    final nome = _nome.text.trim();
    final cognome = _cognome.text.trim();
    if (nome.isEmpty || cognome.isEmpty) {
      setState(() => _error = 'Inserisci almeno nome e cognome.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });

    final ctrl = ref.read(patientsProvider.notifier);
    final editing = _editing;
    if (editing != null) {
      await ctrl.save(editing.copyWith(
        nome: nome,
        cognome: cognome,
        dataNascita: _dob,
        note: _note.text.trim(),
      ));
    } else {
      await ctrl.add(
        nome: nome,
        cognome: cognome,
        dataNascita: _dob,
        note: _note.text.trim(),
      );
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavyAppBar(
        title: _isEdit ? 'Modifica paziente' : 'Nuovo paziente',
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormErrorBox(message: _error),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Nome',
                    controller: _nome,
                    hint: 'Es. Giulia',
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Cognome',
                    controller: _cognome,
                    hint: 'Es. Bianchi',
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            AppTextField(
              label: 'Data di nascita',
              controller: _nascita,
              hint: 'gg/mm/aaaa',
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.muted,
              ),
            ),
            AppTextField(
              label: 'Note cliniche (opzionale)',
              controller: _note,
              hint: 'Anamnesi, terapia in corso, altre note...',
              keyboardType: TextInputType.multiline,
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 6),
            PrimaryButton(
              label: 'Salva paziente',
              onPressed: _save,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
