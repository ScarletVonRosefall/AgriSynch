import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../utils/pdf_download.dart';
import 'package:open_file/open_file.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../shared/currency_helper.dart';

// Custom formatter for decimal numbers - more efficient than regex
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  final int maxDigits;

  DecimalTextInputFormatter({
    this.decimalRange = 2,
    this.maxDigits = 10, // Max 10 digits before decimal (9,999,999,999.99)
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // Allow empty string
    if (newText.isEmpty) {
      return newValue;
    }

    // Quick validation - only allow digits and one decimal point
    if (!RegExp(r'^[\d.]*$').hasMatch(newText)) {
      return oldValue;
    }

    // Check for multiple decimal points
    if (newText.indexOf('.') != newText.lastIndexOf('.')) {
      return oldValue;
    }

    // Check decimal places
    if (newText.contains('.')) {
      final parts = newText.split('.');
      if (parts[1].length > decimalRange) {
        return oldValue;
      }
      // Check digits before decimal
      if (parts[0].length > maxDigits) {
        return oldValue;
      }
    } else {
      // Check total digits
      if (newText.length > maxDigits) {
        return oldValue;
      }
    }

    return newValue;
  }
}

class AgriFinances extends StatefulWidget {
  const AgriFinances({super.key});

  @override
  State<AgriFinances> createState() => _AgriFinancesState();
}

class _AgriFinancesState extends State<AgriFinances> {
  final _themeNotifier = ThemeNotifier();
  int unreadNotifications = 0;
  String currencySymbol = '₱';

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> _cachedFilteredTransactions = [];
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double profit = 0.0;
  
  // Cache chart data to avoid recalculation on every build
  List<BarChartGroupData> _cachedBarChartData = [];
  List<PieChartSectionData> _cachedPieChartData = [];
  List<String> _cachedBarChartLabels = [];

  // Keys for capturing chart widgets as images for PDF export
  final GlobalKey _barChartKey = GlobalKey();
  final GlobalKey _pieChartKey = GlobalKey();

  String selectedFilter = 'All';
  String selectedTimeRange = 'This Month';

  final List<String> categories = [
    'All',
    'Sales',
    'Equipment',
    'Seeds',
    'Fertilizer',
    'Labor',
    'Fuel',
    'Maintenance',
    'Other',
  ];

