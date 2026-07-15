part of app_controller;

extension AppSearchActions on AppController {
  Future<void> loadSuggestions(String query) async {
    final trimmed = query.trim();
    final request = ++_suggestRequest;

    if (trimmed.length < 2) {
      suggesting = false;
      searchSuggestions = [];
      notifyListeners();
      return;
    }

    suggesting = true;
    notifyListeners();

    final remote = await music.suggestions(trimmed);
    if (request != _suggestRequest) return;

    final normalized = trimmed.toLowerCase();
    final local = <String>[
      ...searchHistory,
      ...recent.map((song) => song.title),
      ...librarySongs.map((song) => song.title),
      ...searchResults.map((song) => song.title),
    ].where((value) => value.toLowerCase().contains(normalized));

    final unique = <String>{};
    searchSuggestions = [
      ...remote,
      ...local,
    ].where((value) => unique.add(value.toLowerCase())).take(8).toList();
    suggesting = false;
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestRequest += 1;
    suggesting = false;
    searchSuggestions = [];
    notifyListeners();
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _suggestRequest += 1;
    final request = ++_searchRequest;
    suggesting = false;
    searchSuggestions = [];
    searching = true;
    error = '';
    notifyListeners();

    searchHistory.removeWhere(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    searchHistory.insert(0, trimmed);
    if (searchHistory.length > 12) {
      searchHistory = searchHistory.take(12).toList();
    }
    if (user != null) {
      unawaited(store.setStrings(_key('search_history'), searchHistory));
    }

    try {
      final results = await music.search(trimmed);
      if (request != _searchRequest) return;
      searchResults = results;
      unawaited(music.prefetchMany(searchResults, maxCount: 6));
    } catch (_) {
      if (request != _searchRequest) return;
      error = tr(
        'Không thể tìm nhạc. Kiểm tra Internet rồi thử lại.',
        'Music search failed. Check your Internet and retry.',
      );
      searchResults = [];
    } finally {
      if (request == _searchRequest) {
        searching = false;
        notifyListeners();
      }
    }
  }

  Future<void> removeSearchHistory(String value) async {
    searchHistory.removeWhere((item) => item == value);
    if (user != null) {
      await store.setStrings(_key('search_history'), searchHistory);
    }
    notifyListeners();
  }

  Future<void> clearSearchHistory() async {
    searchHistory = [];
    if (user != null) {
      await store.setStrings(_key('search_history'), searchHistory);
    }
    notifyListeners();
  }
}
