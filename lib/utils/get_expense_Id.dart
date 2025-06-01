Future<String> getNextExpenseIdFromDocs(List<String> docIds) async {
  int maxId = 0;
  for (var id in docIds) {
    if (id.startsWith('E')) {
      final numPart = int.tryParse(id.substring(1));
      if (numPart != null && numPart > maxId) {
        maxId = numPart;
      }
    }
  }
  return 'E${(maxId + 1).toString().padLeft(3, '0')}';
}
