// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DeudasTable extends Deudas with TableInfo<$DeudasTable, Deuda> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeudasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _acreedorNombreMeta = const VerificationMeta(
    'acreedorNombre',
  );
  @override
  late final GeneratedColumn<String> acreedorNombre = GeneratedColumn<String>(
    'acreedor_nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoOriginalMeta = const VerificationMeta(
    'montoOriginal',
  );
  @override
  late final GeneratedColumn<double> montoOriginal = GeneratedColumn<double>(
    'monto_original',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tasaInteresMeta = const VerificationMeta(
    'tasaInteres',
  );
  @override
  late final GeneratedColumn<double> tasaInteres = GeneratedColumn<double>(
    'tasa_interes',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tipoInteresMeta = const VerificationMeta(
    'tipoInteres',
  );
  @override
  late final GeneratedColumn<String> tipoInteres = GeneratedColumn<String>(
    'tipo_interes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ninguno'),
  );
  static const VerificationMeta _modalidadCalculoMeta = const VerificationMeta(
    'modalidadCalculo',
  );
  @override
  late final GeneratedColumn<String> modalidadCalculo = GeneratedColumn<String>(
    'modalidad_calculo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('simple'),
  );
  static const VerificationMeta _fechaPrestamoMeta = const VerificationMeta(
    'fechaPrestamo',
  );
  @override
  late final GeneratedColumn<DateTime> fechaPrestamo =
      GeneratedColumn<DateTime>(
        'fecha_prestamo',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fechaLimiteMeta = const VerificationMeta(
    'fechaLimite',
  );
  @override
  late final GeneratedColumn<DateTime> fechaLimite = GeneratedColumn<DateTime>(
    'fecha_limite',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cuotaMensualMeta = const VerificationMeta(
    'cuotaMensual',
  );
  @override
  late final GeneratedColumn<double> cuotaMensual = GeneratedColumn<double>(
    'cuota_mensual',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('activa'),
  );
  static const VerificationMeta _fechaPagoRealMeta = const VerificationMeta(
    'fechaPagoReal',
  );
  @override
  late final GeneratedColumn<DateTime> fechaPagoReal =
      GeneratedColumn<DateTime>(
        'fecha_pago_real',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    acreedorNombre,
    montoOriginal,
    tasaInteres,
    tipoInteres,
    modalidadCalculo,
    fechaPrestamo,
    fechaLimite,
    cuotaMensual,
    notas,
    estado,
    fechaPagoReal,
    creadoEn,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deudas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deuda> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('acreedor_nombre')) {
      context.handle(
        _acreedorNombreMeta,
        acreedorNombre.isAcceptableOrUnknown(
          data['acreedor_nombre']!,
          _acreedorNombreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_acreedorNombreMeta);
    }
    if (data.containsKey('monto_original')) {
      context.handle(
        _montoOriginalMeta,
        montoOriginal.isAcceptableOrUnknown(
          data['monto_original']!,
          _montoOriginalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoOriginalMeta);
    }
    if (data.containsKey('tasa_interes')) {
      context.handle(
        _tasaInteresMeta,
        tasaInteres.isAcceptableOrUnknown(
          data['tasa_interes']!,
          _tasaInteresMeta,
        ),
      );
    }
    if (data.containsKey('tipo_interes')) {
      context.handle(
        _tipoInteresMeta,
        tipoInteres.isAcceptableOrUnknown(
          data['tipo_interes']!,
          _tipoInteresMeta,
        ),
      );
    }
    if (data.containsKey('modalidad_calculo')) {
      context.handle(
        _modalidadCalculoMeta,
        modalidadCalculo.isAcceptableOrUnknown(
          data['modalidad_calculo']!,
          _modalidadCalculoMeta,
        ),
      );
    }
    if (data.containsKey('fecha_prestamo')) {
      context.handle(
        _fechaPrestamoMeta,
        fechaPrestamo.isAcceptableOrUnknown(
          data['fecha_prestamo']!,
          _fechaPrestamoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaPrestamoMeta);
    }
    if (data.containsKey('fecha_limite')) {
      context.handle(
        _fechaLimiteMeta,
        fechaLimite.isAcceptableOrUnknown(
          data['fecha_limite']!,
          _fechaLimiteMeta,
        ),
      );
    }
    if (data.containsKey('cuota_mensual')) {
      context.handle(
        _cuotaMensualMeta,
        cuotaMensual.isAcceptableOrUnknown(
          data['cuota_mensual']!,
          _cuotaMensualMeta,
        ),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('fecha_pago_real')) {
      context.handle(
        _fechaPagoRealMeta,
        fechaPagoReal.isAcceptableOrUnknown(
          data['fecha_pago_real']!,
          _fechaPagoRealMeta,
        ),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deuda map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deuda(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      acreedorNombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acreedor_nombre'],
      )!,
      montoOriginal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_original'],
      )!,
      tasaInteres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tasa_interes'],
      )!,
      tipoInteres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_interes'],
      )!,
      modalidadCalculo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modalidad_calculo'],
      )!,
      fechaPrestamo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_prestamo'],
      )!,
      fechaLimite: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_limite'],
      ),
      cuotaMensual: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cuota_mensual'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      )!,
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      fechaPagoReal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_pago_real'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      )!,
    );
  }

  @override
  $DeudasTable createAlias(String alias) {
    return $DeudasTable(attachedDatabase, alias);
  }
}

