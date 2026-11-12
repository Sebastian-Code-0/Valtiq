/// Tasa de interés más alta que se puede escribir (en %, mensual o anual).
/// Muy por encima de cualquier tasa real; evita que un número absurdo
/// (un dedo de más) produzca intereses imposibles de mostrar.
const double maxTasa = 500;

/// Lo escrito en un campo de tasa, como número. Vacío o inválido → 0.
double parseTasa(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.')) ?? 0;

/// Validador de un campo de tasa (vacío = sin interés).
String? validarTasa(String? v) {
  if (v == null || v.trim().isEmpty) return null;
  final tasa = double.tryParse(v.trim().replaceAll(',', '.'));
  if (tasa == null || !tasa.isFinite) return 'Ingresa un número válido';
  if (tasa < 0) return 'La tasa no puede ser negativa';
  if (tasa > maxTasa) return 'La tasa no puede pasar de 500%';
  return null;
}

/// Texto inicial del campo de tasa: vacío si no hay interés (para no tener
/// que borrar un "0" antes de escribir).
String tasaParaCampo(double tasa) {
  if (tasa <= 0) return '';
  return tasa == tasa.truncateToDouble()
      ? tasa.toStringAsFixed(0)
      : tasa.toStringAsFixed(2);
}

/// Mensaje cuando hay tasa pero no se eligió si es mensual o anual.
const String errorTipoInteres = 'Elige si la tasa es mensual o anual';
