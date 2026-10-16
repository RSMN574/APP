enum LoadStatus { initial, loading, success, empty, error }

/// Single value describing a load so pages never juggle several booleans.
class LoadState<T> {
  const LoadState._(this.status, this.data, this.error);

  const LoadState.initial() : this._(LoadStatus.initial, null, null);
  const LoadState.loading({T? previous})
      : this._(LoadStatus.loading, previous, null);
  const LoadState.success(T data) : this._(LoadStatus.success, data, null);
  const LoadState.empty() : this._(LoadStatus.empty, null, null);
  const LoadState.error(Object error) : this._(LoadStatus.error, null, error);

  final LoadStatus status;
  final T? data;
  final Object? error;

  bool get isLoading => status == LoadStatus.loading;
  bool get hasError => status == LoadStatus.error;
  bool get isEmpty => status == LoadStatus.empty;
}