  final List<String> timeRanges = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'All Time',
  ];

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _loadTransactions();
    _loadUnreadNotifications();
    _loadCurrency();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload currency when returning to this page
    _loadCurrency();
  }

  void _loadCurrency() async {
    currencySymbol = await CurrencyHelper.getCurrentCurrencySymbol();
    setState(() {});
  }

  void _loadUnreadNotifications() async {
    final count = await NotificationHelper.getUnreadCount();
    setState(() {
      unreadNotifications = count;
    });
  }

  void _loadTransactions() async {
    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    try {
      // Load from Firestore with timeout - limit to recent 100 transactions for performance
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 10));

      transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'] ?? doc.id,
          'type': data['type'] ?? 'income',
          'category': data['category'] ?? '',
          'amount': (data['amount'] ?? 0.0).toDouble(),
          'description': data['description'] ?? '',
          'date': data['date'] ?? DateTime.now().toIso8601String(),
          'orderId': data['orderId'],
        };
      }).toList();

      // Also save to local storage for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('financial_transactions', json.encode(transactions));
      
      debugPrint('✅ Loaded ${transactions.length} transactions from Firestore');
    } catch (e) {
      debugPrint('❌ Error loading from Firestore: $e');
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final savedTransactions = prefs.getString('financial_transactions');
      if (savedTransactions != null) {
        transactions = List<Map<String, dynamic>>.from(
          json.decode(savedTransactions),
        );
        debugPrint('✅ Loaded ${transactions.length} transactions from local storage (fallback)');
      }
    }
    
    _calculateTotals();
    setState(() {});
  }

  void _saveTransactions() async {
    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    try {
      // Save to Firestore - update or create each transaction with timeout
      for (var transaction in transactions) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('transactions')
            .doc(transaction['id'])
            .set({
              'id': transaction['id'],
              'type': transaction['type'],
              'category': transaction['category'],
              'amount': transaction['amount'],
              'description': transaction['description'],
              'date': transaction['date'],
              'orderId': transaction['orderId'],
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
      }
      
      debugPrint('✅ Saved ${transactions.length} transactions to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving to Firestore: $e');
    }

    // Also save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('financial_transactions', json.encode(transactions));
  }

  void _calculateTotals() {
    // Cache filtered transactions to avoid recalculating multiple times
    _cachedFilteredTransactions = _getFilteredTransactions();
    
    totalIncome = _cachedFilteredTransactions
        .where((t) => t['type'] == 'income')
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));
    totalExpenses = _cachedFilteredTransactions
        .where((t) => t['type'] == 'expense')
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));
    profit = totalIncome - totalExpenses;
    
    // Cache chart data to prevent expensive recalculations during build
    _cachedBarChartData = _generateBarChartData();
    _cachedBarChartLabels = _generateBarChartLabels();
    _cachedPieChartData = _generatePieChartData();
  }

  Future<void> _exportPdf() async {
    try {
      // Small UI hint
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing PDF...')),
        );
      }

      // Allow a short delay for painting
      await Future.delayed(const Duration(milliseconds: 200));

      // Prepare lightweight vector summaries (no screenshots) to speed up PDF creation
      // Category totals for bar-like summary
      final Map<String, double> categoryTotals = {};
      double totalIncomeForPie = 0.0;
      double totalExpenseForPie = 0.0;

      for (var t in _cachedFilteredTransactions) {
        final cat = (t['category'] ?? 'Other').toString();
        final amt = (t['amount'] ?? 0.0) as double;
        final type = (t['type'] ?? 'income').toString();

        categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + amt;

        if (type == 'income') {
          totalIncomeForPie += amt;
        } else {
          totalExpenseForPie += amt;
        }
      }

      final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topCategories = sortedCategories.take(6).toList();
      // maxCategoryValue not required when rendering text-based bars

      // Load a unicode-capable font from assets (Poppins is included in project assets)
      pw.Font ttf;
      try {
        final fontData = await rootBundle.load('assets/fonts/Poppins/Poppins-Medium.ttf');
        ttf = pw.Font.ttf(fontData);
      } catch (e) {
        debugPrint('⚠️ Could not load Poppins font for PDF ($e) — falling back to default');
        ttf = pw.Font.helvetica();
      }

      // Determine report owner and small metadata to include in the PDF
      final currentUser = FirebaseAuth.instance.currentUser;
      final String reportUser = currentUser?.displayName ?? currentUser?.email ?? currentUser?.uid ?? 'Unknown User';

      // Generate pie PNG bytes in-memory (async) so the PDF MultiPage builder stays synchronous
      Uint8List pieBytes = Uint8List(0);
      try {
        final double totalPieGen = totalIncomeForPie + totalExpenseForPie;
        if (totalPieGen > 0) {
          const int size = 200;
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          final paint = Paint()..style = PaintingStyle.fill;
          final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

          final double sweepIncome = (totalIncomeForPie / totalPieGen) * 2 * math.pi;
          final double start = -math.pi / 2;

          paint.color = const Color(0xFF4CAF50); // income green
          canvas.drawArc(rect, start, sweepIncome, true, paint);

          paint.color = const Color(0xFFE53935); // expense red
          canvas.drawArc(rect, start + sweepIncome, 2 * math.pi - sweepIncome, true, paint);

          // center white circle for donut look
          paint.color = const Color(0xFFFFFFFF);
          canvas.drawCircle(Offset(size / 2, size / 2), size * 0.28, paint);

          final picture = recorder.endRecording();
          final ui.Image img = await picture.toImage(size, size);
          final ByteData? bd = await img.toByteData(format: ui.ImageByteFormat.png);
          if (bd != null) pieBytes = bd.buffer.asUint8List();
        }
      } catch (e) {
        debugPrint('⚠️ Pie generation failed: $e');
        pieBytes = Uint8List(0);
      }

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          build: (context) {
            final List<pw.Widget> content = [];

            content.add(
              pw.Header(
                level: 0,
                child: pw.Text('AgriSynch - Financial Report', style: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
            );

            content.add(pw.Paragraph(text: 'Generated: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}', style: pw.TextStyle(font: ttf)));
            content.add(pw.Paragraph(text: 'User: $reportUser', style: pw.TextStyle(font: ttf)));
            content.add(pw.SizedBox(height: 4));
            content.add(pw.Bullet(text: 'Filter: $selectedFilter', style: pw.TextStyle(font: ttf)));
            content.add(pw.Bullet(text: 'Time Range: $selectedTimeRange', style: pw.TextStyle(font: ttf)));
            content.add(pw.Bullet(text: 'Items: ${_cachedFilteredTransactions.length}', style: pw.TextStyle(font: ttf)));
            content.add(pw.SizedBox(height: 6));
            content.add(pw.Paragraph(text: 'Summary', style: pw.TextStyle(font: ttf)));
            content.add(pw.Bullet(text: 'Total Income: $currencySymbol${totalIncome.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf)));
            content.add(pw.Bullet(text: 'Total Expenses: $currencySymbol${totalExpenses.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf)));
            content.add(pw.Bullet(text: 'Net Profit: $currencySymbol${profit.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf)));
            content.add(pw.SizedBox(height: 12));

            // Charts (images) if available
            // Lightweight vector summaries instead of screenshots.
            if (topCategories.isNotEmpty) {
              content.add(pw.Header(
                level: 2,
                text: 'Category Summary',
                padding: pw.EdgeInsets.only(top: 8, bottom: 4),
                textStyle: pw.TextStyle(font: ttf, fontSize: 14),
              ));

              final double maxBarWidth = 220.0;
              final double baseValue = topCategories.first.value == 0 ? 1.0 : topCategories.first.value;

              for (final e in topCategories) {
                final barWidth = (e.value / baseValue) * maxBarWidth;
                content.add(pw.Padding(
                  padding: pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(children: [
                    pw.Expanded(flex: 3, child: pw.Text(e.key, style: pw.TextStyle(font: ttf, fontSize: 10))),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                        flex: 6,
                        child: pw.Container(
                            height: 12,
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Container(width: barWidth, height: 12, color: PdfColors.blue))),
                    pw.SizedBox(width: 8),
                    pw.Flexible(child: pw.Text('${e.value.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10))),
                  ]),
                ));
              }
            } else {
              content.add(pw.Text('No category data available', style: pw.TextStyle(font: ttf)));
            }

            // Income / Expense summary — render a simple pie chart (generated in-memory)
            final double totalPie = totalIncomeForPie + totalExpenseForPie;
            content.add(pw.SizedBox(height: 8));
            content.add(pw.Header(
              level: 2,
              text: 'Income / Expense Distribution',
              padding: pw.EdgeInsets.only(top: 8, bottom: 4),
              textStyle: pw.TextStyle(font: ttf, fontSize: 14),
            ));

            if (totalPie > 0) {
              if (pieBytes.isNotEmpty) {
                content.add(pw.Row(children: [
                  pw.Container(width: 170, child: pw.Center(child: pw.Image(pw.MemoryImage(pieBytes), width: 150, height: 150))),
                  pw.SizedBox(width: 12),
                  pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('Income: $currencySymbol${totalIncomeForPie.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 12)),
                    pw.SizedBox(height: 6),
                    pw.Text('Expense: $currencySymbol${totalExpenseForPie.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 12)),
                    pw.SizedBox(height: 12),
                    pw.Text('Income ${(totalIncomeForPie / totalPie * 100).toStringAsFixed(1)}%', style: pw.TextStyle(font: ttf, fontSize: 12)),
                    pw.SizedBox(height: 6),
                    pw.Text('Expense ${(totalExpenseForPie / totalPie * 100).toStringAsFixed(1)}%', style: pw.TextStyle(font: ttf, fontSize: 12)),
                  ]))
                ]));
              } else {
                // Fallback to textual summary if image generation failed
                content.add(pw.Text('Income: $currencySymbol${totalIncomeForPie.toStringAsFixed(2)} — Expense: $currencySymbol${totalExpenseForPie.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf)));
              }
            } else {
              content.add(pw.Text('No income/expense data available', style: pw.TextStyle(font: ttf)));
            }

            // Transactions table (text) — use cached filtered transactions
            if (_cachedFilteredTransactions.isNotEmpty) {
              content.add(pw.SizedBox(height: 12));
              content.add(pw.Text('Transactions', style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold)));
              content.add(pw.SizedBox(height: 6));

              // Build table data
              final headers = ['Date', 'Type', 'Category', 'Amount', 'Description'];
              final data = _cachedFilteredTransactions.map((t) {
                String dateStr = '';
                try {
                  dateStr = DateFormat.yMMMd().format(DateTime.parse(t['date']));
                } catch (_) {
                  dateStr = t['date']?.toString() ?? '';
                }
                final type = (t['type'] ?? '').toString();
                final category = (t['category'] ?? '').toString();
                final amount = (t['amount'] ?? 0.0) as double;
                final description = (t['description'] ?? '').toString();
                return [dateStr, type, category, '$currencySymbol${amount.toStringAsFixed(2)}', description];
              }).toList();

              content.add(
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: data,
                  headerStyle: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(font: ttf, fontSize: 9),
                  cellAlignment: pw.Alignment.centerLeft,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2), // Date
                    1: const pw.FlexColumnWidth(0.8), // Type
                    2: const pw.FlexColumnWidth(1.2), // Category
                    3: const pw.FlexColumnWidth(0.9), // Amount
                    4: const pw.FlexColumnWidth(2.5), // Description
                  },
                ),
              );
            }

            return content;
          },
        ),
      );

      final pdfBytes = await doc.save();
      try {
        await Printing.layoutPdf(onLayout: (format) => pdfBytes);
      } on MissingPluginException catch (e) {
        debugPrint('⚠️ Printing plugin missing: $e — falling back to saving file');
          try {
            final savedPath = await savePdfBytes(
              'agrisynch_financial_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
              pdfBytes,
            );

            if (mounted) {
                if (savedPath != null && savedPath.isNotEmpty) {
                  // Try to open the saved PDF automatically (mobile/desktop)
                  try {
                    final result = await OpenFile.open(savedPath);
                    if (result.type == ResultType.done) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opened PDF: $savedPath')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF saved to $savedPath')),
                      );
                    }
                  } catch (e) {
                    // If OpenFile isn't available or fails, fall back to showing saved path
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF saved to $savedPath')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF download started')),
                  );
                }
            }
          } catch (e) {
            debugPrint('❌ Failed to save or download PDF fallback: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save/download PDF: $e')),
              );
            }
          }
      } catch (e) {
        // Other printing errors
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    List<Map<String, dynamic>> filtered = transactions;

    // Filter by category
    if (selectedFilter != 'All') {
      filtered = filtered
          .where((t) => t['category'] == selectedFilter)
          .toList();
    }

    // Filter by time range
    final now = DateTime.now();
    DateTime startDate;

    switch (selectedTimeRange) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        return filtered; // All Time
    }

    filtered = filtered.where((t) {
      final transactionDate = DateTime.parse(t['date']);
      return transactionDate.isAfter(
        startDate.subtract(const Duration(days: 1)),
      );
    }).toList();

    return filtered;
  }

  void _addTransaction() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: const AddTransactionDialog(),
      ),
      barrierDismissible: true,
    );

    if (result != null) {
      transactions.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': result['type'],
        'category': result['category'],
        'amount': result['amount'],
        'description': result['description'],
        'date': DateTime.now().toIso8601String(),
      });

      _saveTransactions();
      _calculateTotals();
      setState(() {});

      // Create notification
      final isIncome = result['type'] == 'income';
      await NotificationHelper.addNotification(
        title: isIncome ? 'Income Added' : 'Expense Added',
        message:
            '${isIncome ? "Income" : "Expense"} of $currencySymbol${result['amount'].toStringAsFixed(2)} has been recorded.',
        type: 'system',
      );
      _loadUnreadNotifications();
    }
  }

  void _deleteTransaction(String id) async {
    // Remove from local list
    transactions.removeWhere((t) => t['id'] == id);
    
    // Delete from Firestore
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('transactions')
            .doc(id)
            .delete()
            .timeout(const Duration(seconds: 10));
        debugPrint('✅ Deleted transaction $id from Firestore');
      } catch (e) {
        debugPrint('❌ Error deleting from Firestore: $e');
      }
    }
    
    // Update local storage
    _saveTransactions();
    _calculateTotals();
    setState(() {});
  }

  void _editTransaction(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => EditTransactionDialog(
        transaction: transaction,
        onSave: (updatedTransaction) {
          // Update the transaction in local list
          final index = transactions.indexWhere((t) => t['id'] == transaction['id']);
          if (index != -1) {
            transactions[index] = updatedTransaction;
            _saveTransactions();
            _calculateTotals();
            setState(() {});
          }
        },
      ),
    );
  }

  List<BarChartGroupData> _generateBarChartData() {
    final categoryTotals = <String, double>{};

    // Use cached filtered transactions for better performance
    for (var transaction in _cachedFilteredTransactions) {
      final category = transaction['category'] as String;
      final amount = transaction['amount'] as double;

      if (categoryTotals.containsKey(category)) {
        categoryTotals[category] = categoryTotals[category]! + amount;
      } else {
        categoryTotals[category] = amount;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(6).map((entry) {
      final index = sortedCategories.indexOf(entry);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: _getBarColor(index),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }
  
  List<BarChartGroupData> _getBarChartData() {
    return _cachedBarChartData;
  }

  Color _getBarColor(int index) {
    final colors = [
      const Color(0xFF00C853),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF607D8B),
    ];
    return colors[index % colors.length];
  }

  List<PieChartSectionData> _generatePieChartData() {
    final incomeByCategory = <String, double>{};
    final expenseByCategory = <String, double>{};

    // Use cached filtered transactions for better performance
    for (var transaction in _cachedFilteredTransactions) {
      final category = transaction['category'] as String;
      final amount = transaction['amount'] as double;
      final type = transaction['type'] as String;

      if (type == 'income') {
        incomeByCategory[category] = (incomeByCategory[category] ?? 0) + amount;
      } else {
        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) + amount;
      }
    }

    final sections = <PieChartSectionData>[];
    int incomeColorIndex = 0;
    int expenseColorIndex = 0;

    // Add income sections (green shades)
    for (var entry in incomeByCategory.entries) {
      sections.add(
        PieChartSectionData(
          color: _getIncomePieColor(incomeColorIndex++),
          value: entry.value,
          title: '$currencySymbol${entry.value.toStringAsFixed(0)}',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Add expense sections (red shades)
    for (var entry in expenseByCategory.entries) {
      sections.add(
        PieChartSectionData(
          color: _getExpensePieColor(expenseColorIndex++),
          value: entry.value,
          title: '$currencySymbol${entry.value.toStringAsFixed(0)}',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }
  
  List<PieChartSectionData> _getPieChartData() {
    return _cachedPieChartData;
  }

  Color _getIncomePieColor(int index) {
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF66BB6A), // Light Green
      const Color(0xFF81C784), // Lighter Green
      const Color(0xFFA5D6A7), // Pale Green
      const Color(0xFF2E7D32), // Dark Green
    ];
    return colors[index % colors.length];
  }

  Color _getExpensePieColor(int index) {
    final colors = [
      const Color(0xFFEF5350), // Red
      const Color(0xFFF44336), // Light Red
      const Color(0xFFE57373), // Lighter Red
      const Color(0xFFEF9A9A), // Pale Red
      const Color(0xFFC62828), // Dark Red
    ];
    return colors[index % colors.length];
  }

  List<String> _generateBarChartLabels() {
    final categoryTotals = <String, double>{};

    // Use cached filtered transactions for better performance
    for (var transaction in _cachedFilteredTransactions) {
      final category = transaction['category'] as String;
      final amount = transaction['amount'] as double;

      if (categoryTotals.containsKey(category)) {
        categoryTotals[category] = categoryTotals[category]! + amount;
      } else {
        categoryTotals[category] = amount;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(6).map((entry) => entry.key).toList();
  }
  
  List<String> _getBarChartLabels() {
    return _cachedBarChartLabels;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final backgroundColor = ThemeHelper.getBackgroundColor(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
              width: double.infinity,
              decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Text(
                        'Finances',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const Spacer(),
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AgriNotificationPage(),
                                  ),
                                );
                                _loadUnreadNotifications();
                              },
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          if (unreadNotifications > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadNotifications > 9
                                      ? '9+'
                                      : unreadNotifications.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your farm income and expenses',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Financial Summary Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Income',
                      totalIncome,
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Expenses',
                      totalExpenses,
                      Icons.trending_down,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Profit',
                      profit,
                      profit >= 0 ? Icons.attach_money : Icons.money_off,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Add Transaction Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addTransaction,
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: const Text(
                    'Add Transaction',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Charts Section
            if (transactions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Financial Analytics',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bar Chart (wrapped for PDF capture)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RepaintBoundary(
                  key: _barChartKey,
                  child: Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                                  color: Colors.black.withAlpha((0.1 * 255).round()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending by Category',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: () {
                                final data = _getBarChartData();
                                if (data.isEmpty) return 100.0;
                                final maxValue = data.map((e) => e.barRods.first.toY).reduce((a, b) => a > b ? a : b);
                                return (maxValue * 1.2).toDouble();
                              }(),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => isDarkMode
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.grey[800]!,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final labels = _getBarChartLabels();
                                    final label = groupIndex < labels.length
                                        ? labels[groupIndex]
                                        : 'Unknown';
                                    return BarTooltipItem(
                                      '$label\n$currencySymbol${rod.toY.toStringAsFixed(2)}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      final labels = _getBarChartLabels();
                                      final index = value.toInt();
                                      if (index >= 0 && index < labels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            labels[index].length > 8
                                                ? '${labels[index].substring(0, 8)}...'
                                                : labels[index],
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black54,
                                              fontSize: 10,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                          return Text(
                                            '$currencySymbol${value.toInt()}',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black54,
                                              fontSize: 10,
                                              fontFamily: 'Poppins',
                                            ),
                                          );
                                        },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: _getBarChartData(),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 50,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: isDarkMode
                                        ? Colors.white12
                                        : Colors.grey[300]!,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Pie Chart (wrapped for PDF capture)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RepaintBoundary(
                  key: _pieChartKey,
                  child: Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                                color: Colors.black.withAlpha((0.1 * 255).round()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income vs Expenses Distribution',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: _getPieChartData(),
                                    pieTouchData: PieTouchData(
                                      touchCallback:
                                          (FlTouchEvent event, pieTouchResponse) {
                                            // Handle touch events if needed
                                          },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLegendItem(
                                      'Total Income',
                                      totalIncome,
                                      Colors.green,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLegendItem(
                                      'Total Expenses',
                                      totalExpenses,
                                      Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLegendItem(
                                      'Net Profit',
                                      profit,
                                      Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],

            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedFilter,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      dropdownColor: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFilter = value!;
                          _calculateTotals();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedTimeRange,
                      decoration: InputDecoration(
                        labelText: 'Time Range',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      dropdownColor: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                      ),
                      items: timeRanges.map((range) {
                        return DropdownMenuItem(
                          value: range,
                          child: Text(range),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTimeRange = value!;
                          _calculateTotals();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Transactions List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '${_cachedFilteredTransactions.length} items',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _cachedFilteredTransactions.isEmpty
                      ? SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 64,
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: isDarkMode
                                        ? Colors.white54
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Use the "Add Transaction" button above to get started',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.white38
                                        : Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: _cachedFilteredTransactions
                              .take(20) // Show only 20 most recent to improve performance
                              .map((transaction) => _buildTransactionCard(transaction))
                              .toList(),
                        ),
                ],
              ),
            ),

            // Add some bottom padding
            // Export PDF button (bottom of page)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 20),
                  label: const Text(
                    'Export / Print PDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ), // Close Column
      ), // Close SingleChildScrollView
    ); // Close Scaffold
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$currencySymbol${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final isIncome = transaction['type'] == 'income';
    
    // Cache these expensive operations
    final amount = transaction['amount'] as double;
    final description = transaction['description'] ?? 'No description';
    final category = transaction['category'] as String;
    
    // Parse date once
    DateTime? date;
    try {
      date = DateTime.parse(transaction['date']);
    } catch (_) {
      date = DateTime.now();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? const Color(0x1A4CAF50)
              : const Color(0x1AF44336),
          child: Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            color: isIncome ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          description,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$category • ${DateFormat.MMMd().format(date)}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'}$currencySymbol${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                color: isDarkMode ? Colors.white54 : Colors.grey,
                size: 20,
              ),
              onPressed: () => _editTransaction(transaction),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: isDarkMode ? Colors.white54 : Colors.grey,
                size: 20,
              ),
              onPressed: () => _deleteTransaction(transaction['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                '$currencySymbol${value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String selectedType = 'income';
  String selectedCategory = 'Sales';
  final _themeNotifier = ThemeNotifier();

  final Map<String, List<String>> categoryMap = {
    'income': ['Sales', 'Subsidies', 'Other Income'],
    'expense': [
      'Equipment',
      'Seeds',
      'Fertilizer',
      'Labor',
      'Fuel',
      'Maintenance',
      'Other Expense',
    ],
  };

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        maxWidth: MediaQuery.of(context).size.width * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF3C3C3C)
                  : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.white24 : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF00C853),
                          ),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? const Color(0xFF3C3C3C)
                            : const Color(0xFFF8F8F8),
                      ),
                      dropdownColor: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Income'),
                        ),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Expense'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                          selectedCategory = categoryMap[selectedType]!.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.white24 : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF00C853),
                          ),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? const Color(0xFF3C3C3C)
                            : const Color(0xFFF8F8F8),
                      ),
                      dropdownColor: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                      ),
                      items: categoryMap[selectedType]!.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        DecimalTextInputFormatter(
                          decimalRange: 2,
                          maxDigits: 6, // Max 200,000.00 (200k)
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (amount > 200000) {
                          return 'Maximum amount is ₱200,000';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Amount (₱)',
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.white24 : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF00C853),
                          ),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? const Color(0xFF3C3C3C)
                            : const Color(0xFFF8F8F8),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(
                          Icons.description,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.white24 : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF00C853),
                          ),
                        ),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: isDarkMode
                            ? const Color(0xFF3C3C3C)
                            : const Color(0xFFF8F8F8),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF3C3C3C)
                  : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'type': selectedType,
                          'category': selectedCategory,
                          'amount': double.parse(_amountController.text),
                          'description': _descriptionController.text,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditTransactionDialog extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Function(Map<String, dynamic>) onSave;

  const EditTransactionDialog({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String selectedType;
  late String selectedCategory;
  final _themeNotifier = ThemeNotifier();

  final Map<String, List<String>> categoryMap = {
    'income': ['Sales', 'Subsidies', 'Other Income'],
    'expense': [
      'Equipment',
      'Seeds',
      'Fertilizer',
      'Labor',
      'Fuel',
      'Maintenance',
      'Other Expense',
    ],
  };

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    selectedType = widget.transaction['type'] ?? 'income';
    selectedCategory = widget.transaction['category'] ?? 'Sales';
    _amountController = TextEditingController(
      text: widget.transaction['amount'].toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction['description'] ?? '',
    );
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
      title: Text(
        'Edit Transaction',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type dropdown
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.grey,
                    ),
                  ),
                ),
                items: ['income', 'expense'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedType = value;
                      selectedCategory = categoryMap[value]!.first;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              // Category dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.grey,
                    ),
                  ),
                ),
                items: (categoryMap[selectedType] ?? []).map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.grey,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.grey,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedTransaction = {
                ...widget.transaction,
                'type': selectedType,
                'category': selectedCategory,
                'amount': double.parse(_amountController.text),
                'description': _descriptionController.text,
              };
              widget.onSave(updatedTransaction);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

