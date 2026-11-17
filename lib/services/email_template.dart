abstract class EmailTemplate {
  static String _escapeHtml(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;');

  static String build(String asunto, String contenido) {
    final htmlAsunto = _escapeHtml(asunto);
    final htmlContenido = _escapeHtml(contenido).replaceAll('\n', '<br>');

    return '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$htmlAsunto</title>
</head>
<body style="margin:0;padding:0;background-color:#EFE7DA;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="560" cellpadding="0" cellspacing="0" style="max-width:560px;width:100%;">

          <!-- Header -->
          <tr>
            <td style="background-color:#5A1222;border-radius:20px 20px 0 0;padding:24px 32px;">
              <span style="font-family:Arial,Helvetica,sans-serif;font-size:24px;font-weight:bold;color:#EFE7DA;letter-spacing:0.5px;">Valtiq</span>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color:#F4F0E8;padding:32px;border-left:1px solid #DCD2C2;border-right:1px solid #DCD2C2;">
              <p style="font-family:Arial,Helvetica,sans-serif;font-size:15px;line-height:1.7;color:#000000;margin:0;">
                $htmlContenido
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#F4F0E8;border:1px solid #DCD2C2;border-radius:0 0 20px 20px;padding:18px 32px;text-align:center;">
              <p style="font-family:Arial,Helvetica,sans-serif;font-size:13px;color:#63554E;margin:0;">
                Enviado desde <strong style="color:#5A1222;">Valtiq</strong> · Tu dinero, tu control
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>''';
  }
}
