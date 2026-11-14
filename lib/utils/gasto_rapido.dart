import 'currency_input.dart';

/// Lo que se entendió de una línea escrita a la carrera ("café 5mil").
class GastoLeido {
  const GastoLeido({required this.descripcion, required this.monto});

  /// Puede venir vacía (si solo se escribió el monto).
  final String descripcion;

  /// En pesos, mayor que cero y dentro de [maxMonto].
  final int monto;

  @override
  String toString() => 'GastoLeido("$descripcion", $monto)';
}

/// Lee una línea como "café 5000" y separa el nombre del monto.
///
/// Entiende el monto escrito de las formas habituales, en cualquier parte
/// de la línea: `5000`, `5.000`, `5,000`, `$5.000`, `5000 pesos`, `5mil`,
/// `5 mil`, `5k`, `5 lucas`, `2,5 mil`, `5 mil 500`, `1 millón`,
/// `2 millones`, `1.5 millones`, `2 palos`, `2 millones 500 mil`, `un
/// millón`, `mil`.
///
/// Si hay varios números ("2 cafés 8000"), el monto es el que viene marcado
/// como plata (`$`, "mil", "pesos"…); si ninguno lo está, el más grande. Los
/// demás se quedan en el nombre.
///
/// Devuelve `null` si no hay ningún monto válido.
GastoLeido? leerGastoRapido(String linea) {
  final fichas = _fichas.allMatches(linea).toList();
  final candidatos = <_Candidato>[];
  var i = 0;
  while (i < fichas.length) {
    final c = _leerMonto(fichas, i);
    if (c == null) {
      i++;
    } else {
      candidatos.add(c);
      i = c.hasta + 1;
    }
  }
  final validos = candidatos
      .where((c) => c.valor >= 1 && c.valor <= maxMonto)
      .toList();
  if (validos.isEmpty) return null;

  // Primero los marcados como plata; un "mil" suelto (sin número) solo
  // cuenta si no hay nada más. Entre los que queden, el más grande; si
  // empatan, el último.
  var grupo = validos.where((c) => c.marcado && !c.suelto).toList();
  if (grupo.isEmpty) grupo = validos.where((c) => !c.suelto).toList();
  if (grupo.isEmpty) grupo = validos;
  var elegido = grupo.first;
  for (final c in grupo.skip(1)) {
    if (c.valor >= elegido.valor) elegido = c;
  }

  final inicio = fichas[elegido.desde].start;
  final fin = fichas[elegido.hasta].end;
  final resto = '${linea.substring(0, inicio)} ${linea.substring(fin)}';
  return GastoLeido(
    descripcion: _limpiarNombre(resto),
    monto: elegido.valor.round(),
  );
}

/// Lee varias líneas (o una sola con comas o punto y coma) y devuelve un
/// gasto por cada trozo que tenga monto. Los trozos sin monto se devuelven
/// aparte en [sinMonto] para poder avisar.
({List<GastoLeido> gastos, List<String> sinMonto}) leerListaGastos(
  String texto,
) {
  final gastos = <GastoLeido>[];
  final sinMonto = <String>[];
  for (final renglon in texto.split(RegExp(r'[\n;]'))) {
    // La coma separa gastos solo si va seguida de un espacio ("café 5.000,
    // pan 2.000" sí; "2,5 mil" y "1,200,000" no llevan espacio).
    for (final trozo in renglon.split(RegExp(r',\s+'))) {
      final limpio = trozo.trim();
      if (limpio.isEmpty) continue;
      final leido = leerGastoRapido(limpio);
      if (leido == null) {
        sinMonto.add(limpio);
      } else {
        gastos.add(leido);
      }
    }
  }
  return (gastos: gastos, sinMonto: sinMonto);
}

