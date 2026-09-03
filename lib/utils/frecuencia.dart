/// Factor para llevar un monto "por período" (como lo escribe el usuario en
/// Ingresos/GastosFijos) a su equivalente mensual. El monto siempre
/// representa lo que se recibe/paga EN CADA período, no un total ya
/// mensualizado — este factor es lo que falta multiplicar para comparar
/// fuentes de distinta frecuencia en el mismo total mensual.
///
/// `semanal` usa 52/12 (semanas por año ÷ 12 meses = ~4.33), no 4 — un mes
/// tiene en promedio más de 4 semanas exactas.
double factorMensual(String frecuencia) => switch (frecuencia) {
  'quincenal' => 2,
  'semanal' => 52 / 12,
  _ => 1, // 'mensual' y cualquier valor no reconocido
};
