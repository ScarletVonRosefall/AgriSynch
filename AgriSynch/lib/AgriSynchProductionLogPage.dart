import 'package:flutter/material.dart';
import 'Theme_Helper.dart'; // Assumes your ThemeHelper provides necessary styling methods

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

class _AgriSynchProductionLogState
    extends
        State<
          AgriSynchProductionLog
        > {
  final List<
    Map<
      String,
      dynamic
    >
  >
  _logEntries = [];
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _kgController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _isDark = false;
  bool _themeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
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

    if (product.isEmpty ||
        kgText.isEmpty ||
        date.isEmpty) {
      _showSnackBar(
        'All fields are required.',
      );
      return;
    }

    final int? kg = int.tryParse(
      kgText,
    );
    if (kg ==
        null) {
      _showSnackBar(
        'Please enter a valid number for kilograms.',
      );
      return;
    }

    setState(
      () {
        _logEntries.add(
          {
            'product': product,
            'kg': kg,
            'date': date,
          },
        );
        _productController.clear();
        _kgController.clear();
        _dateController.clear();
      },
    );

    Navigator.pop(
      context,
    );
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
  Widget build(
    BuildContext context,
  ) {
    if (!_themeLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(
        _isDark,
      ),
      appBar: AppBar(
        backgroundColor: ThemeHelper.getHeaderColor(
          _isDark,
        ),
        title: Text(
          'Production Log',
          style: ThemeHelper.getHeaderTextStyle(
            isDark: _isDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _logEntries.isEmpty
          ? Center(
              child: Text(
                'No production data yet.',
                style: ThemeHelper.getTextStyle(
                  isDark: _isDark,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(
                16,
              ),
              itemCount: _logEntries.length,
              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final entry = _logEntries[index];
                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      padding: const EdgeInsets.all(
                        16,
                      ),
                      decoration: ThemeHelper.getContainerDecoration(
                        isDark: _isDark,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product: ${entry['product']}',
                            style: ThemeHelper.getTextStyle(
                              isDark: _isDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            'Weight: ${entry['kg']} kg',
                            style: ThemeHelper.getBodyTextStyle(
                              isDark: _isDark,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            'Date: ${entry['date']}',
                            style: ThemeHelper.getBodyTextStyle(
                              isDark: _isDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeHelper.getHeaderColor(
          _isDark,
        ),
        onPressed: _showAddLogModal,
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}
