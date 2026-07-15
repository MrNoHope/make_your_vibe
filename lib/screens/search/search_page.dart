import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.c});

  final AppController c;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final queryController = TextEditingController();
  final focusNode = FocusNode();
  Timer? debounce;
  String query = '';

  @override
  void dispose() {
    debounce?.cancel();
    queryController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() => query = value);
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 320), () {
      widget.c.loadSuggestions(value);
    });
  }

  void _submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    debounce?.cancel();
    focusNode.unfocus();
    setState(() => query = trimmed);
    widget.c.search(trimmed);
  }

  void _chooseSuggestion(String value) {
    queryController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _submit(value);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final showSuggestions = query.trim().length >= 2 &&
        (c.suggesting || c.searchSuggestions.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: Text(c.tr('Tìm kiếm nhạc', 'Search music'))),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: SearchBar(
                controller: queryController,
                focusNode: focusNode,
                hintText: c.tr(
                  'Tên bài hát, nghệ sĩ...',
                  'Song or artist...',
                ),
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (query.isNotEmpty)
                    IconButton(
                      tooltip: c.tr('Xóa', 'Clear'),
                      onPressed: () {
                        debounce?.cancel();
                        queryController.clear();
                        setState(() => query = '');
                        c.clearSuggestions();
                        focusNode.requestFocus();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  IconButton(
                    tooltip: c.tr('Tìm kiếm', 'Search'),
                    onPressed: () => _submit(queryController.text),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
                onChanged: _changed,
                onSubmitted: _submit,
              ),
            ),
            if (c.searching) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
                children: [
                  if (showSuggestions)
                    _SuggestionPanel(
                      c: c,
                      suggestions: c.searchSuggestions,
                      loading: c.suggesting,
                      onSelected: _chooseSuggestion,
                    )
                  else if (query.isEmpty && c.searchHistory.isNotEmpty)
                    _HistoryPanel(
                      c: c,
                      history: c.searchHistory,
                      onSelected: _chooseSuggestion,
                    ),
                  if (query.isEmpty && c.searchResults.isEmpty) ...[
                    const SizedBox(height: 8),
                    SectionTitle(c.tr('Gợi ý nhanh', 'Quick searches')),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'V-pop chill',
                        'Lofi study',
                        'Acoustic Việt',
                        'Deep focus',
                        'Sleep music',
                      ]
                          .map(
                            (value) => ActionChip(
                              avatar: const Icon(
                                Icons.north_west_rounded,
                                size: 16,
                              ),
                              label: Text(value),
                              onPressed: () => _chooseSuggestion(value),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (c.error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(c.error)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (c.searchResults.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SectionTitle(
                      c.tr('Kết quả tìm kiếm', 'Search results'),
                    ),
                    const SizedBox(height: 4),
                    for (final song in c.searchResults)
                      SongTile(c: c, song: song, queue: c.searchResults),
                  ] else if (!c.searching && query.isNotEmpty && !showSuggestions)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: EmptyState(
                        icon: Icons.manage_search_rounded,
                        text: c.tr(
                          'Nhập tên bài hát rồi nhấn tìm kiếm.',
                          'Enter a song title and search.',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.c,
    required this.suggestions,
    required this.loading,
    required this.onSelected,
  });

  final AppController c;
  final List<String> suggestions;
  final bool loading;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading && suggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('Đang tìm gợi ý...')),
                ],
              ),
            ),
          for (final suggestion in suggestions)
            ListTile(
              dense: true,
              leading: const Icon(Icons.search_rounded),
              title: Text(
                suggestion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.north_west_rounded, size: 18),
              onTap: () => onSelected(suggestion),
            ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.c,
    required this.history,
    required this.onSelected,
  });

  final AppController c;
  final List<String> history;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: Text(c.tr('Tìm kiếm gần đây', 'Recent searches')),
            trailing: TextButton(
              onPressed: c.clearSearchHistory,
              child: Text(c.tr('Xóa hết', 'Clear')),
            ),
          ),
          for (final value in history.take(6))
            ListTile(
              dense: true,
              leading: const Icon(Icons.history_rounded, size: 20),
              title: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSelected(value),
              trailing: IconButton(
                tooltip: c.tr('Xóa', 'Remove'),
                onPressed: () => c.removeSearchHistory(value),
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
            ),
        ],
      ),
    );
  }
}
