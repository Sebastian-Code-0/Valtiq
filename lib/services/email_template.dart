abstract class EmailTemplate {
  static String _escapeHtml(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

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
<body style="margin:0;padding:0;background-color:#F0F4F8;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="560" cellpadding="0" cellspacing="0" style="max-width:560px;width:100%;">

          <!-- Header -->
          <tr>
            <td style="background-color:#1E3A5F;border-radius:12px 12px 0 0;padding:28px 32px;">
              <span style="font-size:30px;vertical-align:middle;">💰</span>
              <span style="font-family:Arial,Helvetica,sans-serif;font-size:26px;font-weight:bold;color:#FFFFFF;vertical-align:middle;margin-left:10px;letter-spacing:1px;">Valtiq</span>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color:#FFFFFF;padding:32px;border-left:1px solid #E2E8F0;border-right:1px solid #E2E8F0;">
              <p style="font-family:Arial,Helvetica,sans-serif;font-size:15px;line-height:1.7;color:#1A1A2E;margin:0;">
                $htmlContenido
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#F8FAFC;border:1px solid #E2E8F0;border-top:3px solid #2DD4A0;border-radius:0 0 12px 12px;padding:18px 32px;text-align:center;">
              <p style="font-family:Arial,Helvetica,sans-serif;font-size:13px;color:#6B7280;margin:0;">
                Enviado desde <strong style="color:#2DD4A0;">Valtiq</strong> — Tu dinero, tu control
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
