import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/bottom_action.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/navy_app_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';
import 'patients_controller.dart';
import 'widgets/patient_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final patients = ref.watch(patientsProvider);

    return Scaffold(
      appBar: NavyAppBar(
        title: 'I miei pazienti',
        subtitle: user?.fullName,
        trailing: LogoutPill(
          onTap: () => ref.read(authProvider.notifier).signOut(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                _SearchField(onChanged: (v) => setState(() => _query = v)),
                const SizedBox(height: 16),
                patients.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => EmptyState(message: 'Errore nel caricamento: $e'),
                  data: (list) {
                    final q = _query.trim().toLowerCase();
                    final filtered = q.isEmpty
                        ? list
                        : list
                            .where((p) => p.fullName.toLowerCase().contains(q))
                            .toList();
                    if (filtered.isEmpty) {
                      return const EmptyState(
                        icon: Icons.person_outline,
                        message: 'Nessun paziente ancora.\nAggiungine uno per iniziare.',
                      );
                    }
                    return Column(
                      children: [
                        for (final p in filtered)
                          PatientCard(
                            patient: p,
                            onTap: () => context.push(AppRoutes.patient(p.id)),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          BottomAction(
            child: NavyButton(
              label: 'Nuovo paziente',
              onPressed: () => context.push(AppRoutes.newPatient),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: c, width: 1.5),
        );
    return TextField(
      onChanged: onChanged,
      style: AppText.t(14),
      decoration: InputDecoration(
        hintText: 'Cerca paziente...',
        hintStyle: AppText.t(14, c: AppColors.muted2),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: border(AppColors.cardBorder),
        enabledBorder: border(AppColors.cardBorder),
        focusedBorder: border(AppColors.sky300),
      ),
    );
  }
}
