import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart';

const _sqliteResultCodeConstraint = 19;

bool _esViolacionRestriccion(Object error) {
  if (error is SqliteException) {
    return error.resultCode == _sqliteResultCodeConstraint;
  }
  if (error is DriftWrappedException) {
    final cause = error.cause;
    return cause != null && _esViolacionRestriccion(cause);
  }
  if (error is CouldNotRollBackException) {
    return _esViolacionRestriccion(error.cause);
  }
  return false;
}

String mensajeAmigableGuardado(Object error) {
  if (_esViolacionRestriccion(error)) {
    return 'No se pudo guardar: hay datos relacionados que lo impiden.';
  }
  return 'No se pudo guardar. Intenta de nuevo.';
}
