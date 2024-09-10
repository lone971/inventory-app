// lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

import '../models/item.dart';
import '../db/database_helper.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Item> _items = [];
  bool _isLoading = true;

  // Set up logging
  final Logger _logger = Logger('Dashboard');

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  // Fetch items from the database
  Future<void> _fetchItems() async {
    try {
      List<Map<String, dynamic>> maps = await _dbHelper.queryAll();
      List<Item> items = maps.map((map) => Item.fromMap(map)).toList();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error fetching items: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load items')),
      );
    }
  }

  // Export data to PDF
  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final List<List<String>> items = [];
    final Map<int, Map<String, dynamic>> summary = {};

    // Prepare item rows and calculate summary
    for (var item in _items) {
      final totalProfit = item.sold * (item.sellingPrice - item.buyingPrice);
      final row = [
        item.id.toString(),
        item.name,
        'KSH ${item.buyingPrice.toStringAsFixed(2)}',
        'KSH ${item.sellingPrice.toStringAsFixed(2)}',
        item.stock.toString(),
        item.sold.toString(),
        'KSH ${totalProfit.toStringAsFixed(2)}',
      ];
      items.add(row);

      // Update summary
      if (summary.containsKey(item.id)) {
        summary[item.id]!['totalSold'] += item.sold;
        summary[item.id]!['totalProfit'] += totalProfit;
      } else {
        summary[item.id] = {
          'name': item.name,
          'totalSold': item.sold,
          'totalProfit': totalProfit,
        };
      }
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(16.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Item Summary Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    'ID',
                    'Name',
                    'Buying Price',
                    'Selling Price',
                    'Stock',
                    'Sold',
                    'Total Profit'
                  ],
                  data: items,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration:
                  pw.BoxDecoration(color: PdfColors.blueGrey),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.symmetric(
                      vertical: 4, horizontal: 8),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Overall Summary',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                for (var entry in summary.entries)
                  pw.Text(
                      'Item: ${entry.value['name']} - Total Sold: ${entry.value['totalSold']} - Total Profit: KSH ${entry.value['totalProfit'].toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );

    try {
      final outputFile = await _getOutputFile();
      final file = File(outputFile);
      await file.writeAsBytes(await pdf.save());

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF exported successfully')),
      );
    } catch (e) {
      _logger.severe('Error exporting PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF')),
      );
    }
  }

  // Get the output file path
  Future<String> _getOutputFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/inventory_summary_report.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            tooltip: 'Export to PDF',
            onPressed: _exportToPdf,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchItems,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(child: Text('No items found'))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Buying Price')),
                  DataColumn(label: Text('Selling Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Sold')),
                  DataColumn(label: Text('Total Profit')),
                ],
                rows: _items.map((item) {
                  final totalProfit = item.sold *
                      (item.sellingPrice - item.buyingPrice);
                  return DataRow(
                    cells: [
                      DataCell(Text(item.id.toString())),
                      DataCell(Text(item.name)),
                      DataCell(Text(
                          'KSH ${item.buyingPrice.toStringAsFixed(2)}')),
                      DataCell(Text(
                          'KSH ${item.sellingPrice.toStringAsFixed(2)}')),
                      DataCell(Text(item.stock.toString())),
                      DataCell(Text(item.sold.toString())),
                      DataCell(Text(
                          'KSH ${totalProfit.toStringAsFixed(2)}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          _buildSummaryTable(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Add New Item',
        onPressed: () {
          // Navigate to Add Item screen (to be implemented)
        },
      ),
    );
  }

  // Build the summary table
  Widget _buildSummaryTable() {
    final Map<int, Map<String, dynamic>> summary = {};

    // Calculate summary
    for (var item in _items) {
      final totalProfit = item.sold * (item.sellingPrice - item.buyingPrice);

      if (summary.containsKey(item.id)) {
        summary[item.id]!['totalSold'] += item.sold;
        summary[item.id]!['totalProfit'] += totalProfit;
      } else {
        summary[item.id] = {
          'name': item.name,
          'totalSold': item.sold,
          'totalProfit': totalProfit,
        };
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          for (var entry in summary.entries)
            Text(
              'Item: ${entry.value['name']} - Total Sold: ${entry.value['totalSold']} - Total Profit: KSH ${entry.value['totalProfit'].toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }
}
