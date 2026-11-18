import 'package:flutter/material.dart';

class ModernMealSectionCard extends StatelessWidget {
  final String categoryName;
  final String emoji;
  final List<Map<String, Object?>> entries;
  final VoidCallback onAddMeal;
  final Function(int logId) onDeleteEntry;
  final Function(Map<String, Object?> entry)? onTapEntry;

  const ModernMealSectionCard({
    super.key,
    required this.categoryName,
    required this.emoji,
    required this.entries,
    required this.onAddMeal,
    required this.onDeleteEntry,
    this.onTapEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate category totals
    double totalKcal = 0;
    double totalP = 0;
    double totalC = 0;
    double totalF = 0;

    for (final r in entries) {
      final entryType = (r['entry_type'] as String?) ?? 'food';
      if (entryType == 'manual') {
        totalKcal += ((r['calories'] as num?) ?? 0).toDouble();
        totalP += ((r['protein'] as num?) ?? 0).toDouble();
        totalC += ((r['carbs'] as num?) ?? 0).toDouble();
        totalF += ((r['fat'] as num?) ?? 0).toDouble();
      } else {
        final grams = ((r['grams'] as num?) ?? 0).toDouble();
        final base = ((r['base_amount'] as num?) ?? 100).toDouble();
        final ratio = grams / (base <= 0 ? 1 : base);
        totalKcal += ((r['calories'] as num?) ?? 0).toDouble() * ratio;
        totalP += ((r['protein'] as num?) ?? 0).toDouble() * ratio;
        totalC += ((r['carbs'] as num?) ?? 0).toDouble() * ratio;
        totalF += ((r['fat'] as num?) ?? 0).toDouble() * ratio;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  categoryName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (totalKcal > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${totalKcal.round()} kcal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  color: theme.colorScheme.primary,
                  tooltip: 'Add food to $categoryName',
                  onPressed: onAddMeal,
                ),
              ],
            ),
          ),

          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onAddMeal,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.7),
                      style: BorderStyle.solid,
                    ),
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Add to $categoryName',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
              itemBuilder: (ctx, i) {
                final r = entries[i];
                final logId = (r['log_id'] as int?) ?? 0;
                final name = (r['name'] as String?) ?? 'Food';
                final time = (r['time'] as String?)?.trim() ?? '';
                final grams = ((r['grams'] as num?) ?? 100).round();
                final unit = (r['unit'] as String?) ?? 'g';

                double itemKcal = 0;
                double itemP = 0;
                double itemC = 0;
                double itemF = 0;

                final entryType = (r['entry_type'] as String?) ?? 'food';
                if (entryType == 'manual') {
                  itemKcal = ((r['calories'] as num?) ?? 0).toDouble();
                  itemP = ((r['protein'] as num?) ?? 0).toDouble();
                  itemC = ((r['carbs'] as num?) ?? 0).toDouble();
                  itemF = ((r['fat'] as num?) ?? 0).toDouble();
                } else {
                  final base = ((r['base_amount'] as num?) ?? 100).toDouble();
                  final ratio = grams / (base <= 0 ? 1 : base);
                  itemKcal = ((r['calories'] as num?) ?? 0).toDouble() * ratio;
                  itemP = ((r['protein'] as num?) ?? 0).toDouble() * ratio;
                  itemC = ((r['carbs'] as num?) ?? 0).toDouble() * ratio;
                  itemF = ((r['fat'] as num?) ?? 0).toDouble() * ratio;
                }

                return ListTile(
                  dense: true,
                  onTap: onTapEntry != null ? () => onTapEntry!(r) : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${itemKcal.round()} kcal',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '$grams$unit${time.isNotEmpty ? ' • $time' : ''}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                      const Spacer(),
                      Text(
                        'P:${itemP.round()}g C:${itemC.round()}g F:${itemF.round()}g',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () => onDeleteEntry(logId),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
