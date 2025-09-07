class FilterParameters {
  final String? query;
  final Map<String, dynamic> filters;

  const FilterParameters({this.query, this.filters = const {}});

  Map<String, dynamic> toJson() {
    return {'query': query, 'filters': filters};
  }

  static FilterParameters fromJson(Map<String, dynamic> json) {
    return FilterParameters(
      query: json['query'] as String?,
      filters: json['filters'] as Map<String, dynamic>? ?? {},
    );
  }
}
