import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

LazyDatabase openValtiqConnection() {
  return LazyDatabase(() async {
    // En Android se mantiene el directorio de documentos (privado de la app,
    // ya usado por instalaciones existentes). En Linux/Windows, "documents"
    // resuelve a la carpeta visible del usuario (~/Documentos), así que ahí
    // se usa el directorio de soporte de la app.
    final dbFolder = Platform.isAndroid
        ? await getApplicationDocumentsDirectory()
        : await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'valtiq.db'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