/// Minúsculas, sin tildes y sin espacios de más: para comparar nombres
/// ("Café " = "cafe").
String normalizarNombre(String texto) {
  final sb = StringBuffer();
  for (final r in texto.toLowerCase().runes) {
    sb.write(_sinTilde[r] ?? String.fromCharCode(r));
  }
  return sb.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Categoría que ya se usó antes para un gasto con este nombre.
///
/// [recientes] va del más nuevo al más viejo, como (nombre, categoría).
/// Busca primero el mismo nombre; si no, el gasto más reciente que comparta
/// una palabra de 4 letras o más ("café con leche" ↔ "café"). Devuelve
/// `null` si no hay nada parecido: quien llama decide el valor por defecto.
String? categoriaAprendida(
  String descripcion,
  Iterable<(String nombre, String categoria)> recientes,
) {
  final buscado = normalizarNombre(descripcion);
  if (buscado.isEmpty) return null;
  final palabras = _palabrasClave(buscado);
  String? parecida;
  for (final (nombre, categoria) in recientes) {
    final n = normalizarNombre(nombre);
    if (n == buscado) return categoria;
    if (parecida == null &&
        palabras.isNotEmpty &&
        _palabrasClave(n).any(palabras.contains)) {
      parecida = categoria;
    }
  }
  return parecida;
}

Set<String> _palabrasClave(String normalizado) => {
  for (final p in normalizado.split(RegExp(r'[^a-z0-9ñ]+')))
    if (p.length >= 4 && !_palabrasVacias.contains(p)) p,
};

const _palabrasVacias = {'para', 'pago', 'compra', 'desde', 'hasta', 'sobre'};

// ---------------------------------------------------------------------------

/// Trozos de la línea: `$`, un número (con sus puntos y comas) o una
/// palabra. Así "5mil" y "$5.000" quedan ya separados.
final _fichas = RegExp(r'\$|\d[\d.,]*\d|\d|[^\s\d$]+');

final _miles = RegExp(r'^\d{1,3}(?:[.,]\d{3})+(?:,\d{1,2})?$');
final _simple = RegExp(r'^\d+(?:[.,]\d+)?$');
final _tresCifras = RegExp(r'^\d{3}$');

const _unidadMil = {'mil', 'miles', 'k', 'luca', 'lucas', 'barra', 'barras'};
const _unidadMillon = {'millon', 'millones', 'palo', 'palos'};
const _moneda = {'pesos', 'peso', 'cop'};

class _Candidato {
  _Candidato(this.desde, this.hasta, this.valor, this.marcado, this.suelto);

  /// Posición de la primera y la última ficha del monto.
  final int desde;
  final int hasta;
  final double valor;

  /// Trae algo que lo señala como plata (`$`, "mil", "pesos"…).
  final bool marcado;

  /// Es una unidad sin número ("mil").
  final bool suelto;
}

String _palabra(RegExpMatch m) =>
    normalizarNombre(m[0]!).replaceAll(RegExp(r'[.,;:!?]+$'), '');

double? _numero(RegExpMatch m) {
  final t = m[0]!;
  if (_miles.hasMatch(t)) {
    // 1.200.000 o 1,200,000 (con decimales opcionales tras una coma).
    final partes = t.split(',');
    final conDecimales =
        partes.length > 1 && partes.last.length <= 2 && t.contains('.');
    final entero = (conDecimales ? partes.first : t).replaceAll(
      RegExp(r'[.,]'),
      '',
    );
    return double.tryParse(conDecimales ? '$entero.${partes.last}' : entero);
  }
  if (_simple.hasMatch(t)) return double.tryParse(t.replaceAll(',', '.'));
  return null;
}

/// Intenta leer un monto que empiece en la ficha [i].
_Candidato? _leerMonto(List<RegExpMatch> f, int i) {
  var desde = i;
  var marcado = false;
  var suelto = false;
  var j = i;
  if (f[j][0] == r'$') {
    marcado = true;
    j++;
    if (j >= f.length) return null;
  }

  double? n = _numero(f[j]);
  if (n == null) {
    final letras = _leerEnLetras(f, j);
    if (letras != null) {
      return _cerrarMonto(
        f,
        desde,
        letras.hasta,
        letras.valor,
        marcado || letras.marcado,
        false,
        conLetras: true,
      );
    }
    final p = _palabra(f[j]);
    final sigue = j + 1 < f.length ? _palabra(f[j + 1]) : '';
    if ((p == 'un' || p == 'una') &&
        (_unidadMil.contains(sigue) || _unidadMillon.contains(sigue))) {
      n = 1;
      marcado = true;
    } else if (p == 'mil' || p == 'millon') {
      // Unidad sin número: "mil", "millón".
      n = 1;
      suelto = !marcado;
      j--; // la unidad se lee abajo como si viniera tras el 1
    } else {
      return null;
    }
  }

  var total = 0.0;
  var hasta = j;
  String unidad(int k) => k < f.length ? _palabra(f[k]) : '';

  if (_unidadMillon.contains(unidad(j + 1))) {
    total += n * 1000000;
    marcado = true;
    hasta = j + 1;
    // "2 millones 500 mil"
    final m = hasta + 1 < f.length ? _numero(f[hasta + 1]) : null;
    if (m != null && _unidadMil.contains(unidad(hasta + 2))) {
      total += m * 1000;
      hasta += 2;
    }
  } else if (_unidadMil.contains(unidad(j + 1))) {
    total += n * 1000;
    marcado = true;
    hasta = j + 1;
    // "5 mil 500": solo si lo que sigue son exactamente tres cifras.
    if (hasta + 1 < f.length &&
        _tresCifras.hasMatch(f[hasta + 1][0]!) &&
        !_unidadMil.contains(unidad(hasta + 2)) &&
        !_unidadMillon.contains(unidad(hasta + 2))) {
      total += double.parse(f[hasta + 1][0]!);
      hasta += 1;
    }
  } else {
    total += n;
  }

  return _cerrarMonto(f, desde, hasta, total, marcado, suelto);
}

/// Suma al monto que termina en [hasta] la marca de moneda que lo siga
/// ("5000 pesos", "5000$"). Un número en letras solo cuenta si es plata
/// clara: con "mil"/"millón" o con "pesos"/`$` ("cinco cafés" no es un
/// monto; "quinientos pesos" sí).
_Candidato? _cerrarMonto(
  List<RegExpMatch> f,
  int desde,
  int hasta,
  double total,
  bool marcado,
  bool suelto, {
  bool conLetras = false,
}) {
  final despues = hasta + 1 < f.length ? f[hasta + 1] : null;
  if (despues != null &&
      (despues[0] == r'$' || _moneda.contains(_palabra(despues)))) {
    marcado = true;
    hasta += 1;
  }
  if (conLetras && !marcado) return null;
  if (suelto) desde = hasta; // solo la palabra "mil"
  return _Candidato(desde, hasta, total, marcado, suelto);
}

/// Lee un número escrito en letras desde la ficha [i]: "cincuenta mil",
/// "treinta y cinco mil", "mil quinientos", "dos millones quinientos mil",
/// "ciento veinte lucas". [marcado] dice si trae "mil"/"millón" (o sus
/// apodos: lucas, palos…). `null` si no empieza un número, o si es solo
/// "un"/"una", "mil" o "millón" sueltos (esos los lee [_leerMonto]).
({int hasta, double valor, bool marcado})? _leerEnLetras(
  List<RegExpMatch> f,
  int i,
) {
  final primera = _palabra(f[i]);
  // Empieza con un número en letras, o con "mil"/"millón" seguidos de uno
  // ("mil quinientos"). "lucas" o "palos" al principio no son un número.
  if (!_numerosEnLetras.containsKey(primera) &&
      primera != 'mil' &&
      primera != 'millon') {
    return null;
  }
  var total = 0.0;
  var grupo = 0;
  var marcado = false;
  var hasta = i;
  var palabras = 0;
  int? anterior; // la última palabra-número del grupo, para validar el orden
  var k = i;
  while (k < f.length) {
    final p = _palabra(f[k]);
    final v = _numerosEnLetras[p];
    if (v != null) {
      // "cien cinco" sí (105); "veinte treinta" o "cinco seis" no.
      if (anterior != null && !_seSuman(anterior, v)) break;
      grupo += v;
      anterior = v;
    } else if (p == 'y' && anterior != null && _esDecena(anterior)) {
      // "treinta y cinco": el "y" solo va entre decenas y unidades.
      final sigue = k + 1 < f.length
          ? _numerosEnLetras[_palabra(f[k + 1])]
          : null;
      if (sigue == null || sigue >= 10) break;
      k++;
      continue;
    } else if (_unidadMil.contains(p) || _unidadMillon.contains(p)) {
      // Un multiplicador solo vale tras un número ("dos mil") o al
      // principio ("mil quinientos"); "dos millones mil" se corta.
      if (palabras > 0 && anterior == null) break;
      final base = grupo == 0 ? 1 : grupo;
      if (_unidadMil.contains(p)) {
        total += base * 1000;
      } else {
        total = (total + base) * 1000000;
      }
      grupo = 0;
      anterior = null;
      marcado = true;
    } else {
      break;
    }
    palabras++;
    hasta = k;
    k++;
  }
  // Una sola palabra suelta ("un", "una", "mil", "millón") la decide
  // [_leerMonto] como siempre.
  if (palabras == 1 &&
      (_unidadMil.contains(primera) ||
          _unidadMillon.contains(primera) ||
          (_numerosEnLetras[primera] ?? 0) == 1)) {
    return null;
  }
  return (hasta: hasta, valor: total + grupo, marcado: marcado);
}

bool _esDecena(int n) => n >= 20 && n < 100 && n % 10 == 0;

/// Si [siguiente] puede ir detrás de [anterior] en el mismo grupo de tres
/// cifras: centenas + lo que sea menor que cien ("ciento veinte"),
/// decenas + unidades ("treinta cinco", con o sin "y").
bool _seSuman(int anterior, int siguiente) =>
    (anterior >= 100 && anterior % 100 == 0 && siguiente < 100) ||
    (_esDecena(anterior) && siguiente < 10);

const _numerosEnLetras = {
  'un': 1,
  'uno': 1,
  'una': 1,
  'dos': 2,
  'tres': 3,
  'cuatro': 4,
  'cinco': 5,
  'seis': 6,
  'siete': 7,
  'ocho': 8,
  'nueve': 9,
  'diez': 10,
  'once': 11,
  'doce': 12,
  'trece': 13,
  'catorce': 14,
  'quince': 15,
  'dieciseis': 16,
  'diecisiete': 17,
  'dieciocho': 18,
  'diecinueve': 19,
  'veinte': 20,
  'veintiun': 21,
  'veintiuno': 21,
  'veintiuna': 21,
  'veintidos': 22,
  'veintitres': 23,
  'veinticuatro': 24,
  'veinticinco': 25,
  'veintiseis': 26,
  'veintisiete': 27,
  'veintiocho': 28,
  'veintinueve': 29,
  'treinta': 30,
  'cuarenta': 40,
  'cincuenta': 50,
  'sesenta': 60,
  'setenta': 70,
  'ochenta': 80,
  'noventa': 90,
  'cien': 100,
  'ciento': 100,
  'doscientos': 200,
  'doscientas': 200,
  'trescientos': 300,
  'trescientas': 300,
  'cuatrocientos': 400,
  'cuatrocientas': 400,
  'quinientos': 500,
  'quinientas': 500,
  'seiscientos': 600,
  'seiscientas': 600,
  'setecientos': 700,
  'setecientas': 700,
  'ochocientos': 800,
  'ochocientas': 800,
  'novecientos': 900,
  'novecientas': 900,
};

final _bordes = RegExp(r'^[\s\-–—:=,;.+*]+|[\s\-–—:=,;.+*]+$');
final _colaSobra = RegExp(
  r'\s+(?:por|de|a|en|x|vale|valio|costo|son|fue|fueron)$',
  caseSensitive: false,
);
final _cabezaSobra = RegExp(r'^(?:de|en|por)\s+', caseSensitive: false);

String _limpiarNombre(String texto) {
  var s = texto.replaceAll(RegExp(r'\s+'), ' ').trim();
  String antes;
  do {
    antes = s;
    s = s.replaceAll(_bordes, '');
    // Se compara sin tildes para quitar "costó", "valió"…
    final m = _colaSobra.firstMatch(_quitarTildes(s));
    if (m != null) s = s.substring(0, m.start);
    s = s.replaceFirst(_cabezaSobra, '');
  } while (s != antes);
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

/// Como [normalizarNombre] pero conserva mayúsculas y el largo del texto
/// (cada letra con tilde se cambia por una sola letra).
String _quitarTildes(String texto) {
  final sb = StringBuffer();
  for (final r in texto.runes) {
    sb.write(_sinTilde[r] ?? _sinTildeMayus[r] ?? String.fromCharCode(r));
  }
  return sb.toString();
}

const _sinTilde = {
  0xE1: 'a', // á
  0xE9: 'e', // é
  0xED: 'i', // í
  0xF3: 'o', // ó
  0xFA: 'u', // ú
  0xFC: 'u', // ü
};
const _sinTildeMayus = {
  0xC1: 'A',
  0xC9: 'E',
  0xCD: 'I',
  0xD3: 'O',
  0xDA: 'U',
  0xDC: 'U',
};
