import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'settings_service.dart';

class PdfService {
  final SettingsService _settingsService = SettingsService();

  Future<void> generateAndShowReceipt({
    required String clientName,
    required String amount,
    required String date,
    required String paymentId,
  }) async {
    try {
      // 1. Obtenemos el nombre de la empresa para el recibo
      final companyInfo = await _settingsService.getCompanyInfo();
      final companyName = companyInfo['name'] ?? 'Mi Empresa';

      // 2. Creamos el documento PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey200, width: 1),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // CABECERA
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(companyName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.SizedBox(height: 4),
                          pw.Text('Gestión Financiera Inteligente', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: const pw.BoxDecoration(color: PdfColors.blue100, shape: pw.BoxShape.circle),
                        child: pw.Text('Z', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 20),

                  // TÍTULO
                  pw.Center(
                    child: pw.Text('RECIBO DE PAGO', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: PdfColors.grey800)),
                  ),
                  pw.SizedBox(height: 24),

                  // DETALLES
                  _buildDetailRow('Recibo N°:', paymentId.substring(0, 8).toUpperCase()),
                  _buildDetailRow('Fecha:', date),
                  _buildDetailRow('Recibido de:', clientName),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 20),

                  // MONTO
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text('VALOR RECIBIDO', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                        pw.SizedBox(height: 8),
                        pw.Text('\$ $amount', style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 40),

                  // PIE DE PÁGINA Y FIRMA
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(height: 40, width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1)))),
                          pw.SizedBox(height: 4),
                          pw.Text('Firma Autorizada', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Text('¡Gracias por su pago!', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      // 3. Mostrar la vista previa para imprimir o guardar
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Recibo_${clientName.replaceAll(' ', '_')}_$date.pdf',
      );
    } catch (e) {
      throw Exception('Error al generar PDF: $e');
    }
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}