import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static pw.ImageProvider? _cachedLogo;

  /// 🔹 Main PDF Generate Function (Optimized)
  static Future<Uint8List> generateOrderPdf({
    required String title,
    required List<Map<String, dynamic>> orders
  }) async {
    final pdf = pw.Document();
    final currentDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // ✅ Status summary calculation
    final Map<String, int> statusCount = {};
    for (var order in orders) {
      final status = (order['status'] ?? 'Unknown').toString().toLowerCase();
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [

            // Header Section
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Centered title
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                // Right-aligned date
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Generated: $currentDate',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Order Summary Table
            pw.Text('Order Summary',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Status',
                            style:  pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Count',
                            style:  pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                            textAlign: pw.TextAlign.center)),
                  ],
                ),
                ...statusCount.entries.map((e) => pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(e.key.toUpperCase(),
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(e.value.toString(),
                            textAlign: pw.TextAlign.center)),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),

            // Orders Table
            pw.Text('Order Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(2),
                5: pw.FlexColumnWidth(2),
                6: pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
                  children: [
                    'Order ID',
                    'Name',
                    'Phone',
                    'Branch',
                    'Status',
                    'Total (Taka)',
                    'Date',
                  ].map((h) {
                    return pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(h,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, color: PdfColors.white)));
                  }).toList(),
                ),
                // Data rows (row by row)
                ...orders.map((order) {
                  final createdAt = order['createdAt'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                      order['createdAt'].millisecondsSinceEpoch)
                      : null;
                  final dateText =
                  createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '-';
                  return pw.TableRow(
                    children: [
                      order['id'] ?? '',
                      order['name'] ?? '',
                      order['phone'] ?? '',
                      order['branch'] ?? '',
                      order['status'] ?? '',
                      (order['total'] ?? 0).toString(),
                      dateText,
                    ].map((cell) {
                      return pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(cell.toString(),
                              style: const pw.TextStyle(fontSize: 10)));
                    }).toList(),
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Generated by Branch Manager',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// 🔹 Export PDF (show print/save dialog)
  static Future<void> exportPdf({
    required String title,
    required List<Map<String, dynamic>> orders,
    String? logoUrl,
  }) async {
    final pdfBytes = await generateOrderPdf(
      title: title,
      orders: orders
    );
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}
