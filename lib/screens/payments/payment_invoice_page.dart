import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';

class PaymentInvoicePage extends StatelessWidget {
  final String userName;
  final String apartment;
  final double amount;
  final String paymentMethod;
  final String feeType;
  final String transactionId;

  const PaymentInvoicePage({
    super.key,
    required this.userName,
    required this.apartment,
    required this.amount,
    required this.paymentMethod,
    required this.feeType,
    required this.transactionId,
  });

  String get _receiptNo =>
      transactionId.replaceAll('TXN', '').substring(0, 6);

  String get _today {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}';
  }

  String get _invoiceRef =>
      '#${transactionId.replaceAll('TXN', '').substring(0, 4)} $_today';

  String _amountInWords(double amt) {
    // Simple words for common amounts; full converter for display
    final int rupees = amt.toInt();
    const ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
      'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String inWords(int n) {
      if (n == 0) return 'Zero';
      if (n < 20) return ones[n];
      if (n < 100) {
        return tens[n ~/ 10] + (n % 10 != 0 ? ' ${ones[n % 10]}' : '');
      }
      if (n < 1000) {
        return '${ones[n ~/ 100]} Hundred'
            '${n % 100 != 0 ? ' ${inWords(n % 100)}' : ''}';
      }
      if (n < 100000) {
        return '${inWords(n ~/ 1000)} Thousand'
            '${n % 1000 != 0 ? ' ${inWords(n % 1000)}' : ''}';
      }
      return '${inWords(n ~/ 100000)} Lakh'
          '${n % 100000 != 0 ? ' ${inWords(n % 100000)}' : ''}';
    }

    return '\u20B9 ${inWords(rupees)} only';
  }

  String _methodLabel(String m) {
    switch (m) {
      case 'gpay':
        return 'Google Pay';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      case 'upi':
        return 'UPI Payment';
      case 'card':
        return 'Credit / Debit Card';
      default:
        return 'Online Payment';
    }
  }

  // ── PDF generation ──────────────────────────────────────────────────────────
  Future<pw.Document> _buildPdf() async {
    final doc = pw.Document();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Title
          pw.Text('RECEIPT',
              style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2)),
          pw.SizedBox(height: 18),

          // Org name
          pw.Text('Community Management',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 4),
          pw.Text(
            '12-B, Sri Niwas, Eagle Garden,\nNasiyanur Road, Erode – 638012,\nTamil Nadu, India.',
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),

          // Reg / PAN
          pw.Text('Regn No :',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('PAN :',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),

          // Receipt No & Date — right-aligned
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Receipt No : $_receiptNo',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: $_today',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // Received from
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 12),
              children: [
                const pw.TextSpan(text: 'Received ( '),
                pw.TextSpan(
                    text: _amountInWords(amount),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                const pw.TextSpan(text: ' ) from '),
                pw.TextSpan(
                    text: userName,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline)),
                const pw.TextSpan(text: ' of Unit '),
                pw.TextSpan(
                    text: apartment,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.green, width: 1),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // Header
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFFB2DFDB)),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('ACCOUNT APPLIED',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('#INVOICE NO & Date',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11),
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('AMOUNT',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11),
                        textAlign: pw.TextAlign.center),
                  ),
                ],
              ),
              // Row
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(feeType,
                        style: const pw.TextStyle(fontSize: 11)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_invoiceRef,
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(amount.toStringAsFixed(2),
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Payment details
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(
                    text: pw.TextSpan(children: [
                  const pw.TextSpan(
                      text: 'Payment           : ',
                      style: pw.TextStyle(fontSize: 11)),
                  pw.TextSpan(
                      text: _methodLabel(paymentMethod),
                      style: const pw.TextStyle(fontSize: 11)),
                ])),
                pw.RichText(
                    text: pw.TextSpan(children: [
                  const pw.TextSpan(
                      text: 'Instrument Bank : ',
                      style: pw.TextStyle(fontSize: 11)),
                  const pw.TextSpan(
                      text: '',
                      style: pw.TextStyle(fontSize: 11)),
                ])),
                pw.RichText(
                    text: pw.TextSpan(children: [
                  const pw.TextSpan(
                      text: 'Reference No.    : ',
                      style: pw.TextStyle(fontSize: 11)),
                  const pw.TextSpan(
                      text: '',
                      style: pw.TextStyle(fontSize: 11)),
                ])),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // Footer
          pw.Text('Transaction is Successful',
              style: const pw.TextStyle(fontSize: 11),
              textAlign: pw.TextAlign.center),
          pw.Text(
              'Electronically Generated, does not require Signature.',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 10),
          pw.RichText(
            textAlign: pw.TextAlign.center,
            text: pw.TextSpan(children: [
              const pw.TextSpan(
                  text: 'Generated by ',
                  style: pw.TextStyle(fontSize: 13)),
              pw.TextSpan(
                  text: 'GENNEXT',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700)),
            ]),
          ),
        ],
      ),
    ));

    return doc;
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Receipt',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download PDF',
            onPressed: () async {
              final doc = await _buildPdf();
              await Printing.layoutPdf(
                onLayout: (_) async => doc.save(),
                name:
                    'Receipt_${_receiptNo}_$_today.pdf',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Title ──
            const Text('RECEIPT',
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Colors.black87)),
            const SizedBox(height: 20),

            // ── Org block ──
            const Text('Community Management',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87)),
            const SizedBox(height: 6),
            const Text(
              '12-B, Sri Niwas, Eagle Garden,\nNasiyanur Road, Erode – 638012,\nTamil Nadu, India.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 13,
                  color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // ── Regn / PAN ──
            const _InfoRow(label: 'Regn No :', value: ''),
            const _InfoRow(label: 'PAN :', value: ''),
            const SizedBox(height: 10),

            // ── Receipt No & Date ──
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _BoldRow(label: 'Receipt No :', value: _receiptNo),
                  _BoldRow(label: 'Date:', value: _today),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1.2),
            const SizedBox(height: 12),

            // ── Received from ──
            Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 14,
                      color: Colors.black87),
                  children: [
                    const TextSpan(text: 'Received ( '),
                    TextSpan(
                        text: _amountInWords(amount),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: ' ) from '),
                    TextSpan(
                        text: userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline)),
                    const TextSpan(text: ' of Unit '),
                    TextSpan(
                        text: apartment,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Table ──
            Table(
              border: TableBorder.all(
                  color: const Color(0xFF26A69A), width: 1.2),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.3),
              },
              children: [
                // Header
                TableRow(
                  decoration: const BoxDecoration(
                      color: Color(0xFFB2DFDB)),
                  children: const [
                    _TableCell(
                        text: 'ACCOUNT\nAPPLIED',
                        bold: true,
                        align: TextAlign.left),
                    _TableCell(
                        text: '#INVOICE\nNO &\nDate',
                        bold: true,
                        align: TextAlign.center),
                    _TableCell(
                        text: 'AMOUNT',
                        bold: true,
                        align: TextAlign.center),
                  ],
                ),
                // Data row
                TableRow(
                  children: [
                    _TableCell(text: feeType, align: TextAlign.left),
                    _TableCell(
                        text: _invoiceRef, align: TextAlign.center),
                    _TableCell(
                        text: amount.toStringAsFixed(2),
                        align: TextAlign.center),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Payment details ──
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                      label: 'Payment',
                      value: _methodLabel(paymentMethod)),
                  const _DetailRow(
                      label: 'Instrument Bank',
                      value: ''),
                  const _DetailRow(label: 'Reference No.', value: ''),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 14),

            // ── Footer ──
            const Text('Transaction is Successful',
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 13,
                    color: Colors.black87)),
            const SizedBox(height: 4),
            const Text(
                'Electronically Generated, does not require Signature.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 11,
                    color: Colors.black45)),
            const SizedBox(height: 16),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 16),
                children: [
                  TextSpan(
                      text: 'Generated by ',
                      style: TextStyle(color: Colors.black87)),
                  TextSpan(
                      text: 'GENNEXT',
                      style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Download button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text('Download Invoice',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brand(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final doc = await _buildPdf();
                  await Printing.layoutPdf(
                    onLayout: (_) async => doc.save(),
                    name: 'Receipt_${_receiptNo}_$_today.pdf',
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('$label $value',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Arial Narrow', fontSize: 12, color: Colors.black54)),
    );
  }
}

class _BoldRow extends StatelessWidget {
  final String label;
  final String value;
  const _BoldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontFamily: 'Arial Narrow', fontSize: 13, color: Colors.black87),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool bold;
  final TextAlign align;
  const _TableCell(
      {required this.text, this.bold = false, required this.align});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
            fontFamily: 'Arial Narrow',
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
            color: bold ? const Color(0xFF00695C) : Colors.black87),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
              fontFamily: 'Arial Narrow', fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
                text: '$label'.padRight(18),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(text: ' : '),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
