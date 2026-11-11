import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Datos del perfil del usuario. Solo sirven para personalizar la app (el
/// saludo de Inicio, la foto en el menú): no salen del dispositivo.
@immutable
class Perfil {
  const Perfil({this.nombre = '', this.apellido = '', this.rutaFoto});

  final String nombre;
  final String apellido;

  /// Ruta de la copia de la foto dentro de la carpeta privada de la app.
  final String? rutaFoto;

  /// Inicial para el círculo cuando no hay foto.
  String get inicial =>
      nombre.isEmpty ? '' : nombre.substring(0, 1).toUpperCase();

  String get nombreCompleto =>
      [nombre, apellido].where((s) => s.isNotEmpty).join(' ');
}

/// Guarda y publica el perfil. Vive en `SharedPreferences` (no en la base de
/// datos): son preferencias del dispositivo, igual que el tema. Por lo mismo
/// NO viajan en la copia de seguridad.
abstract class PerfilService {
  static const _kNombre = 'valtiq_perfil_nombre';
  static const _kApellido = 'valtiq_perfil_apellido';
  static const _kFoto = 'valtiq_perfil_foto';

  /// Perfil actual. Las pantallas lo escuchan con `ValueListenableBuilder`
  /// para actualizarse solas cuando cambia.
  static final ValueNotifier<Perfil> perfil = ValueNotifier(const Perfil());

  /// Se llama una vez en `main()` antes de `runApp`.
  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    var ruta = prefs.getString(_kFoto);
    if (ruta != null && !File(ruta).existsSync()) ruta = null;
    perfil.value = Perfil(
      nombre: prefs.getString(_kNombre) ?? '',
      apellido: prefs.getString(_kApellido) ?? '',
      rutaFoto: ruta,
    );
  }

  static Future<void> guardarNombre({
    required String nombre,
    required String apellido,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNombre, nombre.trim());
    await prefs.setString(_kApellido, apellido.trim());
    perfil.value = Perfil(
      nombre: nombre.trim(),
      apellido: apellido.trim(),
      rutaFoto: perfil.value.rutaFoto,
    );
  }

  /// Copia la imagen elegida a la carpeta privada de la app y la deja como
  /// foto de perfil. Se copia (no se guarda la ruta original) porque el
  /// archivo de la galería puede moverse o borrarse, y en Android la ruta
  /// que entrega el selector es temporal.
  static Future<void> guardarFoto(Uint8List bytes, String extension) async {
    final dir = await getApplicationSupportDirectory();
    // Nombre nuevo cada vez: Flutter guarda las imágenes en caché por ruta,
    // y con el mismo nombre seguiría mostrando la foto anterior.
    final ext = extension.isEmpty ? 'jpg' : extension.toLowerCase();
    final destino = File(
      p.join(dir.path, 'perfil_${DateTime.now().millisecondsSinceEpoch}.$ext'),
    );
    await destino.writeAsBytes(bytes, flush: true);
    await _borrarArchivoFoto();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFoto, destino.path);
    perfil.value = Perfil(
      nombre: perfil.value.nombre,
      apellido: perfil.value.apellido,
      rutaFoto: destino.path,
    );
  }

  static Future<void> quitarFoto() async {
    await _borrarArchivoFoto();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFoto);
    perfil.value = Perfil(
      nombre: perfil.value.nombre,
      apellido: perfil.value.apellido,
    );
  }

  static Future<void> _borrarArchivoFoto() async {
    final anterior = perfil.value.rutaFoto;
    if (anterior == null) return;
    try {
      final f = File(anterior);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('PerfilService: no se pudo borrar la foto anterior: $e');
    }
  }
}
