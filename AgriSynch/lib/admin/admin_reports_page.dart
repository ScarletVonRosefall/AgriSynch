import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../shared/theme_helper.dart';
import 'package:intl/intl.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final ReportService _reportService = ReportService();
  final _themeNotifier = ThemeNotifier();
  String _selectedFilter = 'All';

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
    super.dispose();
  }

  Stream<List<Report>> _getReportsStream() {
    switch (_selectedFilter) {
      case 'Pending':
        return _reportService.getReportsByStatus('pending');
      case 'Reviewed':
        return _reportService.getReportsByStatus('reviewed');
      case 'Resolved':
        return _reportService.getReportsByStatus('resolved');
      case 'Dismissed':
        return _reportService.getReportsByStatus('dismissed');
      case 'Products':
        return _reportService.getReportsByType('product');
      case 'Users':
        return _reportService.getReportsByType('user');
      default:
        return _reportService.getAllReports();
    }
  }

  void _showReportDetails(Report report) {
    final isDarkMode = _themeNotifier.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Icon(
              report.reportType == 'product' ? Icons.inventory : Icons.person,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Report Details',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', report.reportType.toUpperCase(), isDarkMode),
              _buildDetailRow('Reported Item', report.reportedItemName, isDarkMode),
              _buildDetailRow('Category', report.category, isDarkMode),
              _buildDetailRow('Reporter', '${report.reporterName} (${report.reporterEmail})', isDarkMode),
              _buildDetailRow('Status', report.status.toUpperCase(), isDarkMode),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(report.createdAt), isDarkMode),
              const Divider(height: 24),
              Text(
                'Description:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Admin Notes:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.adminNotes!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (report.status == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateReportStatus(report, 'reviewed');
              },
              child: const Text('Mark Reviewed', style: TextStyle(fontFamily: 'Poppins')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateReportStatus(report, 'dismissed');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Dismiss', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
          if (report.status == 'reviewed')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateReportStatus(report, 'resolved');
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF4CAF50)),
              child: const Text('Mark Resolved', style: TextStyle(fontFamily: 'Poppins')),
            ),
          if (report.status == 'dismissed' || report.status == 'resolved')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _reportService.deleteReport(report.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report deleted successfully'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting report: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReportStatus(Report report, String newStatus) async {
    try {
      await _reportService.updateReportStatus(
        reportId: report.id,
        status: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report marked as $newStatus'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return const Color(0xFF4CAF50);
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getReportTypeIcon(String type) {
    return type == 'product' ? Icons.inventory : Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Column(
      children: [
        // Filter Chips with horizontal scrolling
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                'All',
                'Pending',
                'Reviewed',
                'Resolved',
                'Dismissed',
                'Products',
                'Users'
              ].map((filter) {
                final isSelected = _selectedFilter == filter;
                Color selectedColor;
                switch (filter) {
                  case 'Pending':
                    selectedColor = Colors.orange;
                    break;
                  case 'Reviewed':
                    selectedColor = Colors.blue;
                    break;
                  case 'Resolved':
                    selectedColor = Colors.green;
                    break;
                  case 'Dismissed':
                    selectedColor = Colors.grey;
                    break;
                  case 'Products':
                    selectedColor = Colors.purple;
                    break;
                  case 'Users':
                    selectedColor = Colors.teal;
                    break;
                  default:
                    selectedColor = const Color(0xFF00A862);
                }
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: selectedColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Reports List
        Expanded(
          child: StreamBuilder<List<Report>>(
            stream: _getReportsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading reports: ${snapshot.error}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: textColor,
                    ),
                  ),
                );
              }

              final reports = snapshot.data ?? [];

              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: textColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reports found',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(report.status).withOpacity(0.2),
                        child: Icon(
                          _getReportTypeIcon(report.reportType),
                          color: _getStatusColor(report.status),
                        ),
                      ),
                      title: Text(
                        report.reportedItemName,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${report.category} • ${report.reportType}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By ${report.reporterName} • ${DateFormat('MMM dd, yyyy').format(report.createdAt)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(report.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          report.status.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(report.status),
                          ),
                        ),
                      ),
                      onTap: () => _showReportDetails(report),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
