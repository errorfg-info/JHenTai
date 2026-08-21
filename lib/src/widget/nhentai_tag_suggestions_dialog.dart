import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jhentai/src/model/nhentai_api_models.dart';

class NHentaiTagSuggestionsDialog extends StatelessWidget {
  final List<NHentaiTagSuggestion> suggestions;
  final int totalCount;

  const NHentaiTagSuggestionsDialog({
    super.key,
    required this.suggestions,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${'nhentaiTagSuggestions'.tr} ($totalCount)'),
      content: SizedBox(
        width: 520,
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.visibility_outlined),
              title: Text('nhentaiSuggestionsReadOnly'.tr),
            ),
            Expanded(
              child: suggestions.isEmpty
                  ? Center(child: Text('noData'.tr))
                  : ListView.separated(
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        NHentaiTagSuggestion suggestion = suggestions[index];
                        String score = suggestion.score == null
                            ? ''
                            : ' · ${'score'.tr}: ${suggestion.score}';
                        return ListTile(
                          leading: Icon(
                            suggestion.action == 'remove'
                                ? Icons.remove_circle_outline
                                : Icons.add_circle_outline,
                          ),
                          title: Text(
                            '${suggestion.namespace}:${suggestion.tagName}',
                          ),
                          subtitle: Text(
                            '${suggestion.action} · ${suggestion.status}'
                            ' · ${'votes'.tr}: ${suggestion.voterCount}$score'
                            '${suggestion.proposer.isEmpty ? '' : ' · @${suggestion.proposer}'}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: Get.back, child: Text('OK'.tr))],
    );
  }
}
