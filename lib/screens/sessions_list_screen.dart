import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../utils/strings.dart';
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
        title: const Text(AppStrings.appTitle),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen()));
            },
            icon: const Icon(Icons.backup),
            tooltip: AppStrings.backupRestore,
          ),
        ],
      ),
      body: sessions.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noData,
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez une nouvelle session',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final s = items[i];
              final isClosed = s.status.name == 'closed';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                elevation: 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Icon(
                    isClosed ? Icons.lock : Icons.folder,
                    color: isClosed ? Colors.red : Colors.blue,
                  ),
                  title: Text(
                    s.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isClosed ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isClosed ? Colors.red : Colors.green,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            isClosed ? AppStrings.closed : AppStrings.open,
                            style: TextStyle(
                              fontSize: 12,
                              color: isClosed ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s)));
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(AppStrings.error),
              const SizedBox(height: 8),
              Text(e.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final formKey = GlobalKey<FormState>();
          final ctrl = TextEditingController();
          final created = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(AppStrings.newSession),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    hintText: 'ex. FTS VOYAGE 2026',
                    labelText: AppStrings.sessionName,
                  ),
                  validator: FormValidators.validateSessionName,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text(AppStrings.create),
                ),
              ],
            ),
          );
          if (created == true && ctrl.text.trim().isNotEmpty) {
            await ref.read(repositoryProvider).createSession(ctrl.text.trim());
            ref.invalidate(sessionsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.add),
      ),
    );
  }
}
