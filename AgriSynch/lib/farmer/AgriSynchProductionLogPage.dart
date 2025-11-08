import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../shared/theme_helper.dart'; // Assumes your ThemeHelper provides necessary styling methods

class AgriSynchProductionLog extends StatefulWidget {
  const AgriSynchProductionLog({super.key});

  @override
  State<AgriSynchProductionLog> createState() => _AgriSynchProductionLogState();
}

class _AgriSynchProductionLogState extends State<AgriSynchProductionLog> {
  final List<Map<String, dynamic>> _logEntries = [];
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _kgController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final _themeNotifier = ThemeNotifier();
  bool _mounted = false;
  bool _isInitialized = false;
  String _filterType = 'All'; // All, Today, This Week, This Month
  List<Map<String, dynamic>> _filteredEntries = [];

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _initializeData();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mounted = false;
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    _productController.dispose();
    _kgController.dispose();
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      return;
    }
  }

  Future<void> _loadEntries() async {
    if (!_mounted) return;
    
    try {
      final loadedEntries = await _loadEntriesFromStorage()
          .timeout(const Duration(seconds: 5));
      
      if (!_mounted) return;
      
      setState(() {
        _logEntries.clear();
        _logEntries.addAll(loadedEntries);
        _applyFilters();
      });
    } catch (e) {
      if (!_mounted) return;
      _showError('Failed to load entries');
    }
  }

  Future<void> _saveEntries() async {
    if (!_mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      
      if (!_mounted) return;
      
      await prefs.setString('production_entries', json.encode(_logEntries))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      if (!_mounted) return;
      _showError('Failed to save entries');
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_logEntries);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (entry) => entry['product'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
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
    filtered.sort(
      (a, b) => _parseDate(b['date']).compareTo(_parseDate(a['date'])),
    );

    setState(() {
      _filteredEntries = filtered;
    });
  }

  DateTime _parseDate(String dateStr) {
    List<String> parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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

  Future<void> _initializeData() async {
    if (!_mounted) return;
    
    try {
      // Load entries
      final loadedEntries = await _loadEntriesFromStorage().timeout(const Duration(seconds: 5));

      if (!_mounted) return;

      setState(() {
        _logEntries.clear();
        _logEntries.addAll(loadedEntries);
        _applyFilters();
      });
    } catch (e) {
      if (!_mounted) return;
      _showError('Failed to load data');
    }
  }

  Future<List<Map<String, dynamic>>> _loadEntriesFromStorage() async {
    try {
      if (!_mounted) return [];
      
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      final savedEntries = prefs.getString('production_entries');
      if (savedEntries != null) {
        final List<dynamic> decoded = json.decode(savedEntries);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Handle load error
      if (_mounted) {
        _showError('Failed to load entries');
      }
    }
    return [];
  }

  void _showError(String message) {
    if (!_mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            if (_mounted) _initializeData();
          },
        ),
      ),
    );
  }

  void _showAddLogModal() {
    final _isDark = _themeNotifier.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeHelper.getCardColor(_isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
            ElevatedButton(
              style: ThemeHelper.getPrimaryButtonStyle(isDark: _isDark),
              onPressed: _addLogEntry,
              child: const Text('Add Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final _isDark = _themeNotifier.isDarkMode;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeHelper.getHeaderColor(_isDark),
              surface: ThemeHelper.getCardColor(_isDark),
              onSurface: ThemeHelper.getTextColor(_isDark),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      });
    }
  }

  Future<void> _addLogEntry() async {
    if (!_mounted) return;
    
    final String product = _productController.text.trim();
    final String kgText = _kgController.text.trim();
    final String date = _dateController.text.trim();

    if (product.isEmpty || kgText.isEmpty || date.isEmpty) {
      if (!_mounted) return;
      _showError('All fields are required.');
      return;
    }

    final double? kg = double.tryParse(kgText);
    if (kg == null || kg <= 0) {
      if (!_mounted) return;
      _showError('Please enter a valid number for kilograms.');
      return;
    }

    try {
      final newEntry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'product': product,
        'kg': kg,
        'date': date,
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _logEntries.add(newEntry);
        _applyFilters();
      });

      await _saveEntries();
      
      if (!_mounted) return;
      
      _productController.clear();
      _kgController.clear();
      _dateController.clear();
      Navigator.pop(context);
      
    } catch (e) {
      if (!_mounted) return;
      _showError('Failed to add entry');
      await _loadEntries(); // Revert changes
    }
  }

  Future<void> _deleteEntry(String id) async {
    if (!_mounted) return;
    
    try {
      setState(() {
        _logEntries.removeWhere((entry) => entry['id'] == id);
        _applyFilters();
      });
      
      await _saveEntries();
    } catch (e) {
      if (!_mounted) return;
      _showError('Failed to delete entry');
      
      // Revert the deletion
      await _loadEntries();
    }
  }

  void _editEntry(Map<String, dynamic> entry) {
    final _isDark = _themeNotifier.isDarkMode;
    if (!_mounted) return;
    
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
    final _isDark = _themeNotifier.isDarkMode;
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

  Future<void> _updateEntry(String id) async {
    if (!_mounted) return;
    
    final String product = _productController.text.trim();
    final String kgText = _kgController.text.trim();
    final String date = _dateController.text.trim();

    if (product.isEmpty || kgText.isEmpty || date.isEmpty) {
      if (!_mounted) return;
      _showError('All fields are required.');
      return;
    }

    final double? kg = double.tryParse(kgText);
    if (kg == null || kg <= 0) {
      if (!_mounted) return;
      _showError('Please enter a valid number for kilograms.');
      return;
    }

    try {
      final index = _logEntries.indexWhere((entry) => entry['id'] == id);
      if (index == -1) {
        if (!_mounted) return;
        _showError('Entry not found');
        return;
      }

      final originalEntry = Map<String, dynamic>.from(_logEntries[index]);
      setState(() {
        _logEntries[index] = {
          'id': id,
          'product': product,
          'kg': kg,
          'date': date,
          'timestamp': originalEntry['timestamp'], // Keep original timestamp
        };
        _applyFilters();
      });

      await _saveEntries();
      
      if (!_mounted) return;
      
      _productController.clear();
      _kgController.clear();
      _dateController.clear();
      Navigator.pop(context);
      
    } catch (e) {
      if (!_mounted) return;
      _showError('Failed to update entry');
      await _loadEntries(); // Revert changes
    }
  }

  @override
  Widget build(BuildContext context) {
    final _isDark = _themeNotifier.isDarkMode;
    
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(_isDark),
      body: Column(
        children: [
          // Green header matching home page
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: _isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Production Log',
                            style: ThemeHelper.getHeaderTextStyle(isDark: _isDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track your harvest and production',
                            style: ThemeHelper.getSubHeaderTextStyle(isDark: _isDark),
                          ),
                        ],
                      ),
                    ),
                    // Filter button
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() {
                          _filterType = value;
                          _applyFilters();
                        });
                      },
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'All', child: Text('All')),
                        const PopupMenuItem(value: 'Today', child: Text('Today')),
                        const PopupMenuItem(value: 'This Week', child: Text('This Week')),
                        const PopupMenuItem(
                          value: 'This Month',
                          child: Text('This Month'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar inside header
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _applyFilters(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadEntries,
              child: Column(
                children: [
                  // Analytics Dashboard
                  _buildAnalyticsDashboard(),

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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeHelper.getHeaderColor(_isDark),
        foregroundColor: Colors.white,
  onPressed: _showAddLogModal,
  child: const Icon(Icons.add),
),
);
  }

  Widget _buildAnalyticsDashboard() {
    final _isDark = _themeNotifier.isDarkMode;
    if (_logEntries.isEmpty) return const SizedBox.shrink();

    final totalEntries = _logEntries.length;
    final totalKg = _logEntries.fold<double>(
      0,
      (sum, entry) => sum + (entry['kg'] as num).toDouble(),
    );
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
                child: _buildStatCard('Top Product', topProduct, Icons.star),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final _isDark = _themeNotifier.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF37474F) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
    final _isDark = _themeNotifier.isDarkMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.agriculture, size: 64, color: _isDark ? const Color(0xFF757575) : Colors.grey[400]),
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
    final _isDark = _themeNotifier.isDarkMode;
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
