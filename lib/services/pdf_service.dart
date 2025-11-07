import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  /// 🔹 Order List Page PDF Generator
  static Future<void> exportOrdersListPdf({
    required String title,
    required List<Map<String, dynamic>> orders,
  }) async {
    final pdf = pw.Document();
    final currentDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // ✅ Count order status summary
    final Map<String, int> statusCount = {};
    for (var order in orders) {
      final status = (order['status'] ?? 'unknown').toString().toLowerCase();
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    final totalCount = statusCount.values.fold<int>(0, (sum, v) => sum + v);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // 🔹 Header
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Generated: $currentDate',
                style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.SizedBox(height: 20),

          // 🔹 Order Summary Table
          pw.Text('Order Summary',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.7),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Status',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white),
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Count',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white),
                        textAlign: pw.TextAlign.center),
                  ),
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
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('TOTAL',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(totalCount.toString(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // 🔹 Order Details Table
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
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                children: [
                  'Order ID',
                  'Name',
                  'Phone',
                  'Branch',
                  'Status',
                  'Total (Taka)',
                  'Date'
                ]
                    .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white))))
                    .toList(),
              ),

              // Data Rows
              ...orders.map((order) {
                final createdAt = order['createdAt'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                    order['createdAt'].millisecondsSinceEpoch)
                    : null;
                final dateText = createdAt != null
                    ? DateFormat('dd MMM yyyy').format(createdAt)
                    : '-';

                return pw.TableRow(
                  children: [
                    order['id'] ?? '',
                    order['name'] ?? '',
                    order['phone'] ?? '',
                    order['branch'] ?? '',
                    order['status'] ?? '',
                    (order['total'] ?? 0).toString(),
                    dateText,
                  ]
                      .map((cell) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(cell.toString(),
                        style: const pw.TextStyle(fontSize: 10)),
                  ))
                      .toList(),
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
              style:
              const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    // 🔹 Export / Print PDF
    await Printing.layoutPdf(onLayout: (format) async => await pdf.save());
  }

  /// 🔹 Order Details Page PDF Generator
  static Future<void> exportOrderDetailsPdf({
    required Map<String, dynamic> order,
  }) async {
    final pdf = pw.Document();
    final currentDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final dateText = order['createdAt'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(
        DateTime.fromMillisecondsSinceEpoch(
            order['createdAt'].millisecondsSinceEpoch))
        : '-';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text('Order Details',
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Generated: $currentDate',
                  style: const pw.TextStyle(fontSize: 10)),
            ),
            pw.SizedBox(height: 10),

            // 🔹 Section Heading
            pw.Text('Order Information:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold
                )),
            pw.Divider(),
            pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(2), // Order ID
          1: pw.FlexColumnWidth(2), // Name
          2: pw.FlexColumnWidth(2), // Phone
          3: pw.FlexColumnWidth(2), // Status
          4: pw.FlexColumnWidth(2), // Branch
          5: pw.FlexColumnWidth(2), // Date
        },

        children: [
          // 🔹 Header Row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.indigo),
            children: [
              'Order ID',
              'Name',
              'Phone',
              'Status',
              'Branch',
              'Date',
            ].map((header) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 12,
                ),
                textAlign: pw.TextAlign.center,
              ),
            )).toList(),
          ),

          // 🔹 Data Row
          pw.TableRow(
            children: [
              order['id'] ?? (order['userId'] ?? '-'),
              order['shipping']?['name'] ?? '-',
              order['shipping']?['phone'] ?? '-',
              order['status'] ?? '-',
              order['branch'] ?? '-',
              dateText,
            ].map((cell) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                cell.toString(),
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            )).toList(),
          ),
        ],
      ),

            pw.SizedBox(height: 20),

            pw.Text(
              'Payment Information:',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3), // Payment Method
                1: pw.FlexColumnWidth(3), // Transaction ID
                2: pw.FlexColumnWidth(2), // Payment Status
              },
              children: [
                // 🔹 Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                  children: ['Payment Method', 'Transaction ID', 'Payment Status']
                      .map(
                        (header) => pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        header,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  )
                      .toList(),
                ),

                // 🔹 Data Row with AUTO Logic
                pw.TableRow(
                  children: [
                    // ✅ Payment Method
                    order['paymentMethod'] ?? 'Cash on Delivery',

                    // ✅ Transaction ID (auto if missing)
                    order['transactionId'] ??
                        (order['paymentMethod'] == 'Cash on Delivery'
                            ? '-'
                            : 'TXN${order['userId'] ?? ''}'),

                    // ✅ Payment Status (auto if missing)
                    order['paymentStatus'] ??
                        (order['paymentMethod'] == 'Cash on Delivery'
                            ? 'Pending'
                            : 'Paid'),
                  ].map(
                        (cell) => pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        cell.toString(),
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Text('Products Information:',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 6),
            if (order['items'] != null && order['items'] is List)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                    children: ['Product', 'Quantity', 'Price (Taka)', 'Total (Taka)']
                        .map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(h,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ))
                        .toList(),
                  ),
                  ...List<Map<String, dynamic>>.from(order['items']).map((item) {
                    final total =
                        (item['price'] ?? 0) * (item['quantity'] ?? 1);
                    return pw.TableRow(
                      children: [
                        item['title'] ??
                        item['name'] ?? '',
                        '${item['quantity']}',
                        '${item['price']}',
                        '$total'
                      ]
                          .map((v) => pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(v.toString(),
                            style:
                            const pw.TextStyle(fontSize: 10)),
                      ))
                          .toList(),
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total: ${(order['total'] ?? 0).toString()} Taka',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Generated by System',
                style:
                const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
