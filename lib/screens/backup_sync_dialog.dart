import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backup_sync_service.dart';

class BackupSyncDialog extends StatefulWidget {
  final VoidCallback onDataRestored;

  const BackupSyncDialog({
    super.key,
    required this.onDataRestored,
  });

  @override
  State<BackupSyncDialog> createState() => _BackupSyncDialogState();
}

class _BackupSyncDialogState extends State<BackupSyncDialog> {
  final TextEditingController _restoreTextController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = true;
  String? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSyncConfig();
  }

  @override
  void dispose() {
    _restoreTextController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSyncConfig() async {
    final cfg = await BackupSyncService.instance.loadConfig();
    _endpointController.text = cfg.endpointUrl;
    _apiKeyController.text = cfg.apiKey;
    if (mounted) {
      setState(() {
        _lastSyncTime = cfg.lastSyncTime;
      });
    }
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final jsonStr = await BackupSyncService.instance.createFullBackupJson();
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage = 'Full backup JSON copied to clipboard (${jsonStr.length} chars). Paste and save it securely!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Backup failed: $e';
      });
    }
  }

  Future<void> _restoreBackup() async {
    final text = _restoreTextController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Please paste valid JSON backup content into the restore box.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final counts = await BackupSyncService.instance.restoreFromJson(text);
      widget.onDataRestored();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage = 'Restore complete! Restored: ${counts.entries.map((e) => "${e.value} ${e.key}").join(", ")}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Restore failed: $e';
      });
    }
  }

  Future<void> _syncToCloud() async {
    final endpoint = _endpointController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (endpoint.isEmpty) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Please provide a valid cloud endpoint URL.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await BackupSyncService.instance.saveConfig(CloudSyncConfig(
        endpointUrl: endpoint,
        apiKey: apiKey,
      ));

      final success = await BackupSyncService.instance.syncWithCloud(
        endpointUrl: endpoint,
        apiKey: apiKey,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = success;
        _statusMessage = success
            ? 'Cloud sync succeeded! Data uploaded to remote endpoint.'
            : 'Cloud sync did not succeed.';
        _lastSyncTime = DateTime.now().toIso8601String();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Cloud sync error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.cloud_sync, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Backup & Cloud Sync',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Export, restore, or sync with remote server',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isSuccess ? Colors.green.withAlpha(80) : Colors.red.withAlpha(80),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                        color: _isSuccess ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Export Backup Section
              Text(
                '1. Local Backup (JSON)',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Copy your entire food diary, water logs, weight history, and custom foods into a single JSON backup.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Export & Copy Backup JSON'),
                  onPressed: _isLoading ? null : _exportBackup,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Restore Backup Section
              Text(
                '2. Restore from Backup',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _restoreTextController,
                maxLines: 3,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Paste backup JSON string here...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore Data from JSON'),
                  onPressed: _isLoading ? null : _restoreBackup,
                ),
              ),
              const Divider(height: 28),

              // 3. Cloud Sync Section
              Text(
                '3. Cloud Sync (Supabase / REST Endpoint)',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _endpointController,
                decoration: const InputDecoration(
                  labelText: 'Sync Endpoint URL',
                  hintText: 'https://xyz.supabase.co/rest/v1/...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API / Authorization Key (Optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (_lastSyncTime != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Last synced: ${_lastSyncTime!.substring(0, 19).replaceAll("T", " ")}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.hintColor),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: const Text('Sync Now with Cloud'),
                  onPressed: _isLoading ? null : _syncToCloud,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
