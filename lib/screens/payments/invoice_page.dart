import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class InvoicePage extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const InvoicePage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final org = invoice['organization_name'] ?? 'GenNext';
    final address = invoice['org_address'] ?? 'Erode';
    final pincode = invoice['org_pincode'] ?? '638001';
    final payee = invoice['payee_name'] ?? invoice['user_name'] ?? 'Unknown';
    final apartment = invoice['apartment'] ?? '';
    final amountStr = invoice['amount'] is num
        ? (invoice['amount'] as num).toStringAsFixed(2)
        : (invoice['amount']?.toString() ?? '0.00');
    final invoiceNo = invoice['invoice_no'] ?? '';
    final receiptNo = invoice['receipt_no'] ?? '';
    final date = invoice['invoice_date'] != null
        ? DateTime.parse(invoice['invoice_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '';

    Future<Uint8List> buildPdf() async {
      final pdf = pw.Document();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return [
            pw.Header(
                level: 0,
                child: pw.Text(org,
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.Text('$address - $pincode',
                style: const pw.TextStyle(color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            pw.Text('Receipt No: $receiptNo',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Invoice No: $invoiceNo',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: $date',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Received from: $payee  $apartment',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(context: ctx, data: <List<String>>[
              <String>['Account Applied', 'Amount'],
              <String>[
                invoice['title'] ?? invoice['description'] ?? 'Maintenance Fee',
                '₹$amountStr'
              ],
            ]),
            pw.SizedBox(height: 12),
            pw.Text('Payment Method: ${invoice['payment_method'] ?? ''}'),
            pw.Text('Reference No: ${invoice['reference_no'] ?? ''}'),
          ];
        },
      ));

      return pdf.save();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                final bytes = await buildPdf();
                final fileName =
                    'invoice_${invoiceNo.isNotEmpty ? invoiceNo : DateTime.now().millisecondsSinceEpoch}.pdf';
                await Printing.sharePdf(bytes: bytes, filename: fileName);
                if (Navigator.canPop(context)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invoice ready to save or share')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to generate PDF: ${e.toString()}')),
                );
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 12),
          Text(org,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('$address - $pincode',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Receipt No : $receiptNo',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Invoice No : $invoiceNo',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Date : $date',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 18),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Received from: $payee  $apartment',
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 12),
          Container(
            decoration:
                BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
            child: const Row(children: [
              Expanded(
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Account Applied',
                          style: TextStyle(color: Colors.black54)))),
              Expanded(
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Amount',
                          style: TextStyle(color: Colors.black54)))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                  child: Text(invoice['title'] ??
                      invoice['description'] ??
                      'Maintenance Fee')),
              Expanded(child: Text('₹$amountStr')),
            ]),
          ),
          const SizedBox(height: 20),
          Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('Payment Method: ${invoice['payment_method'] ?? ''}')),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Reference No: ${invoice['reference_no'] ?? ''}')),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () async {
                try {
                  final bytes = await buildPdf();
                  final fileName =
                      'invoice_${invoiceNo.isNotEmpty ? invoiceNo : DateTime.now().millisecondsSinceEpoch}.pdf';
                  await Printing.sharePdf(bytes: bytes, filename: fileName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invoice ready to save or share')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to generate PDF: ${e.toString()}')),
                  );
                }
              },
            ),
          ),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done')),
        ]),
      ),
    );
  }
}