class Deuda extends DataClass implements Insertable<Deuda> {
  final int id;
  final String acreedorNombre;
  final double montoOriginal;
  final double tasaInteres;
  final String tipoInteres;
  final String modalidadCalculo;
  final DateTime fechaPrestamo;
  final DateTime? fechaLimite;
  final double? cuotaMensual;
  final String notas;
  final String estado;
  final DateTime? fechaPagoReal;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  const Deuda({
    required this.id,
    required this.acreedorNombre,
    required this.montoOriginal,
    required this.tasaInteres,
    required this.tipoInteres,
    required this.modalidadCalculo,
    required this.fechaPrestamo,
    this.fechaLimite,
    this.cuotaMensual,
    required this.notas,
    required this.estado,
    this.fechaPagoReal,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['acreedor_nombre'] = Variable<String>(acreedorNombre);
    map['monto_original'] = Variable<double>(montoOriginal);
    map['tasa_interes'] = Variable<double>(tasaInteres);
    map['tipo_interes'] = Variable<String>(tipoInteres);
    map['modalidad_calculo'] = Variable<String>(modalidadCalculo);
    map['fecha_prestamo'] = Variable<DateTime>(fechaPrestamo);
    if (!nullToAbsent || fechaLimite != null) {
      map['fecha_limite'] = Variable<DateTime>(fechaLimite);
    }
    if (!nullToAbsent || cuotaMensual != null) {
      map['cuota_mensual'] = Variable<double>(cuotaMensual);
    }
    map['notas'] = Variable<String>(notas);
    map['estado'] = Variable<String>(estado);
    if (!nullToAbsent || fechaPagoReal != null) {
      map['fecha_pago_real'] = Variable<DateTime>(fechaPagoReal);
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    return map;
  }

  DeudasCompanion toCompanion(bool nullToAbsent) {
    return DeudasCompanion(
      id: Value(id),
      acreedorNombre: Value(acreedorNombre),
      montoOriginal: Value(montoOriginal),
      tasaInteres: Value(tasaInteres),
      tipoInteres: Value(tipoInteres),
      modalidadCalculo: Value(modalidadCalculo),
      fechaPrestamo: Value(fechaPrestamo),
      fechaLimite: fechaLimite == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaLimite),
      cuotaMensual: cuotaMensual == null && nullToAbsent
          ? const Value.absent()
          : Value(cuotaMensual),
      notas: Value(notas),
      estado: Value(estado),
      fechaPagoReal: fechaPagoReal == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaPagoReal),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory Deuda.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deuda(
      id: serializer.fromJson<int>(json['id']),
      acreedorNombre: serializer.fromJson<String>(json['acreedorNombre']),
      montoOriginal: serializer.fromJson<double>(json['montoOriginal']),
      tasaInteres: serializer.fromJson<double>(json['tasaInteres']),
      tipoInteres: serializer.fromJson<String>(json['tipoInteres']),
      modalidadCalculo: serializer.fromJson<String>(json['modalidadCalculo']),
      fechaPrestamo: serializer.fromJson<DateTime>(json['fechaPrestamo']),
      fechaLimite: serializer.fromJson<DateTime?>(json['fechaLimite']),
      cuotaMensual: serializer.fromJson<double?>(json['cuotaMensual']),
      notas: serializer.fromJson<String>(json['notas']),
      estado: serializer.fromJson<String>(json['estado']),
      fechaPagoReal: serializer.fromJson<DateTime?>(json['fechaPagoReal']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'acreedorNombre': serializer.toJson<String>(acreedorNombre),
      'montoOriginal': serializer.toJson<double>(montoOriginal),
      'tasaInteres': serializer.toJson<double>(tasaInteres),
      'tipoInteres': serializer.toJson<String>(tipoInteres),
      'modalidadCalculo': serializer.toJson<String>(modalidadCalculo),
      'fechaPrestamo': serializer.toJson<DateTime>(fechaPrestamo),
      'fechaLimite': serializer.toJson<DateTime?>(fechaLimite),
      'cuotaMensual': serializer.toJson<double?>(cuotaMensual),
      'notas': serializer.toJson<String>(notas),
      'estado': serializer.toJson<String>(estado),
      'fechaPagoReal': serializer.toJson<DateTime?>(fechaPagoReal),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
    };
  }

  Deuda copyWith({
    int? id,
    String? acreedorNombre,
    double? montoOriginal,
    double? tasaInteres,
    String? tipoInteres,
    String? modalidadCalculo,
    DateTime? fechaPrestamo,
    Value<DateTime?> fechaLimite = const Value.absent(),
    Value<double?> cuotaMensual = const Value.absent(),
    String? notas,
    String? estado,
    Value<DateTime?> fechaPagoReal = const Value.absent(),
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) => Deuda(
    id: id ?? this.id,
    acreedorNombre: acreedorNombre ?? this.acreedorNombre,
    montoOriginal: montoOriginal ?? this.montoOriginal,
    tasaInteres: tasaInteres ?? this.tasaInteres,
    tipoInteres: tipoInteres ?? this.tipoInteres,
    modalidadCalculo: modalidadCalculo ?? this.modalidadCalculo,
    fechaPrestamo: fechaPrestamo ?? this.fechaPrestamo,
    fechaLimite: fechaLimite.present ? fechaLimite.value : this.fechaLimite,
    cuotaMensual: cuotaMensual.present ? cuotaMensual.value : this.cuotaMensual,
    notas: notas ?? this.notas,
    estado: estado ?? this.estado,
    fechaPagoReal: fechaPagoReal.present
        ? fechaPagoReal.value
        : this.fechaPagoReal,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  Deuda copyWithCompanion(DeudasCompanion data) {
    return Deuda(
      id: data.id.present ? data.id.value : this.id,
      acreedorNombre: data.acreedorNombre.present
          ? data.acreedorNombre.value
          : this.acreedorNombre,
      montoOriginal: data.montoOriginal.present
          ? data.montoOriginal.value
          : this.montoOriginal,
      tasaInteres: data.tasaInteres.present
          ? data.tasaInteres.value
          : this.tasaInteres,
      tipoInteres: data.tipoInteres.present
          ? data.tipoInteres.value
          : this.tipoInteres,
      modalidadCalculo: data.modalidadCalculo.present
          ? data.modalidadCalculo.value
          : this.modalidadCalculo,
      fechaPrestamo: data.fechaPrestamo.present
          ? data.fechaPrestamo.value
          : this.fechaPrestamo,
      fechaLimite: data.fechaLimite.present
          ? data.fechaLimite.value
          : this.fechaLimite,
      cuotaMensual: data.cuotaMensual.present
          ? data.cuotaMensual.value
          : this.cuotaMensual,
      notas: data.notas.present ? data.notas.value : this.notas,
      estado: data.estado.present ? data.estado.value : this.estado,
      fechaPagoReal: data.fechaPagoReal.present
          ? data.fechaPagoReal.value
          : this.fechaPagoReal,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deuda(')
          ..write('id: $id, ')
          ..write('acreedorNombre: $acreedorNombre, ')
          ..write('montoOriginal: $montoOriginal, ')
          ..write('tasaInteres: $tasaInteres, ')
          ..write('tipoInteres: $tipoInteres, ')
          ..write('modalidadCalculo: $modalidadCalculo, ')
          ..write('fechaPrestamo: $fechaPrestamo, ')
          ..write('fechaLimite: $fechaLimite, ')
          ..write('cuotaMensual: $cuotaMensual, ')
          ..write('notas: $notas, ')
          ..write('estado: $estado, ')
          ..write('fechaPagoReal: $fechaPagoReal, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    acreedorNombre,
    montoOriginal,
    tasaInteres,
    tipoInteres,
    modalidadCalculo,
    fechaPrestamo,
    fechaLimite,
    cuotaMensual,
    notas,
    estado,
    fechaPagoReal,
    creadoEn,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deuda &&
          other.id == this.id &&
          other.acreedorNombre == this.acreedorNombre &&
          other.montoOriginal == this.montoOriginal &&
          other.tasaInteres == this.tasaInteres &&
          other.tipoInteres == this.tipoInteres &&
          other.modalidadCalculo == this.modalidadCalculo &&
          other.fechaPrestamo == this.fechaPrestamo &&
          other.fechaLimite == this.fechaLimite &&
          other.cuotaMensual == this.cuotaMensual &&
          other.notas == this.notas &&
          other.estado == this.estado &&
          other.fechaPagoReal == this.fechaPagoReal &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn);
}

class DeudasCompanion extends UpdateCompanion<Deuda> {
  final Value<int> id;
  final Value<String> acreedorNombre;
  final Value<double> montoOriginal;
  final Value<double> tasaInteres;
  final Value<String> tipoInteres;
  final Value<String> modalidadCalculo;
  final Value<DateTime> fechaPrestamo;
  final Value<DateTime?> fechaLimite;
  final Value<double?> cuotaMensual;
  final Value<String> notas;
  final Value<String> estado;
  final Value<DateTime?> fechaPagoReal;
  final Value<DateTime> creadoEn;
  final Value<DateTime> actualizadoEn;
  const DeudasCompanion({
    this.id = const Value.absent(),
    this.acreedorNombre = const Value.absent(),
    this.montoOriginal = const Value.absent(),
    this.tasaInteres = const Value.absent(),
    this.tipoInteres = const Value.absent(),
    this.modalidadCalculo = const Value.absent(),
    this.fechaPrestamo = const Value.absent(),
    this.fechaLimite = const Value.absent(),
    this.cuotaMensual = const Value.absent(),
    this.notas = const Value.absent(),
    this.estado = const Value.absent(),
    this.fechaPagoReal = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  });
  DeudasCompanion.insert({
    this.id = const Value.absent(),
    required String acreedorNombre,
    required double montoOriginal,
    this.tasaInteres = const Value.absent(),
    this.tipoInteres = const Value.absent(),
    this.modalidadCalculo = const Value.absent(),
    required DateTime fechaPrestamo,
    this.fechaLimite = const Value.absent(),
    this.cuotaMensual = const Value.absent(),
    this.notas = const Value.absent(),
    this.estado = const Value.absent(),
    this.fechaPagoReal = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  }) : acreedorNombre = Value(acreedorNombre),
       montoOriginal = Value(montoOriginal),
       fechaPrestamo = Value(fechaPrestamo);
  static Insertable<Deuda> custom({
    Expression<int>? id,
    Expression<String>? acreedorNombre,
    Expression<double>? montoOriginal,
    Expression<double>? tasaInteres,
    Expression<String>? tipoInteres,
    Expression<String>? modalidadCalculo,
    Expression<DateTime>? fechaPrestamo,
    Expression<DateTime>? fechaLimite,
    Expression<double>? cuotaMensual,
    Expression<String>? notas,
    Expression<String>? estado,
    Expression<DateTime>? fechaPagoReal,
    Expression<DateTime>? creadoEn,
    Expression<DateTime>? actualizadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (acreedorNombre != null) 'acreedor_nombre': acreedorNombre,
      if (montoOriginal != null) 'monto_original': montoOriginal,
      if (tasaInteres != null) 'tasa_interes': tasaInteres,
      if (tipoInteres != null) 'tipo_interes': tipoInteres,
      if (modalidadCalculo != null) 'modalidad_calculo': modalidadCalculo,
      if (fechaPrestamo != null) 'fecha_prestamo': fechaPrestamo,
      if (fechaLimite != null) 'fecha_limite': fechaLimite,
      if (cuotaMensual != null) 'cuota_mensual': cuotaMensual,
      if (notas != null) 'notas': notas,
      if (estado != null) 'estado': estado,
      if (fechaPagoReal != null) 'fecha_pago_real': fechaPagoReal,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
    });
  }

  DeudasCompanion copyWith({
    Value<int>? id,
    Value<String>? acreedorNombre,
    Value<double>? montoOriginal,
    Value<double>? tasaInteres,
    Value<String>? tipoInteres,
    Value<String>? modalidadCalculo,
    Value<DateTime>? fechaPrestamo,
    Value<DateTime?>? fechaLimite,
    Value<double?>? cuotaMensual,
    Value<String>? notas,
    Value<String>? estado,
    Value<DateTime?>? fechaPagoReal,
    Value<DateTime>? creadoEn,
    Value<DateTime>? actualizadoEn,
  }) {
    return DeudasCompanion(
      id: id ?? this.id,
      acreedorNombre: acreedorNombre ?? this.acreedorNombre,
      montoOriginal: montoOriginal ?? this.montoOriginal,
      tasaInteres: tasaInteres ?? this.tasaInteres,
      tipoInteres: tipoInteres ?? this.tipoInteres,
      modalidadCalculo: modalidadCalculo ?? this.modalidadCalculo,
      fechaPrestamo: fechaPrestamo ?? this.fechaPrestamo,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      cuotaMensual: cuotaMensual ?? this.cuotaMensual,
      notas: notas ?? this.notas,
      estado: estado ?? this.estado,
      fechaPagoReal: fechaPagoReal ?? this.fechaPagoReal,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (acreedorNombre.present) {
      map['acreedor_nombre'] = Variable<String>(acreedorNombre.value);
    }
    if (montoOriginal.present) {
      map['monto_original'] = Variable<double>(montoOriginal.value);
    }
    if (tasaInteres.present) {
      map['tasa_interes'] = Variable<double>(tasaInteres.value);
    }
    if (tipoInteres.present) {
      map['tipo_interes'] = Variable<String>(tipoInteres.value);
    }
    if (modalidadCalculo.present) {
      map['modalidad_calculo'] = Variable<String>(modalidadCalculo.value);
    }
    if (fechaPrestamo.present) {
      map['fecha_prestamo'] = Variable<DateTime>(fechaPrestamo.value);
    }
    if (fechaLimite.present) {
      map['fecha_limite'] = Variable<DateTime>(fechaLimite.value);
    }
    if (cuotaMensual.present) {
      map['cuota_mensual'] = Variable<double>(cuotaMensual.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (fechaPagoReal.present) {
      map['fecha_pago_real'] = Variable<DateTime>(fechaPagoReal.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeudasCompanion(')
          ..write('id: $id, ')
          ..write('acreedorNombre: $acreedorNombre, ')
          ..write('montoOriginal: $montoOriginal, ')
          ..write('tasaInteres: $tasaInteres, ')
          ..write('tipoInteres: $tipoInteres, ')
          ..write('modalidadCalculo: $modalidadCalculo, ')
          ..write('fechaPrestamo: $fechaPrestamo, ')
          ..write('fechaLimite: $fechaLimite, ')
          ..write('cuotaMensual: $cuotaMensual, ')
          ..write('notas: $notas, ')
          ..write('estado: $estado, ')
          ..write('fechaPagoReal: $fechaPagoReal, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }
}

class $PagosDeudaTable extends PagosDeuda
    with TableInfo<$PagosDeudaTable, PagosDeudaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagosDeudaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deudaIdMeta = const VerificationMeta(
    'deudaId',
  );
  @override
  late final GeneratedColumn<int> deudaId = GeneratedColumn<int>(
    'deuda_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES deudas (id)',
    ),
  );
  static const VerificationMeta _montoAbonadoMeta = const VerificationMeta(
    'montoAbonado',
  );
  @override
  late final GeneratedColumn<double> montoAbonado = GeneratedColumn<double>(
    'monto_abonado',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaPagoMeta = const VerificationMeta(
    'fechaPago',
  );
  @override
  late final GeneratedColumn<DateTime> fechaPago = GeneratedColumn<DateTime>(
    'fecha_pago',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deudaId,
    montoAbonado,
    fechaPago,
    notas,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pagos_deuda';
  @override
  VerificationContext validateIntegrity(
    Insertable<PagosDeudaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deuda_id')) {
      context.handle(
        _deudaIdMeta,
        deudaId.isAcceptableOrUnknown(data['deuda_id']!, _deudaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deudaIdMeta);
    }
    if (data.containsKey('monto_abonado')) {
      context.handle(
        _montoAbonadoMeta,
        montoAbonado.isAcceptableOrUnknown(
          data['monto_abonado']!,
          _montoAbonadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoAbonadoMeta);
    }
    if (data.containsKey('fecha_pago')) {
      context.handle(
        _fechaPagoMeta,
        fechaPago.isAcceptableOrUnknown(data['fecha_pago']!, _fechaPagoMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaPagoMeta);
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PagosDeudaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PagosDeudaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deudaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deuda_id'],
      )!,
      montoAbonado: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_abonado'],
      )!,
      fechaPago: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_pago'],
      )!,
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $PagosDeudaTable createAlias(String alias) {
    return $PagosDeudaTable(attachedDatabase, alias);
  }
}

class PagosDeudaData extends DataClass implements Insertable<PagosDeudaData> {
  final int id;
  final int deudaId;
  final double montoAbonado;
  final DateTime fechaPago;
  final String notas;
  final DateTime creadoEn;
  const PagosDeudaData({
    required this.id,
    required this.deudaId,
    required this.montoAbonado,
    required this.fechaPago,
    required this.notas,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deuda_id'] = Variable<int>(deudaId);
    map['monto_abonado'] = Variable<double>(montoAbonado);
    map['fecha_pago'] = Variable<DateTime>(fechaPago);
    map['notas'] = Variable<String>(notas);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  PagosDeudaCompanion toCompanion(bool nullToAbsent) {
    return PagosDeudaCompanion(
      id: Value(id),
      deudaId: Value(deudaId),
      montoAbonado: Value(montoAbonado),
      fechaPago: Value(fechaPago),
      notas: Value(notas),
      creadoEn: Value(creadoEn),
    );
  }

  factory PagosDeudaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PagosDeudaData(
      id: serializer.fromJson<int>(json['id']),
      deudaId: serializer.fromJson<int>(json['deudaId']),
      montoAbonado: serializer.fromJson<double>(json['montoAbonado']),
      fechaPago: serializer.fromJson<DateTime>(json['fechaPago']),
      notas: serializer.fromJson<String>(json['notas']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deudaId': serializer.toJson<int>(deudaId),
      'montoAbonado': serializer.toJson<double>(montoAbonado),
      'fechaPago': serializer.toJson<DateTime>(fechaPago),
      'notas': serializer.toJson<String>(notas),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  PagosDeudaData copyWith({
    int? id,
    int? deudaId,
    double? montoAbonado,
    DateTime? fechaPago,
    String? notas,
    DateTime? creadoEn,
  }) => PagosDeudaData(
    id: id ?? this.id,
    deudaId: deudaId ?? this.deudaId,
    montoAbonado: montoAbonado ?? this.montoAbonado,
    fechaPago: fechaPago ?? this.fechaPago,
    notas: notas ?? this.notas,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  PagosDeudaData copyWithCompanion(PagosDeudaCompanion data) {
    return PagosDeudaData(
      id: data.id.present ? data.id.value : this.id,
      deudaId: data.deudaId.present ? data.deudaId.value : this.deudaId,
      montoAbonado: data.montoAbonado.present
          ? data.montoAbonado.value
          : this.montoAbonado,
      fechaPago: data.fechaPago.present ? data.fechaPago.value : this.fechaPago,
      notas: data.notas.present ? data.notas.value : this.notas,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PagosDeudaData(')
          ..write('id: $id, ')
          ..write('deudaId: $deudaId, ')
          ..write('montoAbonado: $montoAbonado, ')
          ..write('fechaPago: $fechaPago, ')
          ..write('notas: $notas, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, deudaId, montoAbonado, fechaPago, notas, creadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PagosDeudaData &&
          other.id == this.id &&
          other.deudaId == this.deudaId &&
          other.montoAbonado == this.montoAbonado &&
          other.fechaPago == this.fechaPago &&
          other.notas == this.notas &&
          other.creadoEn == this.creadoEn);
}

class PagosDeudaCompanion extends UpdateCompanion<PagosDeudaData> {
  final Value<int> id;
  final Value<int> deudaId;
  final Value<double> montoAbonado;
  final Value<DateTime> fechaPago;
  final Value<String> notas;
  final Value<DateTime> creadoEn;
  const PagosDeudaCompanion({
    this.id = const Value.absent(),
    this.deudaId = const Value.absent(),
    this.montoAbonado = const Value.absent(),
    this.fechaPago = const Value.absent(),
    this.notas = const Value.absent(),
    this.creadoEn = const Value.absent(),
  });
  PagosDeudaCompanion.insert({
    this.id = const Value.absent(),
    required int deudaId,
    required double montoAbonado,
    required DateTime fechaPago,
    this.notas = const Value.absent(),
    this.creadoEn = const Value.absent(),
  }) : deudaId = Value(deudaId),
       montoAbonado = Value(montoAbonado),
       fechaPago = Value(fechaPago);
  static Insertable<PagosDeudaData> custom({
    Expression<int>? id,
    Expression<int>? deudaId,
    Expression<double>? montoAbonado,
    Expression<DateTime>? fechaPago,
    Expression<String>? notas,
    Expression<DateTime>? creadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deudaId != null) 'deuda_id': deudaId,
      if (montoAbonado != null) 'monto_abonado': montoAbonado,
      if (fechaPago != null) 'fecha_pago': fechaPago,
      if (notas != null) 'notas': notas,
      if (creadoEn != null) 'creado_en': creadoEn,
    });
  }

  PagosDeudaCompanion copyWith({
    Value<int>? id,
    Value<int>? deudaId,
    Value<double>? montoAbonado,
    Value<DateTime>? fechaPago,
    Value<String>? notas,
    Value<DateTime>? creadoEn,
  }) {
    return PagosDeudaCompanion(
      id: id ?? this.id,
      deudaId: deudaId ?? this.deudaId,
      montoAbonado: montoAbonado ?? this.montoAbonado,
      fechaPago: fechaPago ?? this.fechaPago,
      notas: notas ?? this.notas,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deudaId.present) {
      map['deuda_id'] = Variable<int>(deudaId.value);
    }
    if (montoAbonado.present) {
      map['monto_abonado'] = Variable<double>(montoAbonado.value);
    }
    if (fechaPago.present) {
      map['fecha_pago'] = Variable<DateTime>(fechaPago.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagosDeudaCompanion(')
          ..write('id: $id, ')
          ..write('deudaId: $deudaId, ')
          ..write('montoAbonado: $montoAbonado, ')
          ..write('fechaPago: $fechaPago, ')
          ..write('notas: $notas, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }
}

class $PrestamosTable extends Prestamos
    with TableInfo<$PrestamosTable, Prestamo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrestamosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deudorNombreMeta = const VerificationMeta(
    'deudorNombre',
  );
  @override
  late final GeneratedColumn<String> deudorNombre = GeneratedColumn<String>(
    'deudor_nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deudorContactoMeta = const VerificationMeta(
    'deudorContacto',
  );
  @override
  late final GeneratedColumn<String> deudorContacto = GeneratedColumn<String>(
    'deudor_contacto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _montoPrestadoMeta = const VerificationMeta(
    'montoPrestado',
  );
  @override
  late final GeneratedColumn<double> montoPrestado = GeneratedColumn<double>(
    'monto_prestado',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tasaInteresMeta = const VerificationMeta(
    'tasaInteres',
  );
  @override
  late final GeneratedColumn<double> tasaInteres = GeneratedColumn<double>(
    'tasa_interes',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tipoInteresMeta = const VerificationMeta(
    'tipoInteres',
  );
  @override
  late final GeneratedColumn<String> tipoInteres = GeneratedColumn<String>(
    'tipo_interes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ninguno'),
  );
  static const VerificationMeta _modalidadCalculoMeta = const VerificationMeta(
    'modalidadCalculo',
  );
  @override
  late final GeneratedColumn<String> modalidadCalculo = GeneratedColumn<String>(
    'modalidad_calculo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('simple'),
  );
  static const VerificationMeta _fechaPrestamoMeta = const VerificationMeta(
    'fechaPrestamo',
  );
  @override
  late final GeneratedColumn<DateTime> fechaPrestamo =
      GeneratedColumn<DateTime>(
        'fecha_prestamo',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fechaPactadaPagoMeta = const VerificationMeta(
    'fechaPactadaPago',
  );
  @override
  late final GeneratedColumn<DateTime> fechaPactadaPago =
      GeneratedColumn<DateTime>(
        'fecha_pactada_pago',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('activo'),
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deudorNombre,
    deudorContacto,
    montoPrestado,
    tasaInteres,
    tipoInteres,
    modalidadCalculo,
    fechaPrestamo,
    fechaPactadaPago,
    estado,
    notas,
    creadoEn,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prestamos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prestamo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deudor_nombre')) {
      context.handle(
        _deudorNombreMeta,
        deudorNombre.isAcceptableOrUnknown(
          data['deudor_nombre']!,
          _deudorNombreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deudorNombreMeta);
    }
    if (data.containsKey('deudor_contacto')) {
      context.handle(
        _deudorContactoMeta,
        deudorContacto.isAcceptableOrUnknown(
          data['deudor_contacto']!,
          _deudorContactoMeta,
        ),
      );
    }
    if (data.containsKey('monto_prestado')) {
      context.handle(
        _montoPrestadoMeta,
        montoPrestado.isAcceptableOrUnknown(
          data['monto_prestado']!,
          _montoPrestadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoPrestadoMeta);
    }
    if (data.containsKey('tasa_interes')) {
      context.handle(
        _tasaInteresMeta,
        tasaInteres.isAcceptableOrUnknown(
          data['tasa_interes']!,
          _tasaInteresMeta,
        ),
      );
    }
    if (data.containsKey('tipo_interes')) {
      context.handle(
        _tipoInteresMeta,
        tipoInteres.isAcceptableOrUnknown(
          data['tipo_interes']!,
          _tipoInteresMeta,
        ),
      );
    }
    if (data.containsKey('modalidad_calculo')) {
      context.handle(
        _modalidadCalculoMeta,
        modalidadCalculo.isAcceptableOrUnknown(
          data['modalidad_calculo']!,
          _modalidadCalculoMeta,
        ),
      );
    }
    if (data.containsKey('fecha_prestamo')) {
      context.handle(
        _fechaPrestamoMeta,
        fechaPrestamo.isAcceptableOrUnknown(
          data['fecha_prestamo']!,
          _fechaPrestamoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaPrestamoMeta);
    }
    if (data.containsKey('fecha_pactada_pago')) {
      context.handle(
        _fechaPactadaPagoMeta,
        fechaPactadaPago.isAcceptableOrUnknown(
          data['fecha_pactada_pago']!,
          _fechaPactadaPagoMeta,
        ),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prestamo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prestamo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deudorNombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deudor_nombre'],
      )!,
      deudorContacto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deudor_contacto'],
      )!,
      montoPrestado: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_prestado'],
      )!,
      tasaInteres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tasa_interes'],
      )!,
      tipoInteres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_interes'],
      )!,
      modalidadCalculo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modalidad_calculo'],
      )!,
      fechaPrestamo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_prestamo'],
      )!,
      fechaPactadaPago: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_pactada_pago'],
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      )!,
    );
  }

  @override
  $PrestamosTable createAlias(String alias) {
    return $PrestamosTable(attachedDatabase, alias);
  }
}

class Prestamo extends DataClass implements Insertable<Prestamo> {
  final int id;
  final String deudorNombre;
  final String deudorContacto;
  final double montoPrestado;
  final double tasaInteres;
  final String tipoInteres;
  final String modalidadCalculo;
  final DateTime fechaPrestamo;
  final DateTime? fechaPactadaPago;
  final String estado;
  final String notas;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  const Prestamo({
    required this.id,
    required this.deudorNombre,
    required this.deudorContacto,
    required this.montoPrestado,
    required this.tasaInteres,
    required this.tipoInteres,
    required this.modalidadCalculo,
    required this.fechaPrestamo,
    this.fechaPactadaPago,
    required this.estado,
    required this.notas,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deudor_nombre'] = Variable<String>(deudorNombre);
    map['deudor_contacto'] = Variable<String>(deudorContacto);
    map['monto_prestado'] = Variable<double>(montoPrestado);
    map['tasa_interes'] = Variable<double>(tasaInteres);
    map['tipo_interes'] = Variable<String>(tipoInteres);
    map['modalidad_calculo'] = Variable<String>(modalidadCalculo);
    map['fecha_prestamo'] = Variable<DateTime>(fechaPrestamo);
    if (!nullToAbsent || fechaPactadaPago != null) {
      map['fecha_pactada_pago'] = Variable<DateTime>(fechaPactadaPago);
    }
    map['estado'] = Variable<String>(estado);
    map['notas'] = Variable<String>(notas);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    return map;
  }

  PrestamosCompanion toCompanion(bool nullToAbsent) {
    return PrestamosCompanion(
      id: Value(id),
      deudorNombre: Value(deudorNombre),
      deudorContacto: Value(deudorContacto),
      montoPrestado: Value(montoPrestado),
      tasaInteres: Value(tasaInteres),
      tipoInteres: Value(tipoInteres),
      modalidadCalculo: Value(modalidadCalculo),
      fechaPrestamo: Value(fechaPrestamo),
      fechaPactadaPago: fechaPactadaPago == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaPactadaPago),
      estado: Value(estado),
      notas: Value(notas),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory Prestamo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prestamo(
      id: serializer.fromJson<int>(json['id']),
      deudorNombre: serializer.fromJson<String>(json['deudorNombre']),
      deudorContacto: serializer.fromJson<String>(json['deudorContacto']),
      montoPrestado: serializer.fromJson<double>(json['montoPrestado']),
      tasaInteres: serializer.fromJson<double>(json['tasaInteres']),
      tipoInteres: serializer.fromJson<String>(json['tipoInteres']),
      modalidadCalculo: serializer.fromJson<String>(json['modalidadCalculo']),
      fechaPrestamo: serializer.fromJson<DateTime>(json['fechaPrestamo']),
      fechaPactadaPago: serializer.fromJson<DateTime?>(
        json['fechaPactadaPago'],
      ),
      estado: serializer.fromJson<String>(json['estado']),
      notas: serializer.fromJson<String>(json['notas']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deudorNombre': serializer.toJson<String>(deudorNombre),
      'deudorContacto': serializer.toJson<String>(deudorContacto),
      'montoPrestado': serializer.toJson<double>(montoPrestado),
      'tasaInteres': serializer.toJson<double>(tasaInteres),
      'tipoInteres': serializer.toJson<String>(tipoInteres),
      'modalidadCalculo': serializer.toJson<String>(modalidadCalculo),
      'fechaPrestamo': serializer.toJson<DateTime>(fechaPrestamo),
      'fechaPactadaPago': serializer.toJson<DateTime?>(fechaPactadaPago),
      'estado': serializer.toJson<String>(estado),
      'notas': serializer.toJson<String>(notas),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
    };
  }

  Prestamo copyWith({
    int? id,
    String? deudorNombre,
    String? deudorContacto,
    double? montoPrestado,
    double? tasaInteres,
    String? tipoInteres,
    String? modalidadCalculo,
    DateTime? fechaPrestamo,
    Value<DateTime?> fechaPactadaPago = const Value.absent(),
    String? estado,
    String? notas,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) => Prestamo(
    id: id ?? this.id,
    deudorNombre: deudorNombre ?? this.deudorNombre,
    deudorContacto: deudorContacto ?? this.deudorContacto,
    montoPrestado: montoPrestado ?? this.montoPrestado,
    tasaInteres: tasaInteres ?? this.tasaInteres,
    tipoInteres: tipoInteres ?? this.tipoInteres,
    modalidadCalculo: modalidadCalculo ?? this.modalidadCalculo,
    fechaPrestamo: fechaPrestamo ?? this.fechaPrestamo,
    fechaPactadaPago: fechaPactadaPago.present
        ? fechaPactadaPago.value
        : this.fechaPactadaPago,
    estado: estado ?? this.estado,
    notas: notas ?? this.notas,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  Prestamo copyWithCompanion(PrestamosCompanion data) {
    return Prestamo(
      id: data.id.present ? data.id.value : this.id,
      deudorNombre: data.deudorNombre.present
          ? data.deudorNombre.value
          : this.deudorNombre,
      deudorContacto: data.deudorContacto.present
          ? data.deudorContacto.value
          : this.deudorContacto,
      montoPrestado: data.montoPrestado.present
          ? data.montoPrestado.value
          : this.montoPrestado,
      tasaInteres: data.tasaInteres.present
          ? data.tasaInteres.value
          : this.tasaInteres,
      tipoInteres: data.tipoInteres.present
          ? data.tipoInteres.value
          : this.tipoInteres,
      modalidadCalculo: data.modalidadCalculo.present
          ? data.modalidadCalculo.value
          : this.modalidadCalculo,
      fechaPrestamo: data.fechaPrestamo.present
          ? data.fechaPrestamo.value
          : this.fechaPrestamo,
      fechaPactadaPago: data.fechaPactadaPago.present
          ? data.fechaPactadaPago.value
          : this.fechaPactadaPago,
      estado: data.estado.present ? data.estado.value : this.estado,
      notas: data.notas.present ? data.notas.value : this.notas,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prestamo(')
          ..write('id: $id, ')
          ..write('deudorNombre: $deudorNombre, ')
          ..write('deudorContacto: $deudorContacto, ')
          ..write('montoPrestado: $montoPrestado, ')
          ..write('tasaInteres: $tasaInteres, ')
          ..write('tipoInteres: $tipoInteres, ')
          ..write('modalidadCalculo: $modalidadCalculo, ')
          ..write('fechaPrestamo: $fechaPrestamo, ')
          ..write('fechaPactadaPago: $fechaPactadaPago, ')
          ..write('estado: $estado, ')
          ..write('notas: $notas, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deudorNombre,
    deudorContacto,
    montoPrestado,
    tasaInteres,
    tipoInteres,
    modalidadCalculo,
    fechaPrestamo,
    fechaPactadaPago,
    estado,
    notas,
    creadoEn,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prestamo &&
          other.id == this.id &&
          other.deudorNombre == this.deudorNombre &&
          other.deudorContacto == this.deudorContacto &&
          other.montoPrestado == this.montoPrestado &&
          other.tasaInteres == this.tasaInteres &&
          other.tipoInteres == this.tipoInteres &&
          other.modalidadCalculo == this.modalidadCalculo &&
          other.fechaPrestamo == this.fechaPrestamo &&
          other.fechaPactadaPago == this.fechaPactadaPago &&
          other.estado == this.estado &&
          other.notas == this.notas &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn);
}

class PrestamosCompanion extends UpdateCompanion<Prestamo> {
  final Value<int> id;
  final Value<String> deudorNombre;
  final Value<String> deudorContacto;
  final Value<double> montoPrestado;
  final Value<double> tasaInteres;
  final Value<String> tipoInteres;
  final Value<String> modalidadCalculo;
  final Value<DateTime> fechaPrestamo;
  final Value<DateTime?> fechaPactadaPago;
  final Value<String> estado;
  final Value<String> notas;
  final Value<DateTime> creadoEn;
  final Value<DateTime> actualizadoEn;
  const PrestamosCompanion({
    this.id = const Value.absent(),
    this.deudorNombre = const Value.absent(),
    this.deudorContacto = const Value.absent(),
    this.montoPrestado = const Value.absent(),
    this.tasaInteres = const Value.absent(),
    this.tipoInteres = const Value.absent(),
    this.modalidadCalculo = const Value.absent(),
    this.fechaPrestamo = const Value.absent(),
    this.fechaPactadaPago = const Value.absent(),
    this.estado = const Value.absent(),
    this.notas = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  });
  PrestamosCompanion.insert({
    this.id = const Value.absent(),
    required String deudorNombre,
    this.deudorContacto = const Value.absent(),
    required double montoPrestado,
    this.tasaInteres = const Value.absent(),
    this.tipoInteres = const Value.absent(),
    this.modalidadCalculo = const Value.absent(),
    required DateTime fechaPrestamo,
    this.fechaPactadaPago = const Value.absent(),
    this.estado = const Value.absent(),
    this.notas = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  }) : deudorNombre = Value(deudorNombre),
       montoPrestado = Value(montoPrestado),
       fechaPrestamo = Value(fechaPrestamo);
  static Insertable<Prestamo> custom({
    Expression<int>? id,
    Expression<String>? deudorNombre,
    Expression<String>? deudorContacto,
    Expression<double>? montoPrestado,
    Expression<double>? tasaInteres,
    Expression<String>? tipoInteres,
    Expression<String>? modalidadCalculo,
    Expression<DateTime>? fechaPrestamo,
    Expression<DateTime>? fechaPactadaPago,
    Expression<String>? estado,
    Expression<String>? notas,
    Expression<DateTime>? creadoEn,
    Expression<DateTime>? actualizadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deudorNombre != null) 'deudor_nombre': deudorNombre,
      if (deudorContacto != null) 'deudor_contacto': deudorContacto,
      if (montoPrestado != null) 'monto_prestado': montoPrestado,
      if (tasaInteres != null) 'tasa_interes': tasaInteres,
      if (tipoInteres != null) 'tipo_interes': tipoInteres,
      if (modalidadCalculo != null) 'modalidad_calculo': modalidadCalculo,
      if (fechaPrestamo != null) 'fecha_prestamo': fechaPrestamo,
      if (fechaPactadaPago != null) 'fecha_pactada_pago': fechaPactadaPago,
      if (estado != null) 'estado': estado,
      if (notas != null) 'notas': notas,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
    });
  }

  PrestamosCompanion copyWith({
    Value<int>? id,
    Value<String>? deudorNombre,
    Value<String>? deudorContacto,
    Value<double>? montoPrestado,
    Value<double>? tasaInteres,
    Value<String>? tipoInteres,
    Value<String>? modalidadCalculo,
    Value<DateTime>? fechaPrestamo,
    Value<DateTime?>? fechaPactadaPago,
    Value<String>? estado,
    Value<String>? notas,
    Value<DateTime>? creadoEn,
    Value<DateTime>? actualizadoEn,
  }) {
    return PrestamosCompanion(
      id: id ?? this.id,
      deudorNombre: deudorNombre ?? this.deudorNombre,
      deudorContacto: deudorContacto ?? this.deudorContacto,
      montoPrestado: montoPrestado ?? this.montoPrestado,
      tasaInteres: tasaInteres ?? this.tasaInteres,
      tipoInteres: tipoInteres ?? this.tipoInteres,
      modalidadCalculo: modalidadCalculo ?? this.modalidadCalculo,
      fechaPrestamo: fechaPrestamo ?? this.fechaPrestamo,
      fechaPactadaPago: fechaPactadaPago ?? this.fechaPactadaPago,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deudorNombre.present) {
      map['deudor_nombre'] = Variable<String>(deudorNombre.value);
    }
    if (deudorContacto.present) {
      map['deudor_contacto'] = Variable<String>(deudorContacto.value);
    }
    if (montoPrestado.present) {
      map['monto_prestado'] = Variable<double>(montoPrestado.value);
    }
    if (tasaInteres.present) {
      map['tasa_interes'] = Variable<double>(tasaInteres.value);
    }
    if (tipoInteres.present) {
      map['tipo_interes'] = Variable<String>(tipoInteres.value);
    }
    if (modalidadCalculo.present) {
      map['modalidad_calculo'] = Variable<String>(modalidadCalculo.value);
    }
    if (fechaPrestamo.present) {
      map['fecha_prestamo'] = Variable<DateTime>(fechaPrestamo.value);
    }
    if (fechaPactadaPago.present) {
      map['fecha_pactada_pago'] = Variable<DateTime>(fechaPactadaPago.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrestamosCompanion(')
          ..write('id: $id, ')
          ..write('deudorNombre: $deudorNombre, ')
          ..write('deudorContacto: $deudorContacto, ')
          ..write('montoPrestado: $montoPrestado, ')
          ..write('tasaInteres: $tasaInteres, ')
          ..write('tipoInteres: $tipoInteres, ')
          ..write('modalidadCalculo: $modalidadCalculo, ')
          ..write('fechaPrestamo: $fechaPrestamo, ')
          ..write('fechaPactadaPago: $fechaPactadaPago, ')
          ..write('estado: $estado, ')
          ..write('notas: $notas, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }
}

class $PagosRecibidosTable extends PagosRecibidos
    with TableInfo<$PagosRecibidosTable, PagosRecibido> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagosRecibidosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _prestamoIdMeta = const VerificationMeta(
    'prestamoId',
  );
  @override
  late final GeneratedColumn<int> prestamoId = GeneratedColumn<int>(
    'prestamo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prestamos (id)',
    ),
  );
  static const VerificationMeta _montoAbonadoMeta = const VerificationMeta(
    'montoAbonado',
  );
  @override
  late final GeneratedColumn<double> montoAbonado = GeneratedColumn<double>(
    'monto_abonado',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaPagoMeta = const VerificationMeta(
    'fechaPago',
  );
  @override
  late final GeneratedColumn<DateTime> fechaPago = GeneratedColumn<DateTime>(
    'fecha_pago',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    prestamoId,
    montoAbonado,
    fechaPago,
    notas,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pagos_recibidos';
  @override
  VerificationContext validateIntegrity(
    Insertable<PagosRecibido> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prestamo_id')) {
      context.handle(
        _prestamoIdMeta,
        prestamoId.isAcceptableOrUnknown(data['prestamo_id']!, _prestamoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_prestamoIdMeta);
    }
    if (data.containsKey('monto_abonado')) {
      context.handle(
        _montoAbonadoMeta,
        montoAbonado.isAcceptableOrUnknown(
          data['monto_abonado']!,
          _montoAbonadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoAbonadoMeta);
    }
    if (data.containsKey('fecha_pago')) {
      context.handle(
        _fechaPagoMeta,
        fechaPago.isAcceptableOrUnknown(data['fecha_pago']!, _fechaPagoMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaPagoMeta);
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PagosRecibido map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PagosRecibido(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      prestamoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prestamo_id'],
      )!,
      montoAbonado: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_abonado'],
      )!,
      fechaPago: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_pago'],
      )!,
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $PagosRecibidosTable createAlias(String alias) {
    return $PagosRecibidosTable(attachedDatabase, alias);
  }
}

class PagosRecibido extends DataClass implements Insertable<PagosRecibido> {
  final int id;
  final int prestamoId;
  final double montoAbonado;
  final DateTime fechaPago;
  final String notas;
  final DateTime creadoEn;
  const PagosRecibido({
    required this.id,
    required this.prestamoId,
    required this.montoAbonado,
    required this.fechaPago,
    required this.notas,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prestamo_id'] = Variable<int>(prestamoId);
    map['monto_abonado'] = Variable<double>(montoAbonado);
    map['fecha_pago'] = Variable<DateTime>(fechaPago);
    map['notas'] = Variable<String>(notas);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  PagosRecibidosCompanion toCompanion(bool nullToAbsent) {
    return PagosRecibidosCompanion(
      id: Value(id),
      prestamoId: Value(prestamoId),
      montoAbonado: Value(montoAbonado),
      fechaPago: Value(fechaPago),
      notas: Value(notas),
      creadoEn: Value(creadoEn),
    );
  }

  factory PagosRecibido.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PagosRecibido(
      id: serializer.fromJson<int>(json['id']),
      prestamoId: serializer.fromJson<int>(json['prestamoId']),
      montoAbonado: serializer.fromJson<double>(json['montoAbonado']),
      fechaPago: serializer.fromJson<DateTime>(json['fechaPago']),
      notas: serializer.fromJson<String>(json['notas']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'prestamoId': serializer.toJson<int>(prestamoId),
      'montoAbonado': serializer.toJson<double>(montoAbonado),
      'fechaPago': serializer.toJson<DateTime>(fechaPago),
      'notas': serializer.toJson<String>(notas),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  PagosRecibido copyWith({
    int? id,
    int? prestamoId,
    double? montoAbonado,
    DateTime? fechaPago,
    String? notas,
    DateTime? creadoEn,
  }) => PagosRecibido(
    id: id ?? this.id,
    prestamoId: prestamoId ?? this.prestamoId,
    montoAbonado: montoAbonado ?? this.montoAbonado,
    fechaPago: fechaPago ?? this.fechaPago,
    notas: notas ?? this.notas,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  PagosRecibido copyWithCompanion(PagosRecibidosCompanion data) {
    return PagosRecibido(
      id: data.id.present ? data.id.value : this.id,
      prestamoId: data.prestamoId.present
          ? data.prestamoId.value
          : this.prestamoId,
      montoAbonado: data.montoAbonado.present
          ? data.montoAbonado.value
          : this.montoAbonado,
      fechaPago: data.fechaPago.present ? data.fechaPago.value : this.fechaPago,
      notas: data.notas.present ? data.notas.value : this.notas,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PagosRecibido(')
          ..write('id: $id, ')
          ..write('prestamoId: $prestamoId, ')
          ..write('montoAbonado: $montoAbonado, ')
          ..write('fechaPago: $fechaPago, ')
          ..write('notas: $notas, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, prestamoId, montoAbonado, fechaPago, notas, creadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PagosRecibido &&
          other.id == this.id &&
          other.prestamoId == this.prestamoId &&
          other.montoAbonado == this.montoAbonado &&
          other.fechaPago == this.fechaPago &&
          other.notas == this.notas &&
          other.creadoEn == this.creadoEn);
}

class PagosRecibidosCompanion extends UpdateCompanion<PagosRecibido> {
  final Value<int> id;
  final Value<int> prestamoId;
  final Value<double> montoAbonado;
  final Value<DateTime> fechaPago;
  final Value<String> notas;
  final Value<DateTime> creadoEn;
  const PagosRecibidosCompanion({
    this.id = const Value.absent(),
    this.prestamoId = const Value.absent(),
    this.montoAbonado = const Value.absent(),
    this.fechaPago = const Value.absent(),
    this.notas = const Value.absent(),
    this.creadoEn = const Value.absent(),
  });
  PagosRecibidosCompanion.insert({
    this.id = const Value.absent(),
    required int prestamoId,
    required double montoAbonado,
    required DateTime fechaPago,
    this.notas = const Value.absent(),
    this.creadoEn = const Value.absent(),
  }) : prestamoId = Value(prestamoId),
       montoAbonado = Value(montoAbonado),
       fechaPago = Value(fechaPago);
  static Insertable<PagosRecibido> custom({
    Expression<int>? id,
    Expression<int>? prestamoId,
    Expression<double>? montoAbonado,
    Expression<DateTime>? fechaPago,
    Expression<String>? notas,
    Expression<DateTime>? creadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prestamoId != null) 'prestamo_id': prestamoId,
      if (montoAbonado != null) 'monto_abonado': montoAbonado,
      if (fechaPago != null) 'fecha_pago': fechaPago,
      if (notas != null) 'notas': notas,
      if (creadoEn != null) 'creado_en': creadoEn,
    });
  }

  PagosRecibidosCompanion copyWith({
    Value<int>? id,
    Value<int>? prestamoId,
    Value<double>? montoAbonado,
    Value<DateTime>? fechaPago,
    Value<String>? notas,
    Value<DateTime>? creadoEn,
  }) {
    return PagosRecibidosCompanion(
      id: id ?? this.id,
      prestamoId: prestamoId ?? this.prestamoId,
      montoAbonado: montoAbonado ?? this.montoAbonado,
      fechaPago: fechaPago ?? this.fechaPago,
      notas: notas ?? this.notas,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (prestamoId.present) {
      map['prestamo_id'] = Variable<int>(prestamoId.value);
    }
    if (montoAbonado.present) {
      map['monto_abonado'] = Variable<double>(montoAbonado.value);
    }
    if (fechaPago.present) {
      map['fecha_pago'] = Variable<DateTime>(fechaPago.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagosRecibidosCompanion(')
          ..write('id: $id, ')
          ..write('prestamoId: $prestamoId, ')
          ..write('montoAbonado: $montoAbonado, ')
          ..write('fechaPago: $fechaPago, ')
          ..write('notas: $notas, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }
}

class $IngresosTable extends Ingresos with TableInfo<$IngresosTable, Ingreso> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngresosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _conceptoMeta = const VerificationMeta(
    'concepto',
  );
  @override
  late final GeneratedColumn<String> concepto = GeneratedColumn<String>(
    'concepto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frecuenciaMeta = const VerificationMeta(
    'frecuencia',
  );
  @override
  late final GeneratedColumn<String> frecuencia = GeneratedColumn<String>(
    'frecuencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mensual'),
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    concepto,
    monto,
    frecuencia,
    fecha,
    notas,
    activo,
    creadoEn,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingresos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ingreso> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('concepto')) {
      context.handle(
        _conceptoMeta,
        concepto.isAcceptableOrUnknown(data['concepto']!, _conceptoMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptoMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('frecuencia')) {
      context.handle(
        _frecuenciaMeta,
        frecuencia.isAcceptableOrUnknown(data['frecuencia']!, _frecuenciaMeta),
      );
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingreso map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingreso(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      concepto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concepto'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      frecuencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frecuencia'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      )!,
    );
  }

  @override
  $IngresosTable createAlias(String alias) {
    return $IngresosTable(attachedDatabase, alias);
  }
}

class Ingreso extends DataClass implements Insertable<Ingreso> {
  final int id;
  final String concepto;
  final double monto;
  final String frecuencia;
  final DateTime fecha;
  final String notas;
  final bool activo;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  const Ingreso({
    required this.id,
    required this.concepto,
    required this.monto,
    required this.frecuencia,
    required this.fecha,
    required this.notas,
    required this.activo,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['concepto'] = Variable<String>(concepto);
    map['monto'] = Variable<double>(monto);
    map['frecuencia'] = Variable<String>(frecuencia);
    map['fecha'] = Variable<DateTime>(fecha);
    map['notas'] = Variable<String>(notas);
    map['activo'] = Variable<bool>(activo);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    return map;
  }

  IngresosCompanion toCompanion(bool nullToAbsent) {
    return IngresosCompanion(
      id: Value(id),
      concepto: Value(concepto),
      monto: Value(monto),
      frecuencia: Value(frecuencia),
      fecha: Value(fecha),
      notas: Value(notas),
      activo: Value(activo),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory Ingreso.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingreso(
      id: serializer.fromJson<int>(json['id']),
      concepto: serializer.fromJson<String>(json['concepto']),
      monto: serializer.fromJson<double>(json['monto']),
      frecuencia: serializer.fromJson<String>(json['frecuencia']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      notas: serializer.fromJson<String>(json['notas']),
      activo: serializer.fromJson<bool>(json['activo']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'concepto': serializer.toJson<String>(concepto),
      'monto': serializer.toJson<double>(monto),
      'frecuencia': serializer.toJson<String>(frecuencia),
      'fecha': serializer.toJson<DateTime>(fecha),
      'notas': serializer.toJson<String>(notas),
      'activo': serializer.toJson<bool>(activo),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
    };
  }

  Ingreso copyWith({
    int? id,
    String? concepto,
    double? monto,
    String? frecuencia,
    DateTime? fecha,
    String? notas,
    bool? activo,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) => Ingreso(
    id: id ?? this.id,
    concepto: concepto ?? this.concepto,
    monto: monto ?? this.monto,
    frecuencia: frecuencia ?? this.frecuencia,
    fecha: fecha ?? this.fecha,
    notas: notas ?? this.notas,
    activo: activo ?? this.activo,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  Ingreso copyWithCompanion(IngresosCompanion data) {
    return Ingreso(
      id: data.id.present ? data.id.value : this.id,
      concepto: data.concepto.present ? data.concepto.value : this.concepto,
      monto: data.monto.present ? data.monto.value : this.monto,
      frecuencia: data.frecuencia.present
          ? data.frecuencia.value
          : this.frecuencia,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      notas: data.notas.present ? data.notas.value : this.notas,
      activo: data.activo.present ? data.activo.value : this.activo,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingreso(')
          ..write('id: $id, ')
          ..write('concepto: $concepto, ')
          ..write('monto: $monto, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('fecha: $fecha, ')
          ..write('notas: $notas, ')
          ..write('activo: $activo, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    concepto,
    monto,
    frecuencia,
    fecha,
    notas,
    activo,
    creadoEn,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingreso &&
          other.id == this.id &&
          other.concepto == this.concepto &&
          other.monto == this.monto &&
          other.frecuencia == this.frecuencia &&
          other.fecha == this.fecha &&
          other.notas == this.notas &&
          other.activo == this.activo &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn);
}

class IngresosCompanion extends UpdateCompanion<Ingreso> {
  final Value<int> id;
  final Value<String> concepto;
  final Value<double> monto;
  final Value<String> frecuencia;
  final Value<DateTime> fecha;
  final Value<String> notas;
  final Value<bool> activo;
  final Value<DateTime> creadoEn;
  final Value<DateTime> actualizadoEn;
  const IngresosCompanion({
    this.id = const Value.absent(),
    this.concepto = const Value.absent(),
    this.monto = const Value.absent(),
    this.frecuencia = const Value.absent(),
    this.fecha = const Value.absent(),
    this.notas = const Value.absent(),
    this.activo = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  });
  IngresosCompanion.insert({
    this.id = const Value.absent(),
    required String concepto,
    required double monto,
    this.frecuencia = const Value.absent(),
    required DateTime fecha,
    this.notas = const Value.absent(),
    this.activo = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  }) : concepto = Value(concepto),
       monto = Value(monto),
       fecha = Value(fecha);
  static Insertable<Ingreso> custom({
    Expression<int>? id,
    Expression<String>? concepto,
    Expression<double>? monto,
    Expression<String>? frecuencia,
    Expression<DateTime>? fecha,
    Expression<String>? notas,
    Expression<bool>? activo,
    Expression<DateTime>? creadoEn,
    Expression<DateTime>? actualizadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (concepto != null) 'concepto': concepto,
      if (monto != null) 'monto': monto,
      if (frecuencia != null) 'frecuencia': frecuencia,
      if (fecha != null) 'fecha': fecha,
      if (notas != null) 'notas': notas,
      if (activo != null) 'activo': activo,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
    });
  }

  IngresosCompanion copyWith({
    Value<int>? id,
    Value<String>? concepto,
    Value<double>? monto,
    Value<String>? frecuencia,
    Value<DateTime>? fecha,
    Value<String>? notas,
    Value<bool>? activo,
    Value<DateTime>? creadoEn,
    Value<DateTime>? actualizadoEn,
  }) {
    return IngresosCompanion(
      id: id ?? this.id,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      frecuencia: frecuencia ?? this.frecuencia,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
      activo: activo ?? this.activo,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (concepto.present) {
      map['concepto'] = Variable<String>(concepto.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (frecuencia.present) {
      map['frecuencia'] = Variable<String>(frecuencia.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngresosCompanion(')
          ..write('id: $id, ')
          ..write('concepto: $concepto, ')
          ..write('monto: $monto, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('fecha: $fecha, ')
          ..write('notas: $notas, ')
          ..write('activo: $activo, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }
}

class $GastosFijosTable extends GastosFijos
    with TableInfo<$GastosFijosTable, GastosFijo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GastosFijosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _conceptoMeta = const VerificationMeta(
    'concepto',
  );
  @override
  late final GeneratedColumn<String> concepto = GeneratedColumn<String>(
    'concepto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frecuenciaMeta = const VerificationMeta(
    'frecuencia',
  );
  @override
  late final GeneratedColumn<String> frecuencia = GeneratedColumn<String>(
    'frecuencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mensual'),
  );
  static const VerificationMeta _diaCobroMeta = const VerificationMeta(
    'diaCobro',
  );
  @override
  late final GeneratedColumn<int> diaCobro = GeneratedColumn<int>(
    'dia_cobro',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    concepto,
    monto,
    frecuencia,
    diaCobro,
    notas,
    activo,
    creadoEn,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gastos_fijos';
  @override
  VerificationContext validateIntegrity(
    Insertable<GastosFijo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('concepto')) {
      context.handle(
        _conceptoMeta,
        concepto.isAcceptableOrUnknown(data['concepto']!, _conceptoMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptoMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('frecuencia')) {
      context.handle(
        _frecuenciaMeta,
        frecuencia.isAcceptableOrUnknown(data['frecuencia']!, _frecuenciaMeta),
      );
    }
    if (data.containsKey('dia_cobro')) {
      context.handle(
        _diaCobroMeta,
        diaCobro.isAcceptableOrUnknown(data['dia_cobro']!, _diaCobroMeta),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GastosFijo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GastosFijo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      concepto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concepto'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      frecuencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frecuencia'],
      )!,
      diaCobro: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dia_cobro'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      )!,
    );
  }

  @override
  $GastosFijosTable createAlias(String alias) {
    return $GastosFijosTable(attachedDatabase, alias);
  }
}

class GastosFijo extends DataClass implements Insertable<GastosFijo> {
  final int id;
  final String concepto;
  final double monto;
  final String frecuencia;
  final int? diaCobro;
  final String notas;
  final bool activo;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  const GastosFijo({
    required this.id,
    required this.concepto,
    required this.monto,
    required this.frecuencia,
    this.diaCobro,
    required this.notas,
    required this.activo,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['concepto'] = Variable<String>(concepto);
    map['monto'] = Variable<double>(monto);
    map['frecuencia'] = Variable<String>(frecuencia);
    if (!nullToAbsent || diaCobro != null) {
      map['dia_cobro'] = Variable<int>(diaCobro);
    }
    map['notas'] = Variable<String>(notas);
    map['activo'] = Variable<bool>(activo);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    return map;
  }

  GastosFijosCompanion toCompanion(bool nullToAbsent) {
    return GastosFijosCompanion(
      id: Value(id),
      concepto: Value(concepto),
      monto: Value(monto),
      frecuencia: Value(frecuencia),
      diaCobro: diaCobro == null && nullToAbsent
          ? const Value.absent()
          : Value(diaCobro),
      notas: Value(notas),
      activo: Value(activo),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory GastosFijo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GastosFijo(
      id: serializer.fromJson<int>(json['id']),
      concepto: serializer.fromJson<String>(json['concepto']),
      monto: serializer.fromJson<double>(json['monto']),
      frecuencia: serializer.fromJson<String>(json['frecuencia']),
      diaCobro: serializer.fromJson<int?>(json['diaCobro']),
      notas: serializer.fromJson<String>(json['notas']),
      activo: serializer.fromJson<bool>(json['activo']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'concepto': serializer.toJson<String>(concepto),
      'monto': serializer.toJson<double>(monto),
      'frecuencia': serializer.toJson<String>(frecuencia),
      'diaCobro': serializer.toJson<int?>(diaCobro),
      'notas': serializer.toJson<String>(notas),
      'activo': serializer.toJson<bool>(activo),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
    };
  }

  GastosFijo copyWith({
    int? id,
    String? concepto,
    double? monto,
    String? frecuencia,
    Value<int?> diaCobro = const Value.absent(),
    String? notas,
    bool? activo,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) => GastosFijo(
    id: id ?? this.id,
    concepto: concepto ?? this.concepto,
    monto: monto ?? this.monto,
    frecuencia: frecuencia ?? this.frecuencia,
    diaCobro: diaCobro.present ? diaCobro.value : this.diaCobro,
    notas: notas ?? this.notas,
    activo: activo ?? this.activo,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  GastosFijo copyWithCompanion(GastosFijosCompanion data) {
    return GastosFijo(
      id: data.id.present ? data.id.value : this.id,
      concepto: data.concepto.present ? data.concepto.value : this.concepto,
      monto: data.monto.present ? data.monto.value : this.monto,
      frecuencia: data.frecuencia.present
          ? data.frecuencia.value
          : this.frecuencia,
      diaCobro: data.diaCobro.present ? data.diaCobro.value : this.diaCobro,
      notas: data.notas.present ? data.notas.value : this.notas,
      activo: data.activo.present ? data.activo.value : this.activo,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GastosFijo(')
          ..write('id: $id, ')
          ..write('concepto: $concepto, ')
          ..write('monto: $monto, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('diaCobro: $diaCobro, ')
          ..write('notas: $notas, ')
          ..write('activo: $activo, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    concepto,
    monto,
    frecuencia,
    diaCobro,
    notas,
    activo,
    creadoEn,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GastosFijo &&
          other.id == this.id &&
          other.concepto == this.concepto &&
          other.monto == this.monto &&
          other.frecuencia == this.frecuencia &&
          other.diaCobro == this.diaCobro &&
          other.notas == this.notas &&
          other.activo == this.activo &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn);
}

class GastosFijosCompanion extends UpdateCompanion<GastosFijo> {
  final Value<int> id;
  final Value<String> concepto;
  final Value<double> monto;
  final Value<String> frecuencia;
  final Value<int?> diaCobro;
  final Value<String> notas;
  final Value<bool> activo;
  final Value<DateTime> creadoEn;
  final Value<DateTime> actualizadoEn;
  const GastosFijosCompanion({
    this.id = const Value.absent(),
    this.concepto = const Value.absent(),
    this.monto = const Value.absent(),
    this.frecuencia = const Value.absent(),
    this.diaCobro = const Value.absent(),
    this.notas = const Value.absent(),
    this.activo = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  });
  GastosFijosCompanion.insert({
    this.id = const Value.absent(),
    required String concepto,
    required double monto,
    this.frecuencia = const Value.absent(),
    this.diaCobro = const Value.absent(),
    this.notas = const Value.absent(),
    this.activo = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  }) : concepto = Value(concepto),
       monto = Value(monto);
  static Insertable<GastosFijo> custom({
    Expression<int>? id,
    Expression<String>? concepto,
    Expression<double>? monto,
    Expression<String>? frecuencia,
    Expression<int>? diaCobro,
    Expression<String>? notas,
    Expression<bool>? activo,
    Expression<DateTime>? creadoEn,
    Expression<DateTime>? actualizadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (concepto != null) 'concepto': concepto,
      if (monto != null) 'monto': monto,
      if (frecuencia != null) 'frecuencia': frecuencia,
      if (diaCobro != null) 'dia_cobro': diaCobro,
      if (notas != null) 'notas': notas,
      if (activo != null) 'activo': activo,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
    });
  }

  GastosFijosCompanion copyWith({
    Value<int>? id,
    Value<String>? concepto,
    Value<double>? monto,
    Value<String>? frecuencia,
    Value<int?>? diaCobro,
    Value<String>? notas,
    Value<bool>? activo,
    Value<DateTime>? creadoEn,
    Value<DateTime>? actualizadoEn,
  }) {
    return GastosFijosCompanion(
      id: id ?? this.id,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      frecuencia: frecuencia ?? this.frecuencia,
      diaCobro: diaCobro ?? this.diaCobro,
      notas: notas ?? this.notas,
      activo: activo ?? this.activo,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (concepto.present) {
      map['concepto'] = Variable<String>(concepto.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (frecuencia.present) {
      map['frecuencia'] = Variable<String>(frecuencia.value);
    }
    if (diaCobro.present) {
      map['dia_cobro'] = Variable<int>(diaCobro.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GastosFijosCompanion(')
          ..write('id: $id, ')
          ..write('concepto: $concepto, ')
          ..write('monto: $monto, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('diaCobro: $diaCobro, ')
          ..write('notas: $notas, ')
          ..write('activo: $activo, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }
}

class $RecordatoriosTable extends Recordatorios
    with TableInfo<$RecordatoriosTable, Recordatorio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordatoriosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
    'titulo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenciaTablaMeta = const VerificationMeta(
    'referenciaTabla',
  );
  @override
  late final GeneratedColumn<String> referenciaTabla = GeneratedColumn<String>(
    'referencia_tabla',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenciaIdMeta = const VerificationMeta(
    'referenciaId',
  );
  @override
  late final GeneratedColumn<int> referenciaId = GeneratedColumn<int>(
    'referencia_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaAlertaMeta = const VerificationMeta(
    'fechaAlerta',
  );
  @override
  late final GeneratedColumn<DateTime> fechaAlerta = GeneratedColumn<DateTime>(
    'fecha_alerta',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diasAnticipacionMeta = const VerificationMeta(
    'diasAnticipacion',
  );
  @override
  late final GeneratedColumn<int> diasAnticipacion = GeneratedColumn<int>(
    'dias_anticipacion',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _tipoNotificacionMeta = const VerificationMeta(
    'tipoNotificacion',
  );
  @override
  late final GeneratedColumn<String> tipoNotificacion = GeneratedColumn<String>(
    'tipo_notificacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sistema'),
  );
  static const VerificationMeta _repetirMeta = const VerificationMeta(
    'repetir',
  );
  @override
  late final GeneratedColumn<bool> repetir = GeneratedColumn<bool>(
    'repetir',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("repetir" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _frecuenciaAvisoMeta = const VerificationMeta(
    'frecuenciaAviso',
  );
  @override
  late final GeneratedColumn<String> frecuenciaAviso = GeneratedColumn<String>(
    'frecuencia_aviso',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unica'),
  );
  static const VerificationMeta _ultimaNotificacionMeta =
      const VerificationMeta('ultimaNotificacion');
  @override
  late final GeneratedColumn<DateTime> ultimaNotificacion =
      GeneratedColumn<DateTime>(
        'ultima_notificacion',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ultimoEnvioCorreoMeta = const VerificationMeta(
    'ultimoEnvioCorreo',
  );
  @override
  late final GeneratedColumn<DateTime> ultimoEnvioCorreo =
      GeneratedColumn<DateTime>(
        'ultimo_envio_correo',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _horaAvisoMeta = const VerificationMeta(
    'horaAviso',
  );
  @override
  late final GeneratedColumn<int> horaAviso = GeneratedColumn<int>(
    'hora_aviso',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(12),
  );
  static const VerificationMeta _minutoAvisoMeta = const VerificationMeta(
    'minutoAviso',
  );
  @override
  late final GeneratedColumn<int> minutoAviso = GeneratedColumn<int>(
    'minuto_aviso',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    titulo,
    referenciaTabla,
    referenciaId,
    fechaAlerta,
    diasAnticipacion,
    tipoNotificacion,
    repetir,
    activo,
    creadoEn,
    frecuenciaAviso,
    ultimaNotificacion,
    ultimoEnvioCorreo,
    horaAviso,
    minutoAviso,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recordatorios';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recordatorio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('titulo')) {
      context.handle(
        _tituloMeta,
        titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta),
      );
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('referencia_tabla')) {
      context.handle(
        _referenciaTablaMeta,
        referenciaTabla.isAcceptableOrUnknown(
          data['referencia_tabla']!,
          _referenciaTablaMeta,
        ),
      );
    }
    if (data.containsKey('referencia_id')) {
      context.handle(
        _referenciaIdMeta,
        referenciaId.isAcceptableOrUnknown(
          data['referencia_id']!,
          _referenciaIdMeta,
        ),
      );
    }
    if (data.containsKey('fecha_alerta')) {
      context.handle(
        _fechaAlertaMeta,
        fechaAlerta.isAcceptableOrUnknown(
          data['fecha_alerta']!,
          _fechaAlertaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaAlertaMeta);
    }
    if (data.containsKey('dias_anticipacion')) {
      context.handle(
        _diasAnticipacionMeta,
        diasAnticipacion.isAcceptableOrUnknown(
          data['dias_anticipacion']!,
          _diasAnticipacionMeta,
        ),
      );
    }
    if (data.containsKey('tipo_notificacion')) {
      context.handle(
        _tipoNotificacionMeta,
        tipoNotificacion.isAcceptableOrUnknown(
          data['tipo_notificacion']!,
          _tipoNotificacionMeta,
        ),
      );
    }
    if (data.containsKey('repetir')) {
      context.handle(
        _repetirMeta,
        repetir.isAcceptableOrUnknown(data['repetir']!, _repetirMeta),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    if (data.containsKey('frecuencia_aviso')) {
      context.handle(
        _frecuenciaAvisoMeta,
        frecuenciaAviso.isAcceptableOrUnknown(
          data['frecuencia_aviso']!,
          _frecuenciaAvisoMeta,
        ),
      );
    }
    if (data.containsKey('ultima_notificacion')) {
      context.handle(
        _ultimaNotificacionMeta,
        ultimaNotificacion.isAcceptableOrUnknown(
          data['ultima_notificacion']!,
          _ultimaNotificacionMeta,
        ),
      );
    }
    if (data.containsKey('ultimo_envio_correo')) {
      context.handle(
        _ultimoEnvioCorreoMeta,
        ultimoEnvioCorreo.isAcceptableOrUnknown(
          data['ultimo_envio_correo']!,
          _ultimoEnvioCorreoMeta,
        ),
      );
    }
    if (data.containsKey('hora_aviso')) {
      context.handle(
        _horaAvisoMeta,
        horaAviso.isAcceptableOrUnknown(data['hora_aviso']!, _horaAvisoMeta),
      );
    }
    if (data.containsKey('minuto_aviso')) {
      context.handle(
        _minutoAvisoMeta,
        minutoAviso.isAcceptableOrUnknown(
          data['minuto_aviso']!,
          _minutoAvisoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recordatorio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recordatorio(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      titulo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titulo'],
      )!,
      referenciaTabla: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referencia_tabla'],
      ),
      referenciaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}referencia_id'],
      ),
      fechaAlerta: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_alerta'],
      )!,
      diasAnticipacion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dias_anticipacion'],
      )!,
      tipoNotificacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_notificacion'],
      )!,
      repetir: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}repetir'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
      frecuenciaAviso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frecuencia_aviso'],
      )!,
      ultimaNotificacion: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultima_notificacion'],
      ),
      ultimoEnvioCorreo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultimo_envio_correo'],
      ),
      horaAviso: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hora_aviso'],
      )!,
      minutoAviso: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minuto_aviso'],
      )!,
    );
  }

  @override
  $RecordatoriosTable createAlias(String alias) {
    return $RecordatoriosTable(attachedDatabase, alias);
  }
}

class Recordatorio extends DataClass implements Insertable<Recordatorio> {
  final int id;
  final String titulo;
  final String? referenciaTabla;
  final int? referenciaId;
  final DateTime fechaAlerta;
  final int diasAnticipacion;
  final String tipoNotificacion;
  final bool repetir;
  final bool activo;
  final DateTime creadoEn;
  final String frecuenciaAviso;
  final DateTime? ultimaNotificacion;
  final DateTime? ultimoEnvioCorreo;
  final int horaAviso;
  final int minutoAviso;
  const Recordatorio({
    required this.id,
    required this.titulo,
    this.referenciaTabla,
    this.referenciaId,
    required this.fechaAlerta,
    required this.diasAnticipacion,
    required this.tipoNotificacion,
    required this.repetir,
    required this.activo,
    required this.creadoEn,
    required this.frecuenciaAviso,
    this.ultimaNotificacion,
    this.ultimoEnvioCorreo,
    required this.horaAviso,
    required this.minutoAviso,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['titulo'] = Variable<String>(titulo);
    if (!nullToAbsent || referenciaTabla != null) {
      map['referencia_tabla'] = Variable<String>(referenciaTabla);
    }
    if (!nullToAbsent || referenciaId != null) {
      map['referencia_id'] = Variable<int>(referenciaId);
    }
    map['fecha_alerta'] = Variable<DateTime>(fechaAlerta);
    map['dias_anticipacion'] = Variable<int>(diasAnticipacion);
    map['tipo_notificacion'] = Variable<String>(tipoNotificacion);
    map['repetir'] = Variable<bool>(repetir);
    map['activo'] = Variable<bool>(activo);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    map['frecuencia_aviso'] = Variable<String>(frecuenciaAviso);
    if (!nullToAbsent || ultimaNotificacion != null) {
      map['ultima_notificacion'] = Variable<DateTime>(ultimaNotificacion);
    }
    if (!nullToAbsent || ultimoEnvioCorreo != null) {
      map['ultimo_envio_correo'] = Variable<DateTime>(ultimoEnvioCorreo);
    }
    map['hora_aviso'] = Variable<int>(horaAviso);
    map['minuto_aviso'] = Variable<int>(minutoAviso);
    return map;
  }

  RecordatoriosCompanion toCompanion(bool nullToAbsent) {
    return RecordatoriosCompanion(
      id: Value(id),
      titulo: Value(titulo),
      referenciaTabla: referenciaTabla == null && nullToAbsent
          ? const Value.absent()
          : Value(referenciaTabla),
      referenciaId: referenciaId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenciaId),
      fechaAlerta: Value(fechaAlerta),
      diasAnticipacion: Value(diasAnticipacion),
      tipoNotificacion: Value(tipoNotificacion),
      repetir: Value(repetir),
      activo: Value(activo),
      creadoEn: Value(creadoEn),
      frecuenciaAviso: Value(frecuenciaAviso),
      ultimaNotificacion: ultimaNotificacion == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimaNotificacion),
      ultimoEnvioCorreo: ultimoEnvioCorreo == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoEnvioCorreo),
      horaAviso: Value(horaAviso),
      minutoAviso: Value(minutoAviso),
    );
  }

  factory Recordatorio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recordatorio(
      id: serializer.fromJson<int>(json['id']),
      titulo: serializer.fromJson<String>(json['titulo']),
      referenciaTabla: serializer.fromJson<String?>(json['referenciaTabla']),
      referenciaId: serializer.fromJson<int?>(json['referenciaId']),
      fechaAlerta: serializer.fromJson<DateTime>(json['fechaAlerta']),
      diasAnticipacion: serializer.fromJson<int>(json['diasAnticipacion']),
      tipoNotificacion: serializer.fromJson<String>(json['tipoNotificacion']),
      repetir: serializer.fromJson<bool>(json['repetir']),
      activo: serializer.fromJson<bool>(json['activo']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
      frecuenciaAviso: serializer.fromJson<String>(json['frecuenciaAviso']),
      ultimaNotificacion: serializer.fromJson<DateTime?>(
        json['ultimaNotificacion'],
      ),
      ultimoEnvioCorreo: serializer.fromJson<DateTime?>(
        json['ultimoEnvioCorreo'],
      ),
      horaAviso: serializer.fromJson<int>(json['horaAviso']),
      minutoAviso: serializer.fromJson<int>(json['minutoAviso']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'titulo': serializer.toJson<String>(titulo),
      'referenciaTabla': serializer.toJson<String?>(referenciaTabla),
      'referenciaId': serializer.toJson<int?>(referenciaId),
      'fechaAlerta': serializer.toJson<DateTime>(fechaAlerta),
      'diasAnticipacion': serializer.toJson<int>(diasAnticipacion),
      'tipoNotificacion': serializer.toJson<String>(tipoNotificacion),
      'repetir': serializer.toJson<bool>(repetir),
      'activo': serializer.toJson<bool>(activo),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
      'frecuenciaAviso': serializer.toJson<String>(frecuenciaAviso),
      'ultimaNotificacion': serializer.toJson<DateTime?>(ultimaNotificacion),
      'ultimoEnvioCorreo': serializer.toJson<DateTime?>(ultimoEnvioCorreo),
      'horaAviso': serializer.toJson<int>(horaAviso),
      'minutoAviso': serializer.toJson<int>(minutoAviso),
    };
  }

  Recordatorio copyWith({
    int? id,
    String? titulo,
    Value<String?> referenciaTabla = const Value.absent(),
    Value<int?> referenciaId = const Value.absent(),
    DateTime? fechaAlerta,
    int? diasAnticipacion,
    String? tipoNotificacion,
    bool? repetir,
    bool? activo,
    DateTime? creadoEn,
    String? frecuenciaAviso,
    Value<DateTime?> ultimaNotificacion = const Value.absent(),
    Value<DateTime?> ultimoEnvioCorreo = const Value.absent(),
    int? horaAviso,
    int? minutoAviso,
  }) => Recordatorio(
    id: id ?? this.id,
    titulo: titulo ?? this.titulo,
    referenciaTabla: referenciaTabla.present
        ? referenciaTabla.value
        : this.referenciaTabla,
    referenciaId: referenciaId.present ? referenciaId.value : this.referenciaId,
    fechaAlerta: fechaAlerta ?? this.fechaAlerta,
    diasAnticipacion: diasAnticipacion ?? this.diasAnticipacion,
    tipoNotificacion: tipoNotificacion ?? this.tipoNotificacion,
    repetir: repetir ?? this.repetir,
    activo: activo ?? this.activo,
    creadoEn: creadoEn ?? this.creadoEn,
    frecuenciaAviso: frecuenciaAviso ?? this.frecuenciaAviso,
    ultimaNotificacion: ultimaNotificacion.present
        ? ultimaNotificacion.value
        : this.ultimaNotificacion,
    ultimoEnvioCorreo: ultimoEnvioCorreo.present
        ? ultimoEnvioCorreo.value
        : this.ultimoEnvioCorreo,
    horaAviso: horaAviso ?? this.horaAviso,
    minutoAviso: minutoAviso ?? this.minutoAviso,
  );
  Recordatorio copyWithCompanion(RecordatoriosCompanion data) {
    return Recordatorio(
      id: data.id.present ? data.id.value : this.id,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      referenciaTabla: data.referenciaTabla.present
          ? data.referenciaTabla.value
          : this.referenciaTabla,
      referenciaId: data.referenciaId.present
          ? data.referenciaId.value
          : this.referenciaId,
      fechaAlerta: data.fechaAlerta.present
          ? data.fechaAlerta.value
          : this.fechaAlerta,
      diasAnticipacion: data.diasAnticipacion.present
          ? data.diasAnticipacion.value
          : this.diasAnticipacion,
      tipoNotificacion: data.tipoNotificacion.present
          ? data.tipoNotificacion.value
          : this.tipoNotificacion,
      repetir: data.repetir.present ? data.repetir.value : this.repetir,
      activo: data.activo.present ? data.activo.value : this.activo,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      frecuenciaAviso: data.frecuenciaAviso.present
          ? data.frecuenciaAviso.value
          : this.frecuenciaAviso,
      ultimaNotificacion: data.ultimaNotificacion.present
          ? data.ultimaNotificacion.value
          : this.ultimaNotificacion,
      ultimoEnvioCorreo: data.ultimoEnvioCorreo.present
          ? data.ultimoEnvioCorreo.value
          : this.ultimoEnvioCorreo,
      horaAviso: data.horaAviso.present ? data.horaAviso.value : this.horaAviso,
      minutoAviso: data.minutoAviso.present
          ? data.minutoAviso.value
          : this.minutoAviso,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recordatorio(')
          ..write('id: $id, ')
          ..write('titulo: $titulo, ')
          ..write('referenciaTabla: $referenciaTabla, ')
          ..write('referenciaId: $referenciaId, ')
          ..write('fechaAlerta: $fechaAlerta, ')
          ..write('diasAnticipacion: $diasAnticipacion, ')
          ..write('tipoNotificacion: $tipoNotificacion, ')
          ..write('repetir: $repetir, ')
          ..write('activo: $activo, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('frecuenciaAviso: $frecuenciaAviso, ')
          ..write('ultimaNotificacion: $ultimaNotificacion, ')
          ..write('ultimoEnvioCorreo: $ultimoEnvioCorreo, ')
          ..write('horaAviso: $horaAviso, ')
          ..write('minutoAviso: $minutoAviso')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    titulo,
    referenciaTabla,
    referenciaId,
    fechaAlerta,
    diasAnticipacion,
    tipoNotificacion,
    repetir,
    activo,
    creadoEn,
    frecuenciaAviso,
    ultimaNotificacion,
    ultimoEnvioCorreo,
    horaAviso,
    minutoAviso,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recordatorio &&
          other.id == this.id &&
          other.titulo == this.titulo &&
          other.referenciaTabla == this.referenciaTabla &&
          other.referenciaId == this.referenciaId &&
          other.fechaAlerta == this.fechaAlerta &&
          other.diasAnticipacion == this.diasAnticipacion &&
          other.tipoNotificacion == this.tipoNotificacion &&
          other.repetir == this.repetir &&
          other.activo == this.activo &&
          other.creadoEn == this.creadoEn &&
          other.frecuenciaAviso == this.frecuenciaAviso &&
          other.ultimaNotificacion == this.ultimaNotificacion &&
          other.ultimoEnvioCorreo == this.ultimoEnvioCorreo &&
          other.horaAviso == this.horaAviso &&
          other.minutoAviso == this.minutoAviso);
}

class RecordatoriosCompanion extends UpdateCompanion<Recordatorio> {
  final Value<int> id;
  final Value<String> titulo;
  final Value<String?> referenciaTabla;
  final Value<int?> referenciaId;
  final Value<DateTime> fechaAlerta;
  final Value<int> diasAnticipacion;
  final Value<String> tipoNotificacion;
  final Value<bool> repetir;
  final Value<bool> activo;
  final Value<DateTime> creadoEn;
  final Value<String> frecuenciaAviso;
  final Value<DateTime?> ultimaNotificacion;
  final Value<DateTime?> ultimoEnvioCorreo;
  final Value<int> horaAviso;
  final Value<int> minutoAviso;
  const RecordatoriosCompanion({
    this.id = const Value.absent(),
    this.titulo = const Value.absent(),
    this.referenciaTabla = const Value.absent(),
    this.referenciaId = const Value.absent(),
    this.fechaAlerta = const Value.absent(),
    this.diasAnticipacion = const Value.absent(),
    this.tipoNotificacion = const Value.absent(),
    this.repetir = const Value.absent(),
    this.activo = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.frecuenciaAviso = const Value.absent(),
    this.ultimaNotificacion = const Value.absent(),
    this.ultimoEnvioCorreo = const Value.absent(),
    this.horaAviso = const Value.absent(),
    this.minutoAviso = const Value.absent(),
  });
  RecordatoriosCompanion.insert({
    this.id = const Value.absent(),
    required String titulo,
    this.referenciaTabla = const Value.absent(),
    this.referenciaId = const Value.absent(),
    required DateTime fechaAlerta,
    this.diasAnticipacion = const Value.absent(),
    this.tipoNotificacion = const Value.absent(),
    this.repetir = const Value.absent(),
    this.activo = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.frecuenciaAviso = const Value.absent(),
    this.ultimaNotificacion = const Value.absent(),
    this.ultimoEnvioCorreo = const Value.absent(),
    this.horaAviso = const Value.absent(),
    this.minutoAviso = const Value.absent(),
  }) : titulo = Value(titulo),
       fechaAlerta = Value(fechaAlerta);
  static Insertable<Recordatorio> custom({
    Expression<int>? id,
    Expression<String>? titulo,
    Expression<String>? referenciaTabla,
    Expression<int>? referenciaId,
    Expression<DateTime>? fechaAlerta,
    Expression<int>? diasAnticipacion,
    Expression<String>? tipoNotificacion,
    Expression<bool>? repetir,
    Expression<bool>? activo,
    Expression<DateTime>? creadoEn,
    Expression<String>? frecuenciaAviso,
    Expression<DateTime>? ultimaNotificacion,
    Expression<DateTime>? ultimoEnvioCorreo,
    Expression<int>? horaAviso,
    Expression<int>? minutoAviso,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titulo != null) 'titulo': titulo,
      if (referenciaTabla != null) 'referencia_tabla': referenciaTabla,
      if (referenciaId != null) 'referencia_id': referenciaId,
      if (fechaAlerta != null) 'fecha_alerta': fechaAlerta,
      if (diasAnticipacion != null) 'dias_anticipacion': diasAnticipacion,
      if (tipoNotificacion != null) 'tipo_notificacion': tipoNotificacion,
      if (repetir != null) 'repetir': repetir,
      if (activo != null) 'activo': activo,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (frecuenciaAviso != null) 'frecuencia_aviso': frecuenciaAviso,
      if (ultimaNotificacion != null) 'ultima_notificacion': ultimaNotificacion,
      if (ultimoEnvioCorreo != null) 'ultimo_envio_correo': ultimoEnvioCorreo,
      if (horaAviso != null) 'hora_aviso': horaAviso,
      if (minutoAviso != null) 'minuto_aviso': minutoAviso,
    });
  }

  RecordatoriosCompanion copyWith({
    Value<int>? id,
    Value<String>? titulo,
    Value<String?>? referenciaTabla,
    Value<int?>? referenciaId,
    Value<DateTime>? fechaAlerta,
    Value<int>? diasAnticipacion,
    Value<String>? tipoNotificacion,
    Value<bool>? repetir,
    Value<bool>? activo,
    Value<DateTime>? creadoEn,
    Value<String>? frecuenciaAviso,
    Value<DateTime?>? ultimaNotificacion,
    Value<DateTime?>? ultimoEnvioCorreo,
    Value<int>? horaAviso,
    Value<int>? minutoAviso,
  }) {
    return RecordatoriosCompanion(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      referenciaTabla: referenciaTabla ?? this.referenciaTabla,
      referenciaId: referenciaId ?? this.referenciaId,
      fechaAlerta: fechaAlerta ?? this.fechaAlerta,
      diasAnticipacion: diasAnticipacion ?? this.diasAnticipacion,
      tipoNotificacion: tipoNotificacion ?? this.tipoNotificacion,
      repetir: repetir ?? this.repetir,
      activo: activo ?? this.activo,
      creadoEn: creadoEn ?? this.creadoEn,
      frecuenciaAviso: frecuenciaAviso ?? this.frecuenciaAviso,
      ultimaNotificacion: ultimaNotificacion ?? this.ultimaNotificacion,
      ultimoEnvioCorreo: ultimoEnvioCorreo ?? this.ultimoEnvioCorreo,
      horaAviso: horaAviso ?? this.horaAviso,
      minutoAviso: minutoAviso ?? this.minutoAviso,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (referenciaTabla.present) {
      map['referencia_tabla'] = Variable<String>(referenciaTabla.value);
    }
    if (referenciaId.present) {
      map['referencia_id'] = Variable<int>(referenciaId.value);
    }
    if (fechaAlerta.present) {
      map['fecha_alerta'] = Variable<DateTime>(fechaAlerta.value);
    }
    if (diasAnticipacion.present) {
      map['dias_anticipacion'] = Variable<int>(diasAnticipacion.value);
    }
    if (tipoNotificacion.present) {
      map['tipo_notificacion'] = Variable<String>(tipoNotificacion.value);
    }
    if (repetir.present) {
      map['repetir'] = Variable<bool>(repetir.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (frecuenciaAviso.present) {
      map['frecuencia_aviso'] = Variable<String>(frecuenciaAviso.value);
    }
    if (ultimaNotificacion.present) {
      map['ultima_notificacion'] = Variable<DateTime>(ultimaNotificacion.value);
    }
    if (ultimoEnvioCorreo.present) {
      map['ultimo_envio_correo'] = Variable<DateTime>(ultimoEnvioCorreo.value);
    }
    if (horaAviso.present) {
      map['hora_aviso'] = Variable<int>(horaAviso.value);
    }
    if (minutoAviso.present) {
      map['minuto_aviso'] = Variable<int>(minutoAviso.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordatoriosCompanion(')
          ..write('id: $id, ')
          ..write('titulo: $titulo, ')
          ..write('referenciaTabla: $referenciaTabla, ')
          ..write('referenciaId: $referenciaId, ')
          ..write('fechaAlerta: $fechaAlerta, ')
          ..write('diasAnticipacion: $diasAnticipacion, ')
          ..write('tipoNotificacion: $tipoNotificacion, ')
          ..write('repetir: $repetir, ')
          ..write('activo: $activo, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('frecuenciaAviso: $frecuenciaAviso, ')
          ..write('ultimaNotificacion: $ultimaNotificacion, ')
          ..write('ultimoEnvioCorreo: $ultimoEnvioCorreo, ')
          ..write('horaAviso: $horaAviso, ')
          ..write('minutoAviso: $minutoAviso')
          ..write(')'))
        .toString();
  }
}

class $ConfigSmtpsTable extends ConfigSmtps
    with TableInfo<$ConfigSmtpsTable, ConfigSmtp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigSmtpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _servidorMeta = const VerificationMeta(
    'servidor',
  );
  @override
  late final GeneratedColumn<String> servidor = GeneratedColumn<String>(
    'servidor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _puertoMeta = const VerificationMeta('puerto');
  @override
  late final GeneratedColumn<int> puerto = GeneratedColumn<int>(
    'puerto',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(587),
  );
  static const VerificationMeta _usuarioMeta = const VerificationMeta(
    'usuario',
  );
  @override
  late final GeneratedColumn<String> usuario = GeneratedColumn<String>(
    'usuario',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contrasenaEncriptadaMeta =
      const VerificationMeta('contrasenaEncriptada');
  @override
  late final GeneratedColumn<String> contrasenaEncriptada =
      GeneratedColumn<String>(
        'contrasena_encriptada',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tieneContrasenaMeta = const VerificationMeta(
    'tieneContrasena',
  );
  @override
  late final GeneratedColumn<bool> tieneContrasena = GeneratedColumn<bool>(
    'tiene_contrasena',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tiene_contrasena" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _correoDestinoMeta = const VerificationMeta(
    'correoDestino',
  );
  @override
  late final GeneratedColumn<String> correoDestino = GeneratedColumn<String>(
    'correo_destino',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nombreRemitenteMeta = const VerificationMeta(
    'nombreRemitente',
  );
  @override
  late final GeneratedColumn<String> nombreRemitente = GeneratedColumn<String>(
    'nombre_remitente',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Valtiq'),
  );
  static const VerificationMeta _sslMeta = const VerificationMeta('ssl');
  @override
  late final GeneratedColumn<bool> ssl = GeneratedColumn<bool>(
    'ssl',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ssl" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _habilitadoMeta = const VerificationMeta(
    'habilitado',
  );
  @override
  late final GeneratedColumn<bool> habilitado = GeneratedColumn<bool>(
    'habilitado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("habilitado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    servidor,
    puerto,
    usuario,
    contrasenaEncriptada,
    tieneContrasena,
    correoDestino,
    nombreRemitente,
    ssl,
    habilitado,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'config_smtps';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigSmtp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('servidor')) {
      context.handle(
        _servidorMeta,
        servidor.isAcceptableOrUnknown(data['servidor']!, _servidorMeta),
      );
    }
    if (data.containsKey('puerto')) {
      context.handle(
        _puertoMeta,
        puerto.isAcceptableOrUnknown(data['puerto']!, _puertoMeta),
      );
    }
    if (data.containsKey('usuario')) {
      context.handle(
        _usuarioMeta,
        usuario.isAcceptableOrUnknown(data['usuario']!, _usuarioMeta),
      );
    }
    if (data.containsKey('contrasena_encriptada')) {
      context.handle(
        _contrasenaEncriptadaMeta,
        contrasenaEncriptada.isAcceptableOrUnknown(
          data['contrasena_encriptada']!,
          _contrasenaEncriptadaMeta,
        ),
      );
    }
    if (data.containsKey('tiene_contrasena')) {
      context.handle(
        _tieneContrasenaMeta,
        tieneContrasena.isAcceptableOrUnknown(
          data['tiene_contrasena']!,
          _tieneContrasenaMeta,
        ),
      );
    }
    if (data.containsKey('correo_destino')) {
      context.handle(
        _correoDestinoMeta,
        correoDestino.isAcceptableOrUnknown(
          data['correo_destino']!,
          _correoDestinoMeta,
        ),
      );
    }
    if (data.containsKey('nombre_remitente')) {
      context.handle(
        _nombreRemitenteMeta,
        nombreRemitente.isAcceptableOrUnknown(
          data['nombre_remitente']!,
          _nombreRemitenteMeta,
        ),
      );
    }
    if (data.containsKey('ssl')) {
      context.handle(
        _sslMeta,
        ssl.isAcceptableOrUnknown(data['ssl']!, _sslMeta),
      );
    }
    if (data.containsKey('habilitado')) {
      context.handle(
        _habilitadoMeta,
        habilitado.isAcceptableOrUnknown(data['habilitado']!, _habilitadoMeta),
      );
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfigSmtp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigSmtp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      servidor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}servidor'],
      )!,
      puerto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}puerto'],
      )!,
      usuario: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario'],
      )!,
      contrasenaEncriptada: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contrasena_encriptada'],
      ),
      tieneContrasena: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tiene_contrasena'],
      )!,
      correoDestino: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correo_destino'],
      )!,
      nombreRemitente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_remitente'],
      )!,
      ssl: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ssl'],
      )!,
      habilitado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}habilitado'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      )!,
    );
  }

  @override
  $ConfigSmtpsTable createAlias(String alias) {
    return $ConfigSmtpsTable(attachedDatabase, alias);
  }
}

class ConfigSmtp extends DataClass implements Insertable<ConfigSmtp> {
  final int id;
  final String servidor;
  final int puerto;
  final String usuario;
  final String? contrasenaEncriptada;
  final bool tieneContrasena;
  final String correoDestino;
  final String nombreRemitente;
  final bool ssl;
  final bool habilitado;
  final DateTime actualizadoEn;
  const ConfigSmtp({
    required this.id,
    required this.servidor,
    required this.puerto,
    required this.usuario,
    this.contrasenaEncriptada,
    required this.tieneContrasena,
    required this.correoDestino,
    required this.nombreRemitente,
    required this.ssl,
    required this.habilitado,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['servidor'] = Variable<String>(servidor);
    map['puerto'] = Variable<int>(puerto);
    map['usuario'] = Variable<String>(usuario);
    if (!nullToAbsent || contrasenaEncriptada != null) {
      map['contrasena_encriptada'] = Variable<String>(contrasenaEncriptada);
    }
    map['tiene_contrasena'] = Variable<bool>(tieneContrasena);
    map['correo_destino'] = Variable<String>(correoDestino);
    map['nombre_remitente'] = Variable<String>(nombreRemitente);
    map['ssl'] = Variable<bool>(ssl);
    map['habilitado'] = Variable<bool>(habilitado);
    map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    return map;
  }

  ConfigSmtpsCompanion toCompanion(bool nullToAbsent) {
    return ConfigSmtpsCompanion(
      id: Value(id),
      servidor: Value(servidor),
      puerto: Value(puerto),
      usuario: Value(usuario),
      contrasenaEncriptada: contrasenaEncriptada == null && nullToAbsent
          ? const Value.absent()
          : Value(contrasenaEncriptada),
      tieneContrasena: Value(tieneContrasena),
      correoDestino: Value(correoDestino),
      nombreRemitente: Value(nombreRemitente),
      ssl: Value(ssl),
      habilitado: Value(habilitado),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory ConfigSmtp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigSmtp(
      id: serializer.fromJson<int>(json['id']),
      servidor: serializer.fromJson<String>(json['servidor']),
      puerto: serializer.fromJson<int>(json['puerto']),
      usuario: serializer.fromJson<String>(json['usuario']),
      contrasenaEncriptada: serializer.fromJson<String?>(
        json['contrasenaEncriptada'],
      ),
      tieneContrasena: serializer.fromJson<bool>(json['tieneContrasena']),
      correoDestino: serializer.fromJson<String>(json['correoDestino']),
      nombreRemitente: serializer.fromJson<String>(json['nombreRemitente']),
      ssl: serializer.fromJson<bool>(json['ssl']),
      habilitado: serializer.fromJson<bool>(json['habilitado']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'servidor': serializer.toJson<String>(servidor),
      'puerto': serializer.toJson<int>(puerto),
      'usuario': serializer.toJson<String>(usuario),
      'contrasenaEncriptada': serializer.toJson<String?>(contrasenaEncriptada),
      'tieneContrasena': serializer.toJson<bool>(tieneContrasena),
      'correoDestino': serializer.toJson<String>(correoDestino),
      'nombreRemitente': serializer.toJson<String>(nombreRemitente),
      'ssl': serializer.toJson<bool>(ssl),
      'habilitado': serializer.toJson<bool>(habilitado),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
    };
  }

  ConfigSmtp copyWith({
    int? id,
    String? servidor,
    int? puerto,
    String? usuario,
    Value<String?> contrasenaEncriptada = const Value.absent(),
    bool? tieneContrasena,
    String? correoDestino,
    String? nombreRemitente,
    bool? ssl,
    bool? habilitado,
    DateTime? actualizadoEn,
  }) => ConfigSmtp(
    id: id ?? this.id,
    servidor: servidor ?? this.servidor,
    puerto: puerto ?? this.puerto,
    usuario: usuario ?? this.usuario,
    contrasenaEncriptada: contrasenaEncriptada.present
        ? contrasenaEncriptada.value
        : this.contrasenaEncriptada,
    tieneContrasena: tieneContrasena ?? this.tieneContrasena,
    correoDestino: correoDestino ?? this.correoDestino,
    nombreRemitente: nombreRemitente ?? this.nombreRemitente,
    ssl: ssl ?? this.ssl,
    habilitado: habilitado ?? this.habilitado,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  ConfigSmtp copyWithCompanion(ConfigSmtpsCompanion data) {
    return ConfigSmtp(
      id: data.id.present ? data.id.value : this.id,
      servidor: data.servidor.present ? data.servidor.value : this.servidor,
      puerto: data.puerto.present ? data.puerto.value : this.puerto,
      usuario: data.usuario.present ? data.usuario.value : this.usuario,
      contrasenaEncriptada: data.contrasenaEncriptada.present
          ? data.contrasenaEncriptada.value
          : this.contrasenaEncriptada,
      tieneContrasena: data.tieneContrasena.present
          ? data.tieneContrasena.value
          : this.tieneContrasena,
      correoDestino: data.correoDestino.present
          ? data.correoDestino.value
          : this.correoDestino,
      nombreRemitente: data.nombreRemitente.present
          ? data.nombreRemitente.value
          : this.nombreRemitente,
      ssl: data.ssl.present ? data.ssl.value : this.ssl,
      habilitado: data.habilitado.present
          ? data.habilitado.value
          : this.habilitado,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigSmtp(')
          ..write('id: $id, ')
          ..write('servidor: $servidor, ')
          ..write('puerto: $puerto, ')
          ..write('usuario: $usuario, ')
          ..write('contrasenaEncriptada: $contrasenaEncriptada, ')
          ..write('tieneContrasena: $tieneContrasena, ')
          ..write('correoDestino: $correoDestino, ')
          ..write('nombreRemitente: $nombreRemitente, ')
          ..write('ssl: $ssl, ')
          ..write('habilitado: $habilitado, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    servidor,
    puerto,
    usuario,
    contrasenaEncriptada,
    tieneContrasena,
    correoDestino,
    nombreRemitente,
    ssl,
    habilitado,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigSmtp &&
          other.id == this.id &&
          other.servidor == this.servidor &&
          other.puerto == this.puerto &&
          other.usuario == this.usuario &&
          other.contrasenaEncriptada == this.contrasenaEncriptada &&
          other.tieneContrasena == this.tieneContrasena &&
          other.correoDestino == this.correoDestino &&
          other.nombreRemitente == this.nombreRemitente &&
          other.ssl == this.ssl &&
          other.habilitado == this.habilitado &&
          other.actualizadoEn == this.actualizadoEn);
}

class ConfigSmtpsCompanion extends UpdateCompanion<ConfigSmtp> {
  final Value<int> id;
  final Value<String> servidor;
  final Value<int> puerto;
  final Value<String> usuario;
  final Value<String?> contrasenaEncriptada;
  final Value<bool> tieneContrasena;
  final Value<String> correoDestino;
  final Value<String> nombreRemitente;
  final Value<bool> ssl;
  final Value<bool> habilitado;
  final Value<DateTime> actualizadoEn;
  const ConfigSmtpsCompanion({
    this.id = const Value.absent(),
    this.servidor = const Value.absent(),
    this.puerto = const Value.absent(),
    this.usuario = const Value.absent(),
    this.contrasenaEncriptada = const Value.absent(),
    this.tieneContrasena = const Value.absent(),
    this.correoDestino = const Value.absent(),
    this.nombreRemitente = const Value.absent(),
    this.ssl = const Value.absent(),
    this.habilitado = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  });
  ConfigSmtpsCompanion.insert({
    this.id = const Value.absent(),
    this.servidor = const Value.absent(),
    this.puerto = const Value.absent(),
    this.usuario = const Value.absent(),
    this.contrasenaEncriptada = const Value.absent(),
    this.tieneContrasena = const Value.absent(),
    this.correoDestino = const Value.absent(),
    this.nombreRemitente = const Value.absent(),
    this.ssl = const Value.absent(),
    this.habilitado = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  });
  static Insertable<ConfigSmtp> custom({
    Expression<int>? id,
    Expression<String>? servidor,
    Expression<int>? puerto,
    Expression<String>? usuario,
    Expression<String>? contrasenaEncriptada,
    Expression<bool>? tieneContrasena,
    Expression<String>? correoDestino,
    Expression<String>? nombreRemitente,
    Expression<bool>? ssl,
    Expression<bool>? habilitado,
    Expression<DateTime>? actualizadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (servidor != null) 'servidor': servidor,
      if (puerto != null) 'puerto': puerto,
      if (usuario != null) 'usuario': usuario,
      if (contrasenaEncriptada != null)
        'contrasena_encriptada': contrasenaEncriptada,
      if (tieneContrasena != null) 'tiene_contrasena': tieneContrasena,
      if (correoDestino != null) 'correo_destino': correoDestino,
      if (nombreRemitente != null) 'nombre_remitente': nombreRemitente,
      if (ssl != null) 'ssl': ssl,
      if (habilitado != null) 'habilitado': habilitado,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
    });
  }

  ConfigSmtpsCompanion copyWith({
    Value<int>? id,
    Value<String>? servidor,
    Value<int>? puerto,
    Value<String>? usuario,
    Value<String?>? contrasenaEncriptada,
    Value<bool>? tieneContrasena,
    Value<String>? correoDestino,
    Value<String>? nombreRemitente,
    Value<bool>? ssl,
    Value<bool>? habilitado,
    Value<DateTime>? actualizadoEn,
  }) {
    return ConfigSmtpsCompanion(
      id: id ?? this.id,
      servidor: servidor ?? this.servidor,
      puerto: puerto ?? this.puerto,
      usuario: usuario ?? this.usuario,
      contrasenaEncriptada: contrasenaEncriptada ?? this.contrasenaEncriptada,
      tieneContrasena: tieneContrasena ?? this.tieneContrasena,
      correoDestino: correoDestino ?? this.correoDestino,
      nombreRemitente: nombreRemitente ?? this.nombreRemitente,
      ssl: ssl ?? this.ssl,
      habilitado: habilitado ?? this.habilitado,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (servidor.present) {
      map['servidor'] = Variable<String>(servidor.value);
    }
    if (puerto.present) {
      map['puerto'] = Variable<int>(puerto.value);
    }
    if (usuario.present) {
      map['usuario'] = Variable<String>(usuario.value);
    }
    if (contrasenaEncriptada.present) {
      map['contrasena_encriptada'] = Variable<String>(
        contrasenaEncriptada.value,
      );
    }
    if (tieneContrasena.present) {
      map['tiene_contrasena'] = Variable<bool>(tieneContrasena.value);
    }
    if (correoDestino.present) {
      map['correo_destino'] = Variable<String>(correoDestino.value);
    }
    if (nombreRemitente.present) {
      map['nombre_remitente'] = Variable<String>(nombreRemitente.value);
    }
    if (ssl.present) {
      map['ssl'] = Variable<bool>(ssl.value);
    }
    if (habilitado.present) {
      map['habilitado'] = Variable<bool>(habilitado.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigSmtpsCompanion(')
          ..write('id: $id, ')
          ..write('servidor: $servidor, ')
          ..write('puerto: $puerto, ')
          ..write('usuario: $usuario, ')
          ..write('contrasenaEncriptada: $contrasenaEncriptada, ')
          ..write('tieneContrasena: $tieneContrasena, ')
          ..write('correoDestino: $correoDestino, ')
          ..write('nombreRemitente: $nombreRemitente, ')
          ..write('ssl: $ssl, ')
          ..write('habilitado: $habilitado, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }
}

class $GastosVariablesTable extends GastosVariables
    with TableInfo<$GastosVariablesTable, GastosVariable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GastosVariablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    descripcion,
    monto,
    categoria,
    fecha,
    notas,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gastos_variables';
  @override
  VerificationContext validateIntegrity(
    Insertable<GastosVariable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GastosVariable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GastosVariable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $GastosVariablesTable createAlias(String alias) {
    return $GastosVariablesTable(attachedDatabase, alias);
  }
}

class GastosVariable extends DataClass implements Insertable<GastosVariable> {
  final int id;
  final String descripcion;
  final double monto;
  final String categoria;
  final DateTime fecha;
  final String? notas;
  final DateTime creadoEn;
  const GastosVariable({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.categoria,
    required this.fecha,
    this.notas,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['descripcion'] = Variable<String>(descripcion);
    map['monto'] = Variable<double>(monto);
    map['categoria'] = Variable<String>(categoria);
    map['fecha'] = Variable<DateTime>(fecha);
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  GastosVariablesCompanion toCompanion(bool nullToAbsent) {
    return GastosVariablesCompanion(
      id: Value(id),
      descripcion: Value(descripcion),
      monto: Value(monto),
      categoria: Value(categoria),
      fecha: Value(fecha),
      notas: notas == null && nullToAbsent
          ? const Value.absent()
          : Value(notas),
      creadoEn: Value(creadoEn),
    );
  }

  factory GastosVariable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GastosVariable(
      id: serializer.fromJson<int>(json['id']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      monto: serializer.fromJson<double>(json['monto']),
      categoria: serializer.fromJson<String>(json['categoria']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      notas: serializer.fromJson<String?>(json['notas']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'descripcion': serializer.toJson<String>(descripcion),
      'monto': serializer.toJson<double>(monto),
      'categoria': serializer.toJson<String>(categoria),
      'fecha': serializer.toJson<DateTime>(fecha),
      'notas': serializer.toJson<String?>(notas),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  GastosVariable copyWith({
    int? id,
    String? descripcion,
    double? monto,
    String? categoria,
    DateTime? fecha,
    Value<String?> notas = const Value.absent(),
    DateTime? creadoEn,
  }) => GastosVariable(
    id: id ?? this.id,
    descripcion: descripcion ?? this.descripcion,
    monto: monto ?? this.monto,
    categoria: categoria ?? this.categoria,
    fecha: fecha ?? this.fecha,
    notas: notas.present ? notas.value : this.notas,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  GastosVariable copyWithCompanion(GastosVariablesCompanion data) {
    return GastosVariable(
      id: data.id.present ? data.id.value : this.id,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      monto: data.monto.present ? data.monto.value : this.monto,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      notas: data.notas.present ? data.notas.value : this.notas,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GastosVariable(')
          ..write('id: $id, ')
          ..write('descripcion: $descripcion, ')
          ..write('monto: $monto, ')
          ..write('categoria: $categoria, ')
          ..write('fecha: $fecha, ')
          ..write('notas: $notas, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, descripcion, monto, categoria, fecha, notas, creadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GastosVariable &&
          other.id == this.id &&
          other.descripcion == this.descripcion &&
          other.monto == this.monto &&
          other.categoria == this.categoria &&
          other.fecha == this.fecha &&
          other.notas == this.notas &&
          other.creadoEn == this.creadoEn);
}

class GastosVariablesCompanion extends UpdateCompanion<GastosVariable> {
  final Value<int> id;
  final Value<String> descripcion;
  final Value<double> monto;
  final Value<String> categoria;
  final Value<DateTime> fecha;
  final Value<String?> notas;
  final Value<DateTime> creadoEn;
  const GastosVariablesCompanion({
    this.id = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.monto = const Value.absent(),
    this.categoria = const Value.absent(),
    this.fecha = const Value.absent(),
    this.notas = const Value.absent(),
    this.creadoEn = const Value.absent(),
  });
  GastosVariablesCompanion.insert({
    this.id = const Value.absent(),
    required String descripcion,
    required double monto,
    required String categoria,
    required DateTime fecha,
    this.notas = const Value.absent(),
    this.creadoEn = const Value.absent(),
  }) : descripcion = Value(descripcion),
       monto = Value(monto),
       categoria = Value(categoria),
       fecha = Value(fecha);
  static Insertable<GastosVariable> custom({
    Expression<int>? id,
    Expression<String>? descripcion,
    Expression<double>? monto,
    Expression<String>? categoria,
    Expression<DateTime>? fecha,
    Expression<String>? notas,
    Expression<DateTime>? creadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (descripcion != null) 'descripcion': descripcion,
      if (monto != null) 'monto': monto,
      if (categoria != null) 'categoria': categoria,
      if (fecha != null) 'fecha': fecha,
      if (notas != null) 'notas': notas,
      if (creadoEn != null) 'creado_en': creadoEn,
    });
  }

  GastosVariablesCompanion copyWith({
    Value<int>? id,
    Value<String>? descripcion,
    Value<double>? monto,
    Value<String>? categoria,
    Value<DateTime>? fecha,
    Value<String?>? notas,
    Value<DateTime>? creadoEn,
  }) {
    return GastosVariablesCompanion(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GastosVariablesCompanion(')
          ..write('id: $id, ')
          ..write('descripcion: $descripcion, ')
          ..write('monto: $monto, ')
          ..write('categoria: $categoria, ')
          ..write('fecha: $fecha, ')
          ..write('notas: $notas, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }
}

class $PresupuestosCategoriasTable extends PresupuestosCategorias
    with TableInfo<$PresupuestosCategoriasTable, PresupuestosCategoria> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresupuestosCategoriasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limiteMensualMeta = const VerificationMeta(
    'limiteMensual',
  );
  @override
  late final GeneratedColumn<double> limiteMensual = GeneratedColumn<double>(
    'limite_mensual',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoria,
    limiteMensual,
    creadoEn,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'presupuestos_categorias';
  @override
  VerificationContext validateIntegrity(
    Insertable<PresupuestosCategoria> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('limite_mensual')) {
      context.handle(
        _limiteMensualMeta,
        limiteMensual.isAcceptableOrUnknown(
          data['limite_mensual']!,
          _limiteMensualMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limiteMensualMeta);
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {categoria},
  ];
  @override
  PresupuestosCategoria map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresupuestosCategoria(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      )!,
      limiteMensual: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}limite_mensual'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      )!,
    );
  }

  @override
  $PresupuestosCategoriasTable createAlias(String alias) {
    return $PresupuestosCategoriasTable(attachedDatabase, alias);
  }
}

class PresupuestosCategoria extends DataClass
    implements Insertable<PresupuestosCategoria> {
  final int id;
  final String categoria;
  final double limiteMensual;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  const PresupuestosCategoria({
    required this.id,
    required this.categoria,
    required this.limiteMensual,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['categoria'] = Variable<String>(categoria);
    map['limite_mensual'] = Variable<double>(limiteMensual);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    return map;
  }

  PresupuestosCategoriasCompanion toCompanion(bool nullToAbsent) {
    return PresupuestosCategoriasCompanion(
      id: Value(id),
      categoria: Value(categoria),
      limiteMensual: Value(limiteMensual),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory PresupuestosCategoria.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresupuestosCategoria(
      id: serializer.fromJson<int>(json['id']),
      categoria: serializer.fromJson<String>(json['categoria']),
      limiteMensual: serializer.fromJson<double>(json['limiteMensual']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoria': serializer.toJson<String>(categoria),
      'limiteMensual': serializer.toJson<double>(limiteMensual),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
    };
  }

  PresupuestosCategoria copyWith({
    int? id,
    String? categoria,
    double? limiteMensual,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) => PresupuestosCategoria(
    id: id ?? this.id,
    categoria: categoria ?? this.categoria,
    limiteMensual: limiteMensual ?? this.limiteMensual,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  PresupuestosCategoria copyWithCompanion(
    PresupuestosCategoriasCompanion data,
  ) {
    return PresupuestosCategoria(
      id: data.id.present ? data.id.value : this.id,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      limiteMensual: data.limiteMensual.present
          ? data.limiteMensual.value
          : this.limiteMensual,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresupuestosCategoria(')
          ..write('id: $id, ')
          ..write('categoria: $categoria, ')
          ..write('limiteMensual: $limiteMensual, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoria, limiteMensual, creadoEn, actualizadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresupuestosCategoria &&
          other.id == this.id &&
          other.categoria == this.categoria &&
          other.limiteMensual == this.limiteMensual &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn);
}

class PresupuestosCategoriasCompanion
    extends UpdateCompanion<PresupuestosCategoria> {
  final Value<int> id;
  final Value<String> categoria;
  final Value<double> limiteMensual;
  final Value<DateTime> creadoEn;
  final Value<DateTime> actualizadoEn;
  const PresupuestosCategoriasCompanion({
    this.id = const Value.absent(),
    this.categoria = const Value.absent(),
    this.limiteMensual = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  });
  PresupuestosCategoriasCompanion.insert({
    this.id = const Value.absent(),
    required String categoria,
    required double limiteMensual,
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
  }) : categoria = Value(categoria),
       limiteMensual = Value(limiteMensual);
  static Insertable<PresupuestosCategoria> custom({
    Expression<int>? id,
    Expression<String>? categoria,
    Expression<double>? limiteMensual,
    Expression<DateTime>? creadoEn,
    Expression<DateTime>? actualizadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoria != null) 'categoria': categoria,
      if (limiteMensual != null) 'limite_mensual': limiteMensual,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
    });
  }

  PresupuestosCategoriasCompanion copyWith({
    Value<int>? id,
    Value<String>? categoria,
    Value<double>? limiteMensual,
    Value<DateTime>? creadoEn,
    Value<DateTime>? actualizadoEn,
  }) {
    return PresupuestosCategoriasCompanion(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      limiteMensual: limiteMensual ?? this.limiteMensual,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (limiteMensual.present) {
      map['limite_mensual'] = Variable<double>(limiteMensual.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresupuestosCategoriasCompanion(')
          ..write('id: $id, ')
          ..write('categoria: $categoria, ')
          ..write('limiteMensual: $limiteMensual, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DeudasTable deudas = $DeudasTable(this);
  late final $PagosDeudaTable pagosDeuda = $PagosDeudaTable(this);
  late final $PrestamosTable prestamos = $PrestamosTable(this);
  late final $PagosRecibidosTable pagosRecibidos = $PagosRecibidosTable(this);
  late final $IngresosTable ingresos = $IngresosTable(this);
  late final $GastosFijosTable gastosFijos = $GastosFijosTable(this);
  late final $RecordatoriosTable recordatorios = $RecordatoriosTable(this);
  late final $ConfigSmtpsTable configSmtps = $ConfigSmtpsTable(this);
  late final $GastosVariablesTable gastosVariables = $GastosVariablesTable(
    this,
  );
  late final $PresupuestosCategoriasTable presupuestosCategorias =
      $PresupuestosCategoriasTable(this);
  late final Index idxPagosDeudaDeudaId = Index(
    'idx_pagos_deuda_deuda_id',
    'CREATE INDEX idx_pagos_deuda_deuda_id ON pagos_deuda (deuda_id)',
  );
  late final Index idxPagosRecibidosPrestamoId = Index(
    'idx_pagos_recibidos_prestamo_id',
    'CREATE INDEX idx_pagos_recibidos_prestamo_id ON pagos_recibidos (prestamo_id)',
  );
  late final DeudasDao deudasDao = DeudasDao(this as AppDatabase);
  late final PagosDeudaDao pagosDeudaDao = PagosDeudaDao(this as AppDatabase);
  late final PrestamosDao prestamosDao = PrestamosDao(this as AppDatabase);
  late final IngresosDao ingresosDao = IngresosDao(this as AppDatabase);
  late final GastosFijosDao gastosFijosDao = GastosFijosDao(
    this as AppDatabase,
  );
  late final RecordatoriosDao recordatoriosDao = RecordatoriosDao(
    this as AppDatabase,
  );
  late final ConfigSmtpDao configSmtpDao = ConfigSmtpDao(this as AppDatabase);
  late final GastosVariablesDao gastosVariablesDao = GastosVariablesDao(
    this as AppDatabase,
  );
  late final PresupuestosCategoriasDao presupuestosCategoriasDao =
      PresupuestosCategoriasDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    deudas,
    pagosDeuda,
    prestamos,
    pagosRecibidos,
    ingresos,
    gastosFijos,
    recordatorios,
    configSmtps,
    gastosVariables,
    presupuestosCategorias,
    idxPagosDeudaDeudaId,
    idxPagosRecibidosPrestamoId,
  ];
}

typedef $$DeudasTableCreateCompanionBuilder =
    DeudasCompanion Function({
      Value<int> id,
      required String acreedorNombre,
      required double montoOriginal,
      Value<double> tasaInteres,
      Value<String> tipoInteres,
      Value<String> modalidadCalculo,
      required DateTime fechaPrestamo,
      Value<DateTime?> fechaLimite,
      Value<double?> cuotaMensual,
      Value<String> notas,
      Value<String> estado,
      Value<DateTime?> fechaPagoReal,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });
typedef $$DeudasTableUpdateCompanionBuilder =
    DeudasCompanion Function({
      Value<int> id,
      Value<String> acreedorNombre,
      Value<double> montoOriginal,
      Value<double> tasaInteres,
      Value<String> tipoInteres,
      Value<String> modalidadCalculo,
      Value<DateTime> fechaPrestamo,
      Value<DateTime?> fechaLimite,
      Value<double?> cuotaMensual,
      Value<String> notas,
      Value<String> estado,
      Value<DateTime?> fechaPagoReal,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });

final class $$DeudasTableReferences
    extends BaseReferences<_$AppDatabase, $DeudasTable, Deuda> {
  $$DeudasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PagosDeudaTable, List<PagosDeudaData>>
  _pagosDeudaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pagosDeuda,
    aliasName: $_aliasNameGenerator(db.deudas.id, db.pagosDeuda.deudaId),
  );

  $$PagosDeudaTableProcessedTableManager get pagosDeudaRefs {
    final manager = $$PagosDeudaTableTableManager(
      $_db,
      $_db.pagosDeuda,
    ).filter((f) => f.deudaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pagosDeudaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DeudasTableFilterComposer
    extends Composer<_$AppDatabase, $DeudasTable> {
  $$DeudasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acreedorNombre => $composableBuilder(
    column: $table.acreedorNombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoOriginal => $composableBuilder(
    column: $table.montoOriginal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tasaInteres => $composableBuilder(
    column: $table.tasaInteres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoInteres => $composableBuilder(
    column: $table.tipoInteres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modalidadCalculo => $composableBuilder(
    column: $table.modalidadCalculo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaPrestamo => $composableBuilder(
    column: $table.fechaPrestamo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaLimite => $composableBuilder(
    column: $table.fechaLimite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cuotaMensual => $composableBuilder(
    column: $table.cuotaMensual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaPagoReal => $composableBuilder(
    column: $table.fechaPagoReal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pagosDeudaRefs(
    Expression<bool> Function($$PagosDeudaTableFilterComposer f) f,
  ) {
    final $$PagosDeudaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagosDeuda,
      getReferencedColumn: (t) => t.deudaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagosDeudaTableFilterComposer(
            $db: $db,
            $table: $db.pagosDeuda,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DeudasTableOrderingComposer
    extends Composer<_$AppDatabase, $DeudasTable> {
  $$DeudasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acreedorNombre => $composableBuilder(
    column: $table.acreedorNombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoOriginal => $composableBuilder(
    column: $table.montoOriginal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tasaInteres => $composableBuilder(
    column: $table.tasaInteres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoInteres => $composableBuilder(
    column: $table.tipoInteres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modalidadCalculo => $composableBuilder(
    column: $table.modalidadCalculo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaPrestamo => $composableBuilder(
    column: $table.fechaPrestamo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaLimite => $composableBuilder(
    column: $table.fechaLimite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cuotaMensual => $composableBuilder(
    column: $table.cuotaMensual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaPagoReal => $composableBuilder(
    column: $table.fechaPagoReal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeudasTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeudasTable> {
  $$DeudasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get acreedorNombre => $composableBuilder(
    column: $table.acreedorNombre,
    builder: (column) => column,
  );

  GeneratedColumn<double> get montoOriginal => $composableBuilder(
    column: $table.montoOriginal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tasaInteres => $composableBuilder(
    column: $table.tasaInteres,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipoInteres => $composableBuilder(
    column: $table.tipoInteres,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modalidadCalculo => $composableBuilder(
    column: $table.modalidadCalculo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaPrestamo => $composableBuilder(
    column: $table.fechaPrestamo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaLimite => $composableBuilder(
    column: $table.fechaLimite,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cuotaMensual => $composableBuilder(
    column: $table.cuotaMensual,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaPagoReal => $composableBuilder(
    column: $table.fechaPagoReal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );

  Expression<T> pagosDeudaRefs<T extends Object>(
    Expression<T> Function($$PagosDeudaTableAnnotationComposer a) f,
  ) {
    final $$PagosDeudaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagosDeuda,
      getReferencedColumn: (t) => t.deudaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagosDeudaTableAnnotationComposer(
            $db: $db,
            $table: $db.pagosDeuda,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DeudasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeudasTable,
          Deuda,
          $$DeudasTableFilterComposer,
          $$DeudasTableOrderingComposer,
          $$DeudasTableAnnotationComposer,
          $$DeudasTableCreateCompanionBuilder,
          $$DeudasTableUpdateCompanionBuilder,
          (Deuda, $$DeudasTableReferences),
          Deuda,
          PrefetchHooks Function({bool pagosDeudaRefs})
        > {
  $$DeudasTableTableManager(_$AppDatabase db, $DeudasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeudasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeudasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeudasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> acreedorNombre = const Value.absent(),
                Value<double> montoOriginal = const Value.absent(),
                Value<double> tasaInteres = const Value.absent(),
                Value<String> tipoInteres = const Value.absent(),
                Value<String> modalidadCalculo = const Value.absent(),
                Value<DateTime> fechaPrestamo = const Value.absent(),
                Value<DateTime?> fechaLimite = const Value.absent(),
                Value<double?> cuotaMensual = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<DateTime?> fechaPagoReal = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => DeudasCompanion(
                id: id,
                acreedorNombre: acreedorNombre,
                montoOriginal: montoOriginal,
                tasaInteres: tasaInteres,
                tipoInteres: tipoInteres,
                modalidadCalculo: modalidadCalculo,
                fechaPrestamo: fechaPrestamo,
                fechaLimite: fechaLimite,
                cuotaMensual: cuotaMensual,
                notas: notas,
                estado: estado,
                fechaPagoReal: fechaPagoReal,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String acreedorNombre,
                required double montoOriginal,
                Value<double> tasaInteres = const Value.absent(),
                Value<String> tipoInteres = const Value.absent(),
                Value<String> modalidadCalculo = const Value.absent(),
                required DateTime fechaPrestamo,
                Value<DateTime?> fechaLimite = const Value.absent(),
                Value<double?> cuotaMensual = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<DateTime?> fechaPagoReal = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => DeudasCompanion.insert(
                id: id,
                acreedorNombre: acreedorNombre,
                montoOriginal: montoOriginal,
                tasaInteres: tasaInteres,
                tipoInteres: tipoInteres,
                modalidadCalculo: modalidadCalculo,
                fechaPrestamo: fechaPrestamo,
                fechaLimite: fechaLimite,
                cuotaMensual: cuotaMensual,
                notas: notas,
                estado: estado,
                fechaPagoReal: fechaPagoReal,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DeudasTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({pagosDeudaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (pagosDeudaRefs) db.pagosDeuda],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pagosDeudaRefs)
                    await $_getPrefetchedData<
                      Deuda,
                      $DeudasTable,
                      PagosDeudaData
                    >(
                      currentTable: table,
                      referencedTable: $$DeudasTableReferences
                          ._pagosDeudaRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DeudasTableReferences(db, table, p0).pagosDeudaRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.deudaId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DeudasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeudasTable,
      Deuda,
      $$DeudasTableFilterComposer,
      $$DeudasTableOrderingComposer,
      $$DeudasTableAnnotationComposer,
      $$DeudasTableCreateCompanionBuilder,
      $$DeudasTableUpdateCompanionBuilder,
      (Deuda, $$DeudasTableReferences),
      Deuda,
      PrefetchHooks Function({bool pagosDeudaRefs})
    >;
typedef $$PagosDeudaTableCreateCompanionBuilder =
    PagosDeudaCompanion Function({
      Value<int> id,
      required int deudaId,
      required double montoAbonado,
      required DateTime fechaPago,
      Value<String> notas,
      Value<DateTime> creadoEn,
    });
typedef $$PagosDeudaTableUpdateCompanionBuilder =
    PagosDeudaCompanion Function({
      Value<int> id,
      Value<int> deudaId,
      Value<double> montoAbonado,
      Value<DateTime> fechaPago,
      Value<String> notas,
      Value<DateTime> creadoEn,
    });

final class $$PagosDeudaTableReferences
    extends BaseReferences<_$AppDatabase, $PagosDeudaTable, PagosDeudaData> {
  $$PagosDeudaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DeudasTable _deudaIdTable(_$AppDatabase db) => db.deudas.createAlias(
    $_aliasNameGenerator(db.pagosDeuda.deudaId, db.deudas.id),
  );

  $$DeudasTableProcessedTableManager get deudaId {
    final $_column = $_itemColumn<int>('deuda_id')!;

    final manager = $$DeudasTableTableManager(
      $_db,
      $_db.deudas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deudaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PagosDeudaTableFilterComposer
    extends Composer<_$AppDatabase, $PagosDeudaTable> {
  $$PagosDeudaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoAbonado => $composableBuilder(
    column: $table.montoAbonado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaPago => $composableBuilder(
    column: $table.fechaPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$DeudasTableFilterComposer get deudaId {
    final $$DeudasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deudaId,
      referencedTable: $db.deudas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeudasTableFilterComposer(
            $db: $db,
            $table: $db.deudas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosDeudaTableOrderingComposer
    extends Composer<_$AppDatabase, $PagosDeudaTable> {
  $$PagosDeudaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoAbonado => $composableBuilder(
    column: $table.montoAbonado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaPago => $composableBuilder(
    column: $table.fechaPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$DeudasTableOrderingComposer get deudaId {
    final $$DeudasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deudaId,
      referencedTable: $db.deudas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeudasTableOrderingComposer(
            $db: $db,
            $table: $db.deudas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosDeudaTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagosDeudaTable> {
  $$PagosDeudaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get montoAbonado => $composableBuilder(
    column: $table.montoAbonado,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaPago =>
      $composableBuilder(column: $table.fechaPago, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  $$DeudasTableAnnotationComposer get deudaId {
    final $$DeudasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deudaId,
      referencedTable: $db.deudas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeudasTableAnnotationComposer(
            $db: $db,
            $table: $db.deudas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosDeudaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagosDeudaTable,
          PagosDeudaData,
          $$PagosDeudaTableFilterComposer,
          $$PagosDeudaTableOrderingComposer,
          $$PagosDeudaTableAnnotationComposer,
          $$PagosDeudaTableCreateCompanionBuilder,
          $$PagosDeudaTableUpdateCompanionBuilder,
          (PagosDeudaData, $$PagosDeudaTableReferences),
          PagosDeudaData,
          PrefetchHooks Function({bool deudaId})
        > {
  $$PagosDeudaTableTableManager(_$AppDatabase db, $PagosDeudaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagosDeudaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagosDeudaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagosDeudaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> deudaId = const Value.absent(),
                Value<double> montoAbonado = const Value.absent(),
                Value<DateTime> fechaPago = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
              }) => PagosDeudaCompanion(
                id: id,
                deudaId: deudaId,
                montoAbonado: montoAbonado,
                fechaPago: fechaPago,
                notas: notas,
                creadoEn: creadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int deudaId,
                required double montoAbonado,
                required DateTime fechaPago,
                Value<String> notas = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
              }) => PagosDeudaCompanion.insert(
                id: id,
                deudaId: deudaId,
                montoAbonado: montoAbonado,
                fechaPago: fechaPago,
                notas: notas,
                creadoEn: creadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PagosDeudaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deudaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deudaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deudaId,
                                referencedTable: $$PagosDeudaTableReferences
                                    ._deudaIdTable(db),
                                referencedColumn: $$PagosDeudaTableReferences
                                    ._deudaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PagosDeudaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagosDeudaTable,
      PagosDeudaData,
      $$PagosDeudaTableFilterComposer,
      $$PagosDeudaTableOrderingComposer,
      $$PagosDeudaTableAnnotationComposer,
      $$PagosDeudaTableCreateCompanionBuilder,
      $$PagosDeudaTableUpdateCompanionBuilder,
      (PagosDeudaData, $$PagosDeudaTableReferences),
      PagosDeudaData,
      PrefetchHooks Function({bool deudaId})
    >;
typedef $$PrestamosTableCreateCompanionBuilder =
    PrestamosCompanion Function({
      Value<int> id,
      required String deudorNombre,
      Value<String> deudorContacto,
      required double montoPrestado,
      Value<double> tasaInteres,
      Value<String> tipoInteres,
      Value<String> modalidadCalculo,
      required DateTime fechaPrestamo,
      Value<DateTime?> fechaPactadaPago,
      Value<String> estado,
      Value<String> notas,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });
typedef $$PrestamosTableUpdateCompanionBuilder =
    PrestamosCompanion Function({
      Value<int> id,
      Value<String> deudorNombre,
      Value<String> deudorContacto,
      Value<double> montoPrestado,
      Value<double> tasaInteres,
      Value<String> tipoInteres,
      Value<String> modalidadCalculo,
      Value<DateTime> fechaPrestamo,
      Value<DateTime?> fechaPactadaPago,
      Value<String> estado,
      Value<String> notas,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });

final class $$PrestamosTableReferences
    extends BaseReferences<_$AppDatabase, $PrestamosTable, Prestamo> {
  $$PrestamosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PagosRecibidosTable, List<PagosRecibido>>
  _pagosRecibidosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pagosRecibidos,
    aliasName: $_aliasNameGenerator(
      db.prestamos.id,
      db.pagosRecibidos.prestamoId,
    ),
  );

  $$PagosRecibidosTableProcessedTableManager get pagosRecibidosRefs {
    final manager = $$PagosRecibidosTableTableManager(
      $_db,
      $_db.pagosRecibidos,
    ).filter((f) => f.prestamoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pagosRecibidosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PrestamosTableFilterComposer
    extends Composer<_$AppDatabase, $PrestamosTable> {
  $$PrestamosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deudorNombre => $composableBuilder(
    column: $table.deudorNombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deudorContacto => $composableBuilder(
    column: $table.deudorContacto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoPrestado => $composableBuilder(
    column: $table.montoPrestado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tasaInteres => $composableBuilder(
    column: $table.tasaInteres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoInteres => $composableBuilder(
    column: $table.tipoInteres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modalidadCalculo => $composableBuilder(
    column: $table.modalidadCalculo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaPrestamo => $composableBuilder(
    column: $table.fechaPrestamo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaPactadaPago => $composableBuilder(
    column: $table.fechaPactadaPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pagosRecibidosRefs(
    Expression<bool> Function($$PagosRecibidosTableFilterComposer f) f,
  ) {
    final $$PagosRecibidosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagosRecibidos,
      getReferencedColumn: (t) => t.prestamoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagosRecibidosTableFilterComposer(
            $db: $db,
            $table: $db.pagosRecibidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PrestamosTableOrderingComposer
    extends Composer<_$AppDatabase, $PrestamosTable> {
  $$PrestamosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deudorNombre => $composableBuilder(
    column: $table.deudorNombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deudorContacto => $composableBuilder(
    column: $table.deudorContacto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoPrestado => $composableBuilder(
    column: $table.montoPrestado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tasaInteres => $composableBuilder(
    column: $table.tasaInteres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoInteres => $composableBuilder(
    column: $table.tipoInteres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modalidadCalculo => $composableBuilder(
    column: $table.modalidadCalculo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaPrestamo => $composableBuilder(
    column: $table.fechaPrestamo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaPactadaPago => $composableBuilder(
    column: $table.fechaPactadaPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrestamosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrestamosTable> {
  $$PrestamosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deudorNombre => $composableBuilder(
    column: $table.deudorNombre,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deudorContacto => $composableBuilder(
    column: $table.deudorContacto,
    builder: (column) => column,
  );

  GeneratedColumn<double> get montoPrestado => $composableBuilder(
    column: $table.montoPrestado,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tasaInteres => $composableBuilder(
    column: $table.tasaInteres,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipoInteres => $composableBuilder(
    column: $table.tipoInteres,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modalidadCalculo => $composableBuilder(
    column: $table.modalidadCalculo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaPrestamo => $composableBuilder(
    column: $table.fechaPrestamo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaPactadaPago => $composableBuilder(
    column: $table.fechaPactadaPago,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );

  Expression<T> pagosRecibidosRefs<T extends Object>(
    Expression<T> Function($$PagosRecibidosTableAnnotationComposer a) f,
  ) {
    final $$PagosRecibidosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagosRecibidos,
      getReferencedColumn: (t) => t.prestamoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagosRecibidosTableAnnotationComposer(
            $db: $db,
            $table: $db.pagosRecibidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PrestamosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrestamosTable,
          Prestamo,
          $$PrestamosTableFilterComposer,
          $$PrestamosTableOrderingComposer,
          $$PrestamosTableAnnotationComposer,
          $$PrestamosTableCreateCompanionBuilder,
          $$PrestamosTableUpdateCompanionBuilder,
          (Prestamo, $$PrestamosTableReferences),
          Prestamo,
          PrefetchHooks Function({bool pagosRecibidosRefs})
        > {
  $$PrestamosTableTableManager(_$AppDatabase db, $PrestamosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrestamosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrestamosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrestamosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deudorNombre = const Value.absent(),
                Value<String> deudorContacto = const Value.absent(),
                Value<double> montoPrestado = const Value.absent(),
                Value<double> tasaInteres = const Value.absent(),
                Value<String> tipoInteres = const Value.absent(),
                Value<String> modalidadCalculo = const Value.absent(),
                Value<DateTime> fechaPrestamo = const Value.absent(),
                Value<DateTime?> fechaPactadaPago = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => PrestamosCompanion(
                id: id,
                deudorNombre: deudorNombre,
                deudorContacto: deudorContacto,
                montoPrestado: montoPrestado,
                tasaInteres: tasaInteres,
                tipoInteres: tipoInteres,
                modalidadCalculo: modalidadCalculo,
                fechaPrestamo: fechaPrestamo,
                fechaPactadaPago: fechaPactadaPago,
                estado: estado,
                notas: notas,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deudorNombre,
                Value<String> deudorContacto = const Value.absent(),
                required double montoPrestado,
                Value<double> tasaInteres = const Value.absent(),
                Value<String> tipoInteres = const Value.absent(),
                Value<String> modalidadCalculo = const Value.absent(),
                required DateTime fechaPrestamo,
                Value<DateTime?> fechaPactadaPago = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => PrestamosCompanion.insert(
                id: id,
                deudorNombre: deudorNombre,
                deudorContacto: deudorContacto,
                montoPrestado: montoPrestado,
                tasaInteres: tasaInteres,
                tipoInteres: tipoInteres,
                modalidadCalculo: modalidadCalculo,
                fechaPrestamo: fechaPrestamo,
                fechaPactadaPago: fechaPactadaPago,
                estado: estado,
                notas: notas,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PrestamosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pagosRecibidosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (pagosRecibidosRefs) db.pagosRecibidos,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pagosRecibidosRefs)
                    await $_getPrefetchedData<
                      Prestamo,
                      $PrestamosTable,
                      PagosRecibido
                    >(
                      currentTable: table,
                      referencedTable: $$PrestamosTableReferences
                          ._pagosRecibidosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PrestamosTableReferences(
                            db,
                            table,
                            p0,
                          ).pagosRecibidosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.prestamoId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PrestamosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrestamosTable,
      Prestamo,
      $$PrestamosTableFilterComposer,
      $$PrestamosTableOrderingComposer,
      $$PrestamosTableAnnotationComposer,
      $$PrestamosTableCreateCompanionBuilder,
      $$PrestamosTableUpdateCompanionBuilder,
      (Prestamo, $$PrestamosTableReferences),
      Prestamo,
      PrefetchHooks Function({bool pagosRecibidosRefs})
    >;
typedef $$PagosRecibidosTableCreateCompanionBuilder =
    PagosRecibidosCompanion Function({
      Value<int> id,
      required int prestamoId,
      required double montoAbonado,
      required DateTime fechaPago,
      Value<String> notas,
      Value<DateTime> creadoEn,
    });
typedef $$PagosRecibidosTableUpdateCompanionBuilder =
    PagosRecibidosCompanion Function({
      Value<int> id,
      Value<int> prestamoId,
      Value<double> montoAbonado,
      Value<DateTime> fechaPago,
      Value<String> notas,
      Value<DateTime> creadoEn,
    });

final class $$PagosRecibidosTableReferences
    extends BaseReferences<_$AppDatabase, $PagosRecibidosTable, PagosRecibido> {
  $$PagosRecibidosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PrestamosTable _prestamoIdTable(_$AppDatabase db) =>
      db.prestamos.createAlias(
        $_aliasNameGenerator(db.pagosRecibidos.prestamoId, db.prestamos.id),
      );

  $$PrestamosTableProcessedTableManager get prestamoId {
    final $_column = $_itemColumn<int>('prestamo_id')!;

    final manager = $$PrestamosTableTableManager(
      $_db,
      $_db.prestamos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_prestamoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PagosRecibidosTableFilterComposer
    extends Composer<_$AppDatabase, $PagosRecibidosTable> {
  $$PagosRecibidosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoAbonado => $composableBuilder(
    column: $table.montoAbonado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaPago => $composableBuilder(
    column: $table.fechaPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$PrestamosTableFilterComposer get prestamoId {
    final $$PrestamosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prestamoId,
      referencedTable: $db.prestamos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrestamosTableFilterComposer(
            $db: $db,
            $table: $db.prestamos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosRecibidosTableOrderingComposer
    extends Composer<_$AppDatabase, $PagosRecibidosTable> {
  $$PagosRecibidosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoAbonado => $composableBuilder(
    column: $table.montoAbonado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaPago => $composableBuilder(
    column: $table.fechaPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$PrestamosTableOrderingComposer get prestamoId {
    final $$PrestamosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prestamoId,
      referencedTable: $db.prestamos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrestamosTableOrderingComposer(
            $db: $db,
            $table: $db.prestamos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosRecibidosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagosRecibidosTable> {
  $$PagosRecibidosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get montoAbonado => $composableBuilder(
    column: $table.montoAbonado,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaPago =>
      $composableBuilder(column: $table.fechaPago, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  $$PrestamosTableAnnotationComposer get prestamoId {
    final $$PrestamosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prestamoId,
      referencedTable: $db.prestamos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrestamosTableAnnotationComposer(
            $db: $db,
            $table: $db.prestamos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosRecibidosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagosRecibidosTable,
          PagosRecibido,
          $$PagosRecibidosTableFilterComposer,
          $$PagosRecibidosTableOrderingComposer,
          $$PagosRecibidosTableAnnotationComposer,
          $$PagosRecibidosTableCreateCompanionBuilder,
          $$PagosRecibidosTableUpdateCompanionBuilder,
          (PagosRecibido, $$PagosRecibidosTableReferences),
          PagosRecibido,
          PrefetchHooks Function({bool prestamoId})
        > {
  $$PagosRecibidosTableTableManager(
    _$AppDatabase db,
    $PagosRecibidosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagosRecibidosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagosRecibidosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagosRecibidosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> prestamoId = const Value.absent(),
                Value<double> montoAbonado = const Value.absent(),
                Value<DateTime> fechaPago = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
              }) => PagosRecibidosCompanion(
                id: id,
                prestamoId: prestamoId,
                montoAbonado: montoAbonado,
                fechaPago: fechaPago,
                notas: notas,
                creadoEn: creadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int prestamoId,
                required double montoAbonado,
                required DateTime fechaPago,
                Value<String> notas = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
              }) => PagosRecibidosCompanion.insert(
                id: id,
                prestamoId: prestamoId,
                montoAbonado: montoAbonado,
                fechaPago: fechaPago,
                notas: notas,
                creadoEn: creadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PagosRecibidosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({prestamoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (prestamoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.prestamoId,
                                referencedTable: $$PagosRecibidosTableReferences
                                    ._prestamoIdTable(db),
                                referencedColumn:
                                    $$PagosRecibidosTableReferences
                                        ._prestamoIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PagosRecibidosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagosRecibidosTable,
      PagosRecibido,
      $$PagosRecibidosTableFilterComposer,
      $$PagosRecibidosTableOrderingComposer,
      $$PagosRecibidosTableAnnotationComposer,
      $$PagosRecibidosTableCreateCompanionBuilder,
      $$PagosRecibidosTableUpdateCompanionBuilder,
      (PagosRecibido, $$PagosRecibidosTableReferences),
      PagosRecibido,
      PrefetchHooks Function({bool prestamoId})
    >;
typedef $$IngresosTableCreateCompanionBuilder =
    IngresosCompanion Function({
      Value<int> id,
      required String concepto,
      required double monto,
      Value<String> frecuencia,
      required DateTime fecha,
      Value<String> notas,
      Value<bool> activo,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });
typedef $$IngresosTableUpdateCompanionBuilder =
    IngresosCompanion Function({
      Value<int> id,
      Value<String> concepto,
      Value<double> monto,
      Value<String> frecuencia,
      Value<DateTime> fecha,
      Value<String> notas,
      Value<bool> activo,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });

class $$IngresosTableFilterComposer
    extends Composer<_$AppDatabase, $IngresosTable> {
  $$IngresosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get concepto => $composableBuilder(
    column: $table.concepto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IngresosTableOrderingComposer
    extends Composer<_$AppDatabase, $IngresosTable> {
  $$IngresosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get concepto => $composableBuilder(
    column: $table.concepto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngresosTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngresosTable> {
  $$IngresosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get concepto =>
      $composableBuilder(column: $table.concepto, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );
}

class $$IngresosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngresosTable,
          Ingreso,
          $$IngresosTableFilterComposer,
          $$IngresosTableOrderingComposer,
          $$IngresosTableAnnotationComposer,
          $$IngresosTableCreateCompanionBuilder,
          $$IngresosTableUpdateCompanionBuilder,
          (Ingreso, BaseReferences<_$AppDatabase, $IngresosTable, Ingreso>),
          Ingreso,
          PrefetchHooks Function()
        > {
  $$IngresosTableTableManager(_$AppDatabase db, $IngresosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngresosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngresosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngresosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> concepto = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<String> frecuencia = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => IngresosCompanion(
                id: id,
                concepto: concepto,
                monto: monto,
                frecuencia: frecuencia,
                fecha: fecha,
                notas: notas,
                activo: activo,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String concepto,
                required double monto,
                Value<String> frecuencia = const Value.absent(),
                required DateTime fecha,
                Value<String> notas = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => IngresosCompanion.insert(
                id: id,
                concepto: concepto,
                monto: monto,
                frecuencia: frecuencia,
                fecha: fecha,
                notas: notas,
                activo: activo,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngresosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngresosTable,
      Ingreso,
      $$IngresosTableFilterComposer,
      $$IngresosTableOrderingComposer,
      $$IngresosTableAnnotationComposer,
      $$IngresosTableCreateCompanionBuilder,
      $$IngresosTableUpdateCompanionBuilder,
      (Ingreso, BaseReferences<_$AppDatabase, $IngresosTable, Ingreso>),
      Ingreso,
      PrefetchHooks Function()
    >;
typedef $$GastosFijosTableCreateCompanionBuilder =
    GastosFijosCompanion Function({
      Value<int> id,
      required String concepto,
      required double monto,
      Value<String> frecuencia,
      Value<int?> diaCobro,
      Value<String> notas,
      Value<bool> activo,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });
typedef $$GastosFijosTableUpdateCompanionBuilder =
    GastosFijosCompanion Function({
      Value<int> id,
      Value<String> concepto,
      Value<double> monto,
      Value<String> frecuencia,
      Value<int?> diaCobro,
      Value<String> notas,
      Value<bool> activo,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });

class $$GastosFijosTableFilterComposer
    extends Composer<_$AppDatabase, $GastosFijosTable> {
  $$GastosFijosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get concepto => $composableBuilder(
    column: $table.concepto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diaCobro => $composableBuilder(
    column: $table.diaCobro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GastosFijosTableOrderingComposer
    extends Composer<_$AppDatabase, $GastosFijosTable> {
  $$GastosFijosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get concepto => $composableBuilder(
    column: $table.concepto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diaCobro => $composableBuilder(
    column: $table.diaCobro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GastosFijosTableAnnotationComposer
    extends Composer<_$AppDatabase, $GastosFijosTable> {
  $$GastosFijosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get concepto =>
      $composableBuilder(column: $table.concepto, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diaCobro =>
      $composableBuilder(column: $table.diaCobro, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );
}

class $$GastosFijosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GastosFijosTable,
          GastosFijo,
          $$GastosFijosTableFilterComposer,
          $$GastosFijosTableOrderingComposer,
          $$GastosFijosTableAnnotationComposer,
          $$GastosFijosTableCreateCompanionBuilder,
          $$GastosFijosTableUpdateCompanionBuilder,
          (
            GastosFijo,
            BaseReferences<_$AppDatabase, $GastosFijosTable, GastosFijo>,
          ),
          GastosFijo,
          PrefetchHooks Function()
        > {
  $$GastosFijosTableTableManager(_$AppDatabase db, $GastosFijosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GastosFijosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GastosFijosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GastosFijosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> concepto = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<String> frecuencia = const Value.absent(),
                Value<int?> diaCobro = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => GastosFijosCompanion(
                id: id,
                concepto: concepto,
                monto: monto,
                frecuencia: frecuencia,
                diaCobro: diaCobro,
                notas: notas,
                activo: activo,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String concepto,
                required double monto,
                Value<String> frecuencia = const Value.absent(),
                Value<int?> diaCobro = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => GastosFijosCompanion.insert(
                id: id,
                concepto: concepto,
                monto: monto,
                frecuencia: frecuencia,
                diaCobro: diaCobro,
                notas: notas,
                activo: activo,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GastosFijosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GastosFijosTable,
      GastosFijo,
      $$GastosFijosTableFilterComposer,
      $$GastosFijosTableOrderingComposer,
      $$GastosFijosTableAnnotationComposer,
      $$GastosFijosTableCreateCompanionBuilder,
      $$GastosFijosTableUpdateCompanionBuilder,
      (
        GastosFijo,
        BaseReferences<_$AppDatabase, $GastosFijosTable, GastosFijo>,
      ),
      GastosFijo,
      PrefetchHooks Function()
    >;
typedef $$RecordatoriosTableCreateCompanionBuilder =
    RecordatoriosCompanion Function({
      Value<int> id,
      required String titulo,
      Value<String?> referenciaTabla,
      Value<int?> referenciaId,
      required DateTime fechaAlerta,
      Value<int> diasAnticipacion,
      Value<String> tipoNotificacion,
      Value<bool> repetir,
      Value<bool> activo,
      Value<DateTime> creadoEn,
      Value<String> frecuenciaAviso,
      Value<DateTime?> ultimaNotificacion,
      Value<DateTime?> ultimoEnvioCorreo,
      Value<int> horaAviso,
      Value<int> minutoAviso,
    });
typedef $$RecordatoriosTableUpdateCompanionBuilder =
    RecordatoriosCompanion Function({
      Value<int> id,
      Value<String> titulo,
      Value<String?> referenciaTabla,
      Value<int?> referenciaId,
      Value<DateTime> fechaAlerta,
      Value<int> diasAnticipacion,
      Value<String> tipoNotificacion,
      Value<bool> repetir,
      Value<bool> activo,
      Value<DateTime> creadoEn,
      Value<String> frecuenciaAviso,
      Value<DateTime?> ultimaNotificacion,
      Value<DateTime?> ultimoEnvioCorreo,
      Value<int> horaAviso,
      Value<int> minutoAviso,
    });

class $$RecordatoriosTableFilterComposer
    extends Composer<_$AppDatabase, $RecordatoriosTable> {
  $$RecordatoriosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenciaTabla => $composableBuilder(
    column: $table.referenciaTabla,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get referenciaId => $composableBuilder(
    column: $table.referenciaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaAlerta => $composableBuilder(
    column: $table.fechaAlerta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diasAnticipacion => $composableBuilder(
    column: $table.diasAnticipacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoNotificacion => $composableBuilder(
    column: $table.tipoNotificacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get repetir => $composableBuilder(
    column: $table.repetir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frecuenciaAviso => $composableBuilder(
    column: $table.frecuenciaAviso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimaNotificacion => $composableBuilder(
    column: $table.ultimaNotificacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimoEnvioCorreo => $composableBuilder(
    column: $table.ultimoEnvioCorreo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get horaAviso => $composableBuilder(
    column: $table.horaAviso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutoAviso => $composableBuilder(
    column: $table.minutoAviso,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordatoriosTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordatoriosTable> {
  $$RecordatoriosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenciaTabla => $composableBuilder(
    column: $table.referenciaTabla,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get referenciaId => $composableBuilder(
    column: $table.referenciaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaAlerta => $composableBuilder(
    column: $table.fechaAlerta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diasAnticipacion => $composableBuilder(
    column: $table.diasAnticipacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoNotificacion => $composableBuilder(
    column: $table.tipoNotificacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get repetir => $composableBuilder(
    column: $table.repetir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frecuenciaAviso => $composableBuilder(
    column: $table.frecuenciaAviso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimaNotificacion => $composableBuilder(
    column: $table.ultimaNotificacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimoEnvioCorreo => $composableBuilder(
    column: $table.ultimoEnvioCorreo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get horaAviso => $composableBuilder(
    column: $table.horaAviso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutoAviso => $composableBuilder(
    column: $table.minutoAviso,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordatoriosTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordatoriosTable> {
  $$RecordatoriosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get referenciaTabla => $composableBuilder(
    column: $table.referenciaTabla,
    builder: (column) => column,
  );

  GeneratedColumn<int> get referenciaId => $composableBuilder(
    column: $table.referenciaId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaAlerta => $composableBuilder(
    column: $table.fechaAlerta,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diasAnticipacion => $composableBuilder(
    column: $table.diasAnticipacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipoNotificacion => $composableBuilder(
    column: $table.tipoNotificacion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get repetir =>
      $composableBuilder(column: $table.repetir, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<String> get frecuenciaAviso => $composableBuilder(
    column: $table.frecuenciaAviso,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ultimaNotificacion => $composableBuilder(
    column: $table.ultimaNotificacion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ultimoEnvioCorreo => $composableBuilder(
    column: $table.ultimoEnvioCorreo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get horaAviso =>
      $composableBuilder(column: $table.horaAviso, builder: (column) => column);

  GeneratedColumn<int> get minutoAviso => $composableBuilder(
    column: $table.minutoAviso,
    builder: (column) => column,
  );
}

class $$RecordatoriosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordatoriosTable,
          Recordatorio,
          $$RecordatoriosTableFilterComposer,
          $$RecordatoriosTableOrderingComposer,
          $$RecordatoriosTableAnnotationComposer,
          $$RecordatoriosTableCreateCompanionBuilder,
          $$RecordatoriosTableUpdateCompanionBuilder,
          (
            Recordatorio,
            BaseReferences<_$AppDatabase, $RecordatoriosTable, Recordatorio>,
          ),
          Recordatorio,
          PrefetchHooks Function()
        > {
  $$RecordatoriosTableTableManager(_$AppDatabase db, $RecordatoriosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordatoriosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordatoriosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordatoriosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> titulo = const Value.absent(),
                Value<String?> referenciaTabla = const Value.absent(),
                Value<int?> referenciaId = const Value.absent(),
                Value<DateTime> fechaAlerta = const Value.absent(),
                Value<int> diasAnticipacion = const Value.absent(),
                Value<String> tipoNotificacion = const Value.absent(),
                Value<bool> repetir = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<String> frecuenciaAviso = const Value.absent(),
                Value<DateTime?> ultimaNotificacion = const Value.absent(),
                Value<DateTime?> ultimoEnvioCorreo = const Value.absent(),
                Value<int> horaAviso = const Value.absent(),
                Value<int> minutoAviso = const Value.absent(),
              }) => RecordatoriosCompanion(
                id: id,
                titulo: titulo,
                referenciaTabla: referenciaTabla,
                referenciaId: referenciaId,
                fechaAlerta: fechaAlerta,
                diasAnticipacion: diasAnticipacion,
                tipoNotificacion: tipoNotificacion,
                repetir: repetir,
                activo: activo,
                creadoEn: creadoEn,
                frecuenciaAviso: frecuenciaAviso,
                ultimaNotificacion: ultimaNotificacion,
                ultimoEnvioCorreo: ultimoEnvioCorreo,
                horaAviso: horaAviso,
                minutoAviso: minutoAviso,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String titulo,
                Value<String?> referenciaTabla = const Value.absent(),
                Value<int?> referenciaId = const Value.absent(),
                required DateTime fechaAlerta,
                Value<int> diasAnticipacion = const Value.absent(),
                Value<String> tipoNotificacion = const Value.absent(),
                Value<bool> repetir = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<String> frecuenciaAviso = const Value.absent(),
                Value<DateTime?> ultimaNotificacion = const Value.absent(),
                Value<DateTime?> ultimoEnvioCorreo = const Value.absent(),
                Value<int> horaAviso = const Value.absent(),
                Value<int> minutoAviso = const Value.absent(),
              }) => RecordatoriosCompanion.insert(
                id: id,
                titulo: titulo,
                referenciaTabla: referenciaTabla,
                referenciaId: referenciaId,
                fechaAlerta: fechaAlerta,
                diasAnticipacion: diasAnticipacion,
                tipoNotificacion: tipoNotificacion,
                repetir: repetir,
                activo: activo,
                creadoEn: creadoEn,
                frecuenciaAviso: frecuenciaAviso,
                ultimaNotificacion: ultimaNotificacion,
                ultimoEnvioCorreo: ultimoEnvioCorreo,
                horaAviso: horaAviso,
                minutoAviso: minutoAviso,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordatoriosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordatoriosTable,
      Recordatorio,
      $$RecordatoriosTableFilterComposer,
      $$RecordatoriosTableOrderingComposer,
      $$RecordatoriosTableAnnotationComposer,
      $$RecordatoriosTableCreateCompanionBuilder,
      $$RecordatoriosTableUpdateCompanionBuilder,
      (
        Recordatorio,
        BaseReferences<_$AppDatabase, $RecordatoriosTable, Recordatorio>,
      ),
      Recordatorio,
      PrefetchHooks Function()
    >;
typedef $$ConfigSmtpsTableCreateCompanionBuilder =
    ConfigSmtpsCompanion Function({
      Value<int> id,
      Value<String> servidor,
      Value<int> puerto,
      Value<String> usuario,
      Value<String?> contrasenaEncriptada,
      Value<bool> tieneContrasena,
      Value<String> correoDestino,
      Value<String> nombreRemitente,
      Value<bool> ssl,
      Value<bool> habilitado,
      Value<DateTime> actualizadoEn,
    });
typedef $$ConfigSmtpsTableUpdateCompanionBuilder =
    ConfigSmtpsCompanion Function({
      Value<int> id,
      Value<String> servidor,
      Value<int> puerto,
      Value<String> usuario,
      Value<String?> contrasenaEncriptada,
      Value<bool> tieneContrasena,
      Value<String> correoDestino,
      Value<String> nombreRemitente,
      Value<bool> ssl,
      Value<bool> habilitado,
      Value<DateTime> actualizadoEn,
    });

class $$ConfigSmtpsTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigSmtpsTable> {
  $$ConfigSmtpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servidor => $composableBuilder(
    column: $table.servidor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get puerto => $composableBuilder(
    column: $table.puerto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuario => $composableBuilder(
    column: $table.usuario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contrasenaEncriptada => $composableBuilder(
    column: $table.contrasenaEncriptada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tieneContrasena => $composableBuilder(
    column: $table.tieneContrasena,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correoDestino => $composableBuilder(
    column: $table.correoDestino,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreRemitente => $composableBuilder(
    column: $table.nombreRemitente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ssl => $composableBuilder(
    column: $table.ssl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get habilitado => $composableBuilder(
    column: $table.habilitado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfigSmtpsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigSmtpsTable> {
  $$ConfigSmtpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servidor => $composableBuilder(
    column: $table.servidor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get puerto => $composableBuilder(
    column: $table.puerto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuario => $composableBuilder(
    column: $table.usuario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contrasenaEncriptada => $composableBuilder(
    column: $table.contrasenaEncriptada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tieneContrasena => $composableBuilder(
    column: $table.tieneContrasena,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correoDestino => $composableBuilder(
    column: $table.correoDestino,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreRemitente => $composableBuilder(
    column: $table.nombreRemitente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ssl => $composableBuilder(
    column: $table.ssl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get habilitado => $composableBuilder(
    column: $table.habilitado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigSmtpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigSmtpsTable> {
  $$ConfigSmtpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get servidor =>
      $composableBuilder(column: $table.servidor, builder: (column) => column);

  GeneratedColumn<int> get puerto =>
      $composableBuilder(column: $table.puerto, builder: (column) => column);

  GeneratedColumn<String> get usuario =>
      $composableBuilder(column: $table.usuario, builder: (column) => column);

  GeneratedColumn<String> get contrasenaEncriptada => $composableBuilder(
    column: $table.contrasenaEncriptada,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tieneContrasena => $composableBuilder(
    column: $table.tieneContrasena,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correoDestino => $composableBuilder(
    column: $table.correoDestino,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombreRemitente => $composableBuilder(
    column: $table.nombreRemitente,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get ssl =>
      $composableBuilder(column: $table.ssl, builder: (column) => column);

  GeneratedColumn<bool> get habilitado => $composableBuilder(
    column: $table.habilitado,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );
}

class $$ConfigSmtpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigSmtpsTable,
          ConfigSmtp,
          $$ConfigSmtpsTableFilterComposer,
          $$ConfigSmtpsTableOrderingComposer,
          $$ConfigSmtpsTableAnnotationComposer,
          $$ConfigSmtpsTableCreateCompanionBuilder,
          $$ConfigSmtpsTableUpdateCompanionBuilder,
          (
            ConfigSmtp,
            BaseReferences<_$AppDatabase, $ConfigSmtpsTable, ConfigSmtp>,
          ),
          ConfigSmtp,
          PrefetchHooks Function()
        > {
  $$ConfigSmtpsTableTableManager(_$AppDatabase db, $ConfigSmtpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigSmtpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigSmtpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigSmtpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> servidor = const Value.absent(),
                Value<int> puerto = const Value.absent(),
                Value<String> usuario = const Value.absent(),
                Value<String?> contrasenaEncriptada = const Value.absent(),
                Value<bool> tieneContrasena = const Value.absent(),
                Value<String> correoDestino = const Value.absent(),
                Value<String> nombreRemitente = const Value.absent(),
                Value<bool> ssl = const Value.absent(),
                Value<bool> habilitado = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => ConfigSmtpsCompanion(
                id: id,
                servidor: servidor,
                puerto: puerto,
                usuario: usuario,
                contrasenaEncriptada: contrasenaEncriptada,
                tieneContrasena: tieneContrasena,
                correoDestino: correoDestino,
                nombreRemitente: nombreRemitente,
                ssl: ssl,
                habilitado: habilitado,
                actualizadoEn: actualizadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> servidor = const Value.absent(),
                Value<int> puerto = const Value.absent(),
                Value<String> usuario = const Value.absent(),
                Value<String?> contrasenaEncriptada = const Value.absent(),
                Value<bool> tieneContrasena = const Value.absent(),
                Value<String> correoDestino = const Value.absent(),
                Value<String> nombreRemitente = const Value.absent(),
                Value<bool> ssl = const Value.absent(),
                Value<bool> habilitado = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => ConfigSmtpsCompanion.insert(
                id: id,
                servidor: servidor,
                puerto: puerto,
                usuario: usuario,
                contrasenaEncriptada: contrasenaEncriptada,
                tieneContrasena: tieneContrasena,
                correoDestino: correoDestino,
                nombreRemitente: nombreRemitente,
                ssl: ssl,
                habilitado: habilitado,
                actualizadoEn: actualizadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfigSmtpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigSmtpsTable,
      ConfigSmtp,
      $$ConfigSmtpsTableFilterComposer,
      $$ConfigSmtpsTableOrderingComposer,
      $$ConfigSmtpsTableAnnotationComposer,
      $$ConfigSmtpsTableCreateCompanionBuilder,
      $$ConfigSmtpsTableUpdateCompanionBuilder,
      (
        ConfigSmtp,
        BaseReferences<_$AppDatabase, $ConfigSmtpsTable, ConfigSmtp>,
      ),
      ConfigSmtp,
      PrefetchHooks Function()
    >;
typedef $$GastosVariablesTableCreateCompanionBuilder =
    GastosVariablesCompanion Function({
      Value<int> id,
      required String descripcion,
      required double monto,
      required String categoria,
      required DateTime fecha,
      Value<String?> notas,
      Value<DateTime> creadoEn,
    });
typedef $$GastosVariablesTableUpdateCompanionBuilder =
    GastosVariablesCompanion Function({
      Value<int> id,
      Value<String> descripcion,
      Value<double> monto,
      Value<String> categoria,
      Value<DateTime> fecha,
      Value<String?> notas,
      Value<DateTime> creadoEn,
    });

class $$GastosVariablesTableFilterComposer
    extends Composer<_$AppDatabase, $GastosVariablesTable> {
  $$GastosVariablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GastosVariablesTableOrderingComposer
    extends Composer<_$AppDatabase, $GastosVariablesTable> {
  $$GastosVariablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GastosVariablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GastosVariablesTable> {
  $$GastosVariablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);
}

class $$GastosVariablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GastosVariablesTable,
          GastosVariable,
          $$GastosVariablesTableFilterComposer,
          $$GastosVariablesTableOrderingComposer,
          $$GastosVariablesTableAnnotationComposer,
          $$GastosVariablesTableCreateCompanionBuilder,
          $$GastosVariablesTableUpdateCompanionBuilder,
          (
            GastosVariable,
            BaseReferences<
              _$AppDatabase,
              $GastosVariablesTable,
              GastosVariable
            >,
          ),
          GastosVariable,
          PrefetchHooks Function()
        > {
  $$GastosVariablesTableTableManager(
    _$AppDatabase db,
    $GastosVariablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GastosVariablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GastosVariablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GastosVariablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
              }) => GastosVariablesCompanion(
                id: id,
                descripcion: descripcion,
                monto: monto,
                categoria: categoria,
                fecha: fecha,
                notas: notas,
                creadoEn: creadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String descripcion,
                required double monto,
                required String categoria,
                required DateTime fecha,
                Value<String?> notas = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
              }) => GastosVariablesCompanion.insert(
                id: id,
                descripcion: descripcion,
                monto: monto,
                categoria: categoria,
                fecha: fecha,
                notas: notas,
                creadoEn: creadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GastosVariablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GastosVariablesTable,
      GastosVariable,
      $$GastosVariablesTableFilterComposer,
      $$GastosVariablesTableOrderingComposer,
      $$GastosVariablesTableAnnotationComposer,
      $$GastosVariablesTableCreateCompanionBuilder,
      $$GastosVariablesTableUpdateCompanionBuilder,
      (
        GastosVariable,
        BaseReferences<_$AppDatabase, $GastosVariablesTable, GastosVariable>,
      ),
      GastosVariable,
      PrefetchHooks Function()
    >;
typedef $$PresupuestosCategoriasTableCreateCompanionBuilder =
    PresupuestosCategoriasCompanion Function({
      Value<int> id,
      required String categoria,
      required double limiteMensual,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });
typedef $$PresupuestosCategoriasTableUpdateCompanionBuilder =
    PresupuestosCategoriasCompanion Function({
      Value<int> id,
      Value<String> categoria,
      Value<double> limiteMensual,
      Value<DateTime> creadoEn,
      Value<DateTime> actualizadoEn,
    });

class $$PresupuestosCategoriasTableFilterComposer
    extends Composer<_$AppDatabase, $PresupuestosCategoriasTable> {
  $$PresupuestosCategoriasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get limiteMensual => $composableBuilder(
    column: $table.limiteMensual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PresupuestosCategoriasTableOrderingComposer
    extends Composer<_$AppDatabase, $PresupuestosCategoriasTable> {
  $$PresupuestosCategoriasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get limiteMensual => $composableBuilder(
    column: $table.limiteMensual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PresupuestosCategoriasTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresupuestosCategoriasTable> {
  $$PresupuestosCategoriasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<double> get limiteMensual => $composableBuilder(
    column: $table.limiteMensual,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );
}

class $$PresupuestosCategoriasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PresupuestosCategoriasTable,
          PresupuestosCategoria,
          $$PresupuestosCategoriasTableFilterComposer,
          $$PresupuestosCategoriasTableOrderingComposer,
          $$PresupuestosCategoriasTableAnnotationComposer,
          $$PresupuestosCategoriasTableCreateCompanionBuilder,
          $$PresupuestosCategoriasTableUpdateCompanionBuilder,
          (
            PresupuestosCategoria,
            BaseReferences<
              _$AppDatabase,
              $PresupuestosCategoriasTable,
              PresupuestosCategoria
            >,
          ),
          PresupuestosCategoria,
          PrefetchHooks Function()
        > {
  $$PresupuestosCategoriasTableTableManager(
    _$AppDatabase db,
    $PresupuestosCategoriasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresupuestosCategoriasTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PresupuestosCategoriasTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PresupuestosCategoriasTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<double> limiteMensual = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => PresupuestosCategoriasCompanion(
                id: id,
                categoria: categoria,
                limiteMensual: limiteMensual,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String categoria,
                required double limiteMensual,
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
              }) => PresupuestosCategoriasCompanion.insert(
                id: id,
                categoria: categoria,
                limiteMensual: limiteMensual,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PresupuestosCategoriasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PresupuestosCategoriasTable,
      PresupuestosCategoria,
      $$PresupuestosCategoriasTableFilterComposer,
      $$PresupuestosCategoriasTableOrderingComposer,
      $$PresupuestosCategoriasTableAnnotationComposer,
      $$PresupuestosCategoriasTableCreateCompanionBuilder,
      $$PresupuestosCategoriasTableUpdateCompanionBuilder,
      (
        PresupuestosCategoria,
        BaseReferences<
          _$AppDatabase,
          $PresupuestosCategoriasTable,
          PresupuestosCategoria
        >,
      ),
      PresupuestosCategoria,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DeudasTableTableManager get deudas =>
      $$DeudasTableTableManager(_db, _db.deudas);
  $$PagosDeudaTableTableManager get pagosDeuda =>
      $$PagosDeudaTableTableManager(_db, _db.pagosDeuda);
  $$PrestamosTableTableManager get prestamos =>
      $$PrestamosTableTableManager(_db, _db.prestamos);
  $$PagosRecibidosTableTableManager get pagosRecibidos =>
      $$PagosRecibidosTableTableManager(_db, _db.pagosRecibidos);
  $$IngresosTableTableManager get ingresos =>
      $$IngresosTableTableManager(_db, _db.ingresos);
  $$GastosFijosTableTableManager get gastosFijos =>
      $$GastosFijosTableTableManager(_db, _db.gastosFijos);
  $$RecordatoriosTableTableManager get recordatorios =>
      $$RecordatoriosTableTableManager(_db, _db.recordatorios);
  $$ConfigSmtpsTableTableManager get configSmtps =>
      $$ConfigSmtpsTableTableManager(_db, _db.configSmtps);
  $$GastosVariablesTableTableManager get gastosVariables =>
      $$GastosVariablesTableTableManager(_db, _db.gastosVariables);
  $$PresupuestosCategoriasTableTableManager get presupuestosCategorias =>
      $$PresupuestosCategoriasTableTableManager(
        _db,
        _db.presupuestosCategorias,
      );
}
