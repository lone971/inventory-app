import 'package:flutter/material.dart';
import 'package:inventoryapp/db/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Future<Map<String, dynamic>> _summaryData;

  @override
  void initState() {
    super.initState();
    _summaryData = _fetchSummaryData();
  }

  Future<Map<String, dynamic>> _fetchSummaryData() async {
    final dailySummary = await DatabaseHelper.instance.getDailySummary();
    final weeklySummary = await DatabaseHelper.instance.getWeeklySummary();
    final monthlySummary = await DatabaseHelper.instance.getMonthlySummary();
    final mostSold = await DatabaseHelper.instance.getMostSoldItem();
    final leastSold = await DatabaseHelper.instance.getLeastSoldItem();
    final mediumSold = await DatabaseHelper.instance.getMediumSoldItem();

    return {
      'daily': dailySummary,
      'weekly': weeklySummary,
      'monthly': monthlySummary,
      'mostSold': mostSold,
      'leastSold': leastSold,
      'mediumSold': mediumSold,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summaryData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No summary data available.'));
          }

          final data = snapshot.data!;
          final pieChartData = _preparePieChartData(data);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              _buildSummarySection('Daily Summary', data['daily']),
              _buildSummarySection('Weekly Summary', data['weekly']),
              _buildSummarySection('Monthly Summary', data['monthly']),
              _buildSummaryItem('Most Sold Item', data['mostSold']),
              _buildSummaryItem('Least Sold Item', data['leastSold']),
              _buildSummaryItem('Medium Sold Item', data['mediumSold']),
              const SizedBox(height: 20),
              _buildPieChart(pieChartData),
            ],
          );
        },
      ),
    );
  }

  Map<String, double> _preparePieChartData(Map<String, dynamic> data) {
    return {
      'Most Sold': data['mostSold']['totalSold'].toDouble(),
      'Least Sold': data['leastSold']['totalSold'].toDouble(),
      'Medium Sold': data['mediumSold']['totalSold'].toDouble(),
    };
  }

  Widget _buildPieChart(Map<String, double> data) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: data.entries.map((entry) {
            return PieChartSectionData(
              value: entry.value,
              title: '${entry.key}\n${entry.value.toStringAsFixed(1)}',
              radius: 50,
            );
          }).toList(),
          sectionsSpace: 0,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildSummarySection(String title, Map<String, dynamic> summary) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          'Total Stock: ${summary['totalStock'] ?? 0}\n'
              'Total Sold: ${summary['totalSold'] ?? 0}\n'
              'Average Price: ${summary['avgPrice'] ?? 0}',
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, Map<String, dynamic> item) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          'Name: ${item['name'] ?? 'N/A'}\n'
              'Total Sold: ${item['totalSold'] ?? 0}',
        ),
      ),
    );
  }
}
