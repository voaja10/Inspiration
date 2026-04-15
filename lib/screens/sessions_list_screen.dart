import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../utils/validators.dart';
import 'backup_restore_screen.dart';
import 'session_detail_screen.dart';

class SessionsListScreen extends ConsumerWidget {
  const SessionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Sessions'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen()));
            },
            icon: const Icon(Icons.backup),
          ),
        ],
      ),
      body: sessions.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final s = items[i];
            return ListTile(
              title: Text(s.name),
              subtitle: Text('Status: ${s.status.name}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s)));
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final formKey = GlobalKey<FormState>();
          final ctrl = TextEditingController();
          final created = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('New Session'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: ctrl,
                  decoration: const InputDecoration(hintText: 'e.g. FTS TRIP 2026', labelText: 'Session Name'),
                  validator: FormValidators.validateSessionName,
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          );
          if (created == true && ctrl.text.trim().isNotEmpty) {
            await ref.read(repositoryProvider).createSession(ctrl.text.trim());
            ref.invalidate(sessionsProvider);
          }
        },
        label: const Text('New Session'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
