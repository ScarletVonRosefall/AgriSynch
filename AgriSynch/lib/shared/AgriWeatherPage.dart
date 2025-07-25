import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'weather_helper.dart';
import 'theme_helper.dart';
import 'notification_helper.dart';
import 'AgriNotificationPage.dart';

class AgriWeatherPage extends StatefulWidget {
  const AgriWeatherPage({super.key});

  @override
  State<AgriWeatherPage> createState() => _AgriWeatherPageState();
}

class _AgriWeatherPageState extends State<AgriWeatherPage> {
  bool isDarkMode = false;
  int unreadNotifications = 0;
  WeatherData? currentWeather;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadWeather();
    _loadUnreadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTheme();
    _loadUnreadNotifications();
  }

  void _loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {});
  }

  void _loadUnreadNotifications() async {
    final count = await NotificationHelper.getUnreadCount();
    setState(() {
      unreadNotifications = count;
    });
  }

  void _loadWeather() async {
    setState(() => isLoading = true);
    try {
      final weather = await WeatherHelper.getCurrentWeather();
      setState(() {
        currentWeather = weather;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load weather data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weather Forecast',
                            style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                          ),
                          Text(
                            'Agricultural Weather Info',
                            style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AgriNotificationPage(),
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
                                unreadNotifications > 9 ? '9+' : unreadNotifications.toString(),
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weather Content
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: isDarkMode ? Colors.white : const Color(0xFF00C853),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading weather data...',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : currentWeather == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 64,
                              color: isDarkMode ? Colors.white54 : Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Weather data unavailable',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: isDarkMode ? Colors.white54 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadWeather,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadWeather(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCurrentWeatherCard(),
                              const SizedBox(height: 20),
                              _buildWeatherDetails(),
                              const SizedBox(height: 20),
                              _buildFarmingAdvice(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    if (currentWeather == null) return Container();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode 
              ? [const Color(0xFF2E7D32), const Color(0xFF4CAF50)]
              : [const Color(0xFF00C853), const Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                WeatherHelper.getWeatherIcon(currentWeather!.icon),
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentWeather!.temperatureString,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentWeather!.capitalizedDescription,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    currentWeather!.location,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.thermostat, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Feels like ${currentWeather!.feelsLikeString}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(DateTime.now()),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    if (currentWeather == null) return Container();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Details',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Humidity',
                  '${currentWeather!.humidity}%',
                  Icons.water_drop,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Wind Speed',
                  '${currentWeather!.windSpeed.toStringAsFixed(1)} km/h',
                  Icons.air,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Feels Like',
                  currentWeather!.feelsLikeString,
                  Icons.thermostat,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Updated',
                  DateFormat('HH:mm').format(DateTime.now()),
                  Icons.update,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmingAdvice() {
    if (currentWeather == null) return Container();

    final advice = WeatherHelper.getWeatherAdvice(
      currentWeather!.description,
      currentWeather!.temperature,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? const Color(0xFF1B5E20).withOpacity(0.3)
            : const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
              ? const Color(0xFF4CAF50)
              : const Color(0xFF81C784),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.agriculture,
                color: isDarkMode ? Colors.white : const Color(0xFF2E7D32),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Farming Advice',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advice,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }
}
