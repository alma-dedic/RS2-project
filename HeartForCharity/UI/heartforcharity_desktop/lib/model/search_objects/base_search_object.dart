class BaseSearchObject {
  final String? fts;
  final int page;
  final int pageSize;
  final bool? includeTotalCount;
  final bool? retrieveAll;

  BaseSearchObject({
    this.fts,
    this.page = 0,
    this.pageSize = 10,
    this.includeTotalCount,
    this.retrieveAll,
  });

  Map<String, dynamic> toMap() => {
        if (fts != null) 'fts': fts,
        'page': page,
        'pageSize': pageSize,
        if (includeTotalCount != null) 'includeTotalCount': includeTotalCount,
        if (retrieveAll != null) 'retrieveAll': retrieveAll,
      };
}
