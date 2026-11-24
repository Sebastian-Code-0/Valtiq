/// Tasa de interés más alta que se puede escribir (en %, mensual o anual).
/// Muy por encima de cualquier tasa real; evita que un número absurdo
/// (un dedo de más) produzca intereses imposibles de mostrar.
const double maxTasa = 500;

/// Lo escrito en un campo de tasa, como número. Vacío o inválido → 0.
double parseTasa(String texto) => _leerTasa(texto) ?? 0;

/// Solo dígitos con un separador decimal opcional: `double.tryParse` a secas
/// también aceptaría `1e2`, `NaN` o `Infinity`.
final _formatoTasa = RegExp(r'^-?(\d+([.,]\d*)?|[.,]\d+)$');

double? _leerTasa(String texto) {
  final t = texto.trim();
  if (!_formatoTasa.hasMatch(t)) return null;
  return double.tryParse(t.replaceAll(',', '.'));
}

/// Validador de un campo de tasa (vacío = sin interés).
String? validarTasa(String? v) {
  if (v == null || v.trim().isEmpty) return null;
  final tasa = _leerTasa(v);
  if (tasa == null || !tasa.isFinite) return 'Ingresa un número válido';
  if (tasa < 0) return 'La tasa no puede ser negativa';
  if (tasa > maxTasa) return 'La tasa no puede pasar de 500%';
  return null;
}

/// Texto inicial del campo de tasa: vacío si no hay interés (para no tener
/// que borrar un "0" antes de escribir).
String tasaParaCampo(double tasa) {
  if (tasa <= 0) return '';
  if (tasa == tasa.truncateToDouble()) return tasa.toStringAsFixed(0);
  // La tasa exacta: abrir y guardar el formulario no debe cambiarla. Una
  // muy pequeña sale en notación científica, que el campo no entiende.
  var texto = tasa.toString();
  final e = texto.indexOf('e');
  if (e >= 0) {
    final digitos = texto.substring(0, e).replaceAll('.', '');
    final ceros = -int.parse(texto.substring(e + 1)) - 1;
    texto = '0.${'0' * ceros}$digitos';
  }
  return texto.replaceAll('.', ',');
}

/// Mensaje cuando hay tasa pero no se eligió si es mensual o anual.
const String errorTipoInteres = 'Elige si la tasa es mensual o anual';
