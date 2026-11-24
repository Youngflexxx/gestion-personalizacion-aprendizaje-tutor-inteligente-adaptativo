/// Fallas de dominio tipadas.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

final class DataFailure extends AppFailure {
  const DataFailure(super.message);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}
