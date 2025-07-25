import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../shared/theme_helper.dart'; // Assumes your ThemeHelper provides necessary styling methods

class AgriSynchProductionLog
    extends
        StatefulWidget {
  const AgriSynchProductionLog({
    super.key,
  });

  @override
  State<
    AgriSynchProductionLog
  >
  createState() => _AgriSynchProductionLogState();
}

class _AgriSynchProductionLogState extends State<AgriSynchProductionLog> {
  final List<Map<String, dynamic>> _logEntries = [];
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _kgController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isDark = false;
  bool _themeLoaded = false;
  String _filterType = 'All'; // All, Today, This Week, This Month
  List<Map<String, dynamic>> _filteredEntries = [];

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadEntries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTheme();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEntries = prefs.getString('production_entries');
    if (savedEntries != null) {
      final List<dynamic> decoded = json.decode(savedEntries);
      setState(() {
        _logEntries.clear();
        _logEntries.addAll(decoded.cast<Map<String, dynamic>>());
        _applyFilters();
      });
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('production_entries', json.encode(_logEntries));
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_logEntries);
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((entry) => 
        entry['product'].toString().toLowerCase()
          .contains(_searchController.text.toLowerCase())).toList();
    }
    
    // Apply date filter
    DateTime now = DateTime.now();
    if (_filterType != 'All') {
      filtered = filtered.where((entry) {
        DateTime entryDate = _parseDate(entry['date']);
        switch (_filterType) {
          case 'Today':
            return _isSameDay(entryDate, now);
          case 'This Week':
            return _isSameWeek(entryDate, now);
          case 'This Month':
            return _isSameMonth(entryDate, now);
          default:
            return true;
        }
      }).toList();
    }
    
    // Sort by date (newest first)
    filtered.sort((a, b) => _parseDate(b['date']).compareTo(_parseDate(a['date'])));
    
    setState(() {
      _filteredEntries = filtered;
    });
  }

  DateTime _parseDate(String dateStr) {
    List<String> parts = dateStr.split('-');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    DateTime startOfWeek = date2.subtract(Duration(days: date2.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
    return date1.isAfter(startOfWeek.subtract(Duration(days: 1))) && 
           date1.isBefore(endOfWeek.add(Duration(days: 1)));
  }

  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  Future<
    void
  >
  _loadTheme() async {
    final darkMode = await ThemeHelper.isDarkModeEnabled();
    setState(
      () {
        _isDark = darkMode;
        _themeLoaded = true;
      },
    );
  }

  void _showAddLogModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeHelper.getCardColor(
        _isDark,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            20,
          ),
        ),
      ),
      isScrollControlled: true,
      builder:
          (
            context,
          ) => Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom:
                  MediaQuery.of(
                    context,
                  ).viewInsets.bottom +
                  20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _productController,
                  keyboardType: TextInputType.text,
                  style: ThemeHelper.getTextStyle(isDark: _isDark),
                  decoration: ThemeHelper.getInputDecoration(
                    hintText: 'Product Name',
                    prefixIcon: Icons.agriculture,
                    isDark: _isDark,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: _kgController,
                  keyboardType: TextInputType.number,
                  style: ThemeHelper.getTextStyle(isDark: _isDark),
                  decoration: ThemeHelper.getInputDecoration(
                    hintText: 'Kilograms',
                    prefixIcon: Icons.scale,
                    isDark: _isDark,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _pickDate,
                  style: ThemeHelper.getTextStyle(isDark: _isDark),
                  decoration: ThemeHelper.getInputDecoration(
                    hintText: 'Select Date',
                    prefixIcon: Icons.calendar_month,
                    isDark: _isDark,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ThemeHelper.getPrimaryButtonStyle(
                    isDark: _isDark,
                  ),
                  onPressed: _addLogEntry,
                  child: const Text(
                    'Add Entry',
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<
    void
  >
  _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(
        2020,
      ),
      lastDate: DateTime(
        2030,
      ),
      builder:
          (
            context,
            child,
          ) {
            return Theme(
              data:
                  Theme.of(
                    context,
                  ).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: ThemeHelper.getHeaderColor(
                        _isDark,
                      ),
                      surface: ThemeHelper.getCardColor(
                        _isDark,
                      ),
                      onSurface: ThemeHelper.getTextColor(
                        _isDark,
                      ),
                    ),
                  ),
              child: child!,
            );
          },
    );

    if (picked !=
        null) {
      setState(
        () {
          _dateController.text = '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
        },
      );
    }
  }

  void _addLogEntry() {
    final String product = _productController.text.trim();
    final String kgText = _kgController.text.trim();
    final String date = _dateController.text.trim();

    if (product.isEmpty || kgText.isEmpty || date.isEmpty) {
      _showSnackBar('All fields are required.');
      return;
    }

    final double? kg = double.tryParse(kgText);
    if (kg == null || kg <= 0) {
      _showSnackBar('Please enter a valid number for kilograms.');
      return;
    }

    setState(() {
      _logEntries.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'product': product,
        'kg': kg,
        'date': date,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _productController.clear();
      _kgController.clear();
      _dateController.clear();
      _applyFilters();
    });

    _saveEntries();
    Navigator.pop(context);
  }

  void _deleteEntry(String id) {
    setState(() {
      _logEntries.removeWhere((entry) => entry['id'] == id);
      _applyFilters();
    });
    _saveEntries();
  }

  void _editEntry(Map<String, dynamic> entry) {
    _productController.text = entry['product'];
    _kgController.text = entry['kg'].toString();
    _dateController.text = entry['date'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeHelper.getCardColor(_isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => _buildEditModal(entry),
    );
  }

  Widget _buildEditModal(Map<String, dynamic> entry) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Edit Entry',
            style: ThemeHelper.getTextStyle(
              isDark: _isDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _productController,
            style: ThemeHelper.getTextStyle(isDark: _isDark),
            decoration: ThemeHelper.getInputDecoration(
              hintText: 'Product Name',
              prefixIcon: Icons.agriculture,
              isDark: _isDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _kgController,
            keyboardType: TextInputType.number,
            style: ThemeHelper.getTextStyle(isDark: _isDark),
            decoration: ThemeHelper.getInputDecoration(
              hintText: 'Kilograms',
              prefixIcon: Icons.scale,
              isDark: _isDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            style: ThemeHelper.getTextStyle(isDark: _isDark),
            decoration: ThemeHelper.getInputDecoration(
              hintText: 'Select Date',
              prefixIcon: Icons.calendar_month,
              isDark: _isDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ThemeHelper.getPrimaryButtonStyle(isDark: _isDark),
                  onPressed: () => _updateEntry(entry['id']),
                  child: const Text('Update'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateEntry(String id) {
    final String product = _productController.text.trim();
    final String kgText = _kgController.text.trim();
    final String date = _dateController.text.trim();

    if (product.isEmpty || kgText.isEmpty || date.isEmpty) {
      _showSnackBar('All fields are required.');
      return;
    }

    final double? kg = double.tryParse(kgText);
    if (kg == null || kg <= 0) {
      _showSnackBar('Please enter a valid number for kilograms.');
      return;
    }

    setState(() {
      final index = _logEntries.indexWhere((entry) => entry['id'] == id);
      if (index != -1) {
        _logEntries[index] = {
          'id': id,
          'product': product,
          'kg': kg,
          'date': date,
          'timestamp': _logEntries[index]['timestamp'], // Keep original timestamp
        };
      }
      _productController.clear();
      _kgController.clear();
      _dateController.clear();
      _applyFilters();
    });

    _saveEntries();
    Navigator.pop(context);
  }

  void _showSnackBar(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        backgroundColor: ThemeHelper.getHeaderColor(
          _isDark,
        ),
        content: Text(
          message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_themeLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(_isDark),
      appBar: AppBar(
        backgroundColor: ThemeHelper.getHeaderColor(_isDark),
        title: Text(
          'Production Log',
          style: ThemeHelper.getHeaderTextStyle(isDark: _isDark),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterType = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Today', child: Text('Today')),
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(value: 'This Month', child: Text('This Month')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: Column(
          children: [
            // Analytics Dashboard
            _buildAnalyticsDashboard(),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _applyFilters(),
                style: ThemeHelper.getTextStyle(isDark: _isDark),
                decoration: ThemeHelper.getInputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icons.search,
                  isDark: _isDark,
                ),
              ),
            ),
            
            // Filter indicator
            if (_filterType != 'All' || _searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    if (_filterType != 'All')
                      Chip(
                        label: Text(_filterType),
                        onDeleted: () {
                          setState(() {
                            _filterType = 'All';
                            _applyFilters();
                          });
                        },
                      ),
                    if (_searchController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Chip(
                          label: Text('Search: ${_searchController.text}'),
                          onDeleted: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            
            // Entries List
            Expanded(
              child: _filteredEntries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredEntries[index];
                        return _buildEntryCard(entry);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeHelper.getHeaderColor(_isDark),
        onPressed: _showAddLogModal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAnalyticsDashboard() {
    if (_logEntries.isEmpty) return const SizedBox.shrink();
    
    final totalEntries = _logEntries.length;
    final totalKg = _logEntries.fold<double>(0, (sum, entry) => sum + (entry['kg'] as num).toDouble());
    final avgKg = totalKg / totalEntries;
    
    // Find most productive crop
    Map<String, double> productTotals = {};
    for (var entry in _logEntries) {
      String product = entry['product'];
      double kg = (entry['kg'] as num).toDouble();
      productTotals[product] = (productTotals[product] ?? 0) + kg;
    }
    String topProduct = productTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: ThemeHelper.getContainerDecoration(isDark: _isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Production Summary',
            style: ThemeHelper.getTextStyle(
              isDark: _isDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Entries',
                  totalEntries.toString(),
                  Icons.list_alt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Production',
                  '${totalKg.toStringAsFixed(1)} kg',
                  Icons.scale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Average per Entry',
                  '${avgKg.toStringAsFixed(1)} kg',
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Top Product',
                  topProduct,
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: ThemeHelper.getHeaderColor(_isDark), size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: ThemeHelper.getTextStyle(
              isDark: _isDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: ThemeHelper.getBodyTextStyle(isDark: _isDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.agriculture,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _logEntries.isEmpty 
                ? 'No production data yet'
                : 'No entries match your filters',
            style: ThemeHelper.getTextStyle(isDark: _isDark),
          ),
          const SizedBox(height: 8),
          Text(
            _logEntries.isEmpty 
                ? 'Tap the + button to add your first entry'
                : 'Try adjusting your search or filters',
            style: ThemeHelper.getBodyTextStyle(isDark: _isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ThemeHelper.getContainerDecoration(isDark: _isDark),
        child: Row(
          children: [
            // Product Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeHelper.getHeaderColor(_isDark).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.agriculture,
                color: ThemeHelper.getHeaderColor(_isDark),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            
            // Entry Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['product'],
                    style: ThemeHelper.getTextStyle(
                      isDark: _isDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry['kg']} kg',
                    style: ThemeHelper.getBodyTextStyle(isDark: _isDark),
                  ),
                  Text(
                    entry['date'],
                    style: ThemeHelper.getBodyTextStyle(isDark: _isDark),
                  ),
                ],
              ),
            ),
            
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editEntry(entry);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(entry);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete ${entry['product']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteEntry(entry['id']);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
