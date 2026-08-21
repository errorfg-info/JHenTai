import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jhentai/src/widget/eh_group_name_selector.dart';

typedef NHentaiArchiveDialogResult = ({String format, String group});

class NHentaiArchiveDialog extends StatefulWidget {
  final String currentGroup;
  final List<String> candidates;

  const NHentaiArchiveDialog({
    super.key,
    required this.currentGroup,
    required this.candidates,
  });

  @override
  State<NHentaiArchiveDialog> createState() => _NHentaiArchiveDialogState();
}

class _NHentaiArchiveDialogState extends State<NHentaiArchiveDialog> {
  late String group = widget.currentGroup;
  String format = 'zip';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('chooseArchive'.tr),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EHGroupNameSelector(
              candidates: widget.candidates,
              currentGroup: group,
              listener: (value) => group = value,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: format,
              decoration: InputDecoration(labelText: 'nhentaiArchiveFormat'.tr),
              items: const [
                DropdownMenuItem(value: 'zip', child: Text('ZIP')),
                DropdownMenuItem(value: 'cbz', child: Text('CBZ')),
              ],
              onChanged: (value) => setState(() => format = value ?? 'zip'),
            ),
            const SizedBox(height: 12),
            Text(
              'nhentaiOfficialArchiveHint'.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        FilledButton(
          onPressed: group.trim().isEmpty
              ? null
              : () => Get.back<NHentaiArchiveDialogResult>(
                  result: (format: format, group: group.trim()),
                ),
          child: Text('download'.tr),
        ),
      ],
    );
  }
}
