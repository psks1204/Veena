class PagedResponse<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;

  PagedResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
  });

  bool get isLast => number >= totalPages - 1;
  bool get isFirst => number == 0;
}
