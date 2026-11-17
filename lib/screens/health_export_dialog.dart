import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/health_export_service.dart';

class HealthExportDialog extends StatefulWidget {
  const HealthExportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const HealthExportDialog(),
    );
  }

  @override
  State<HealthExportDialog> createState() => _HealthExportDialogState();
}

class _HealthExportDialogState extends State<HealthExportDialog> {
  int _selectedDays = 14;
  bool _isCsv = true;
  bool _isLoading = false;
  String _previewContent = '';

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final text = _isCsv
        ? await HealthExportService.instance.generateCsvExport(days: _selectedDays)
        : await HealthExportService.instance.generateMedicalSummary(days: _selectedDays);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _previewContent = text;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _previewContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard! Ready to paste into an email, spreadsheet, or doc.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.description_outlined, color: Colors.teal),
          SizedBox(width: 8),
          Text('Clinical & Health Export'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedDays,
                    decoration: const InputDecoration(labelText: 'Timeframe', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 Days')),
                      DropdownMenuItem(value: 14, child: Text('14 Days (2 weeks)')),
                      DropdownMenuItem(value: 30, child: Text('30 Days (Month)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDays = val);
                        _loadReport();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<bool>(
                    value: _isCsv,
                    decoration: const InputDecoration(labelText: 'Format', isDense: true),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('CSV Spreadsheet')),
                      DropdownMenuItem(value: false, child: Text('Doctor Summary')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _isCsv = val);
                        _loadReport();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: SelectableText(
                          _previewContent,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _copyToClipboard,
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy to Clipboard'),
        ),
      ],
    );
  }
}
