// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:registering_attendance/Home/creatDoctorOrTA.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../Auth/colors.dart';
import '../core/responsive.dart';
import '../l10n/app_localizations.dart';

class DoctorsListPage extends StatefulWidget {
  const DoctorsListPage({super.key});

  @override
  _DoctorsListPageState createState() => _DoctorsListPageState();
}

class _DoctorsListPageState extends State<DoctorsListPage> {
  final TextEditingController _searchController = TextEditingController();
  final StreamController<List<Map<String, dynamic>>> _doctorsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<int> _statsStreamController =
      StreamController<int>.broadcast();

  String _searchQuery = '';
  String? _authToken;
  Timer? _refreshTimer;

  static const String _doctorsUrl =
      'http://77.83.242.94:5000/api/Admin/list-doctors';

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
    _searchController.addListener(_onSearchChanged);

    // تحديث تلقائي كل 30 ثانية
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_authToken != null) {
        _fetchAllData();
      }
    });
  }

  @override
  void dispose() {
    _doctorsStreamController.close();
    _statsStreamController.close();
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadTokenAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');

    if (_authToken == null) {
      _doctorsStreamController.add([]);
      _statsStreamController.add(0);
      return;
    }

    await _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    if (_authToken == null) return;

    try {
      // جلب البيانات بالتوازي
      await Future.wait([_fetchDoctors()]);
    } catch (e) {
      print('Error fetching all data: $e');
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      final response = await http.get(
        Uri.parse(_doctorsUrl),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> doctorsData = jsonDecode(response.body);
        final doctors = _processDoctorsData(doctorsData);
        _doctorsStreamController.add(doctors);
        _statsStreamController.add(doctors.length);
      } else if (response.statusCode == 401) {
        print('Unauthorized - Token may be expired');
        _doctorsStreamController.add([]);
        _statsStreamController.add(0);
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching doctors: $e');
      _doctorsStreamController.add([]);
      _statsStreamController.add(0);
    }
  }

  Future<void> _deleteDoctorDirectly(String universityCode, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Deletion', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete Dr. $name?\n\nThis will permanently remove their account and access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse(
          'http://77.83.242.94:5000/api/Admin/delete-user/$universityCode',
        ),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor deleted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchAllData();
      } else if (response.statusCode == 500) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot delete this doctor because they are currently assigned to one or more courses. Please unassign them first.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        var errorMsg =
            'Failed to delete doctor (Status: ${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) {
            errorMsg = data['message'];
          } else {
            errorMsg += ' | Body: ${response.body}';
          }
        } catch (_) {
          errorMsg += ' | Raw: ${response.body}';
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _processDoctorsData(List<dynamic> doctorsData) {
    List<Map<String, dynamic>> doctors = [];

    // قائمة ألوان للبطاقات
    final colors = [
      AppColors.primaryColor,
      AppColors.successColor,
      AppColors.accentColor,
      AppColors.secondaryColor,
      AppColors.warningColor,
      AppColors.errorColor,
    ];

    for (int i = 0; i < doctorsData.length; i++) {
      var doctor = doctorsData[i];

      Map<String, dynamic> doctorMap = {
        'id': doctor['id']?.toString() ?? '0',
        'name': doctor['name']?.toString() ?? 'Unknown',
        'email': doctor['email']?.toString() ?? 'No email',
        'universityCode': doctor['universityCode']?.toString() ?? 'No code',
        'avatar': _getAvatarInitials(doctor['name']?.toString() ?? '?'),
        'color': colors[i % colors.length],
      };

      doctors.add(doctorMap);
    }

    return doctors;
  }

  String _getAvatarInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    return '?';
  }

  List<Map<String, dynamic>> _filterDoctors(
    List<Map<String, dynamic>> doctors,
  ) {
    if (_searchQuery.isEmpty) return doctors;

    return doctors.where((doctor) {
      final name = doctor['name'].toString().toLowerCase();
      final email = doctor['email'].toString().toLowerCase();
      final code = doctor['universityCode'].toString().toLowerCase();

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          code.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: AppColors.primaryColor,
              elevation: 4,
              shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.doctorsList,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryColor, AppColors.darkColor],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 20,
                      bottom: 16,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _doctorsStreamController.stream,
                        builder: (context, snapshot) {
                          final doctors = snapshot.data ?? [];
                          final filteredDoctors = _filterDoctors(doctors);

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${filteredDoctors.length} doctor${filteredDoctors.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.autoRefresh30,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppColors.darkColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.searchDoctors,
                              hintStyle: TextStyle(
                                color: AppColors.darkColor.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: AppColors.darkColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.lightColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.clear,
                                size: 20,
                                color: AppColors.accentColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Statistics
                StreamBuilder<int>(
                  stream: _statsStreamController.stream,
                  builder: (context, statsSnapshot) {
                    final doctorsCount = statsSnapshot.data ?? 0;
                    final w = MediaQuery.of(context).size.width;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: w >= 850
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 280,
                                  child: _buildStatCard(
                                    icon: Icons.person,
                                    title: 'Doctors',
                                    value: doctorsCount.toString(),
                                    color: AppColors.primaryColor,
                                    isLoading: !statsSnapshot.hasData,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.person,
                                    title: 'Doctors',
                                    value: doctorsCount.toString(),
                                    color: AppColors.primaryColor,
                                    isLoading: !statsSnapshot.hasData,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),

                // Doctors List
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _doctorsStreamController.stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return _buildLoadingState();
                      }

                      final doctors = snapshot.data!;
                      final filteredDoctors = _filterDoctors(doctors);

                      if (doctors.isEmpty) {
                        return _buildEmptyState();
                      }

                      if (filteredDoctors.isEmpty)
                        return _buildNoResultsState();

                      final w = MediaQuery.of(context).size.width;
                      final cols = w >= 1100
                          ? 3
                          : w >= 850
                          ? 2
                          : 1;

                      if (cols > 1) {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: cols == 3 ? 2.0 : 2.2,
                              ),
                          itemCount: filteredDoctors.length,
                          itemBuilder: (context, index) =>
                              _buildDoctorCard(filteredDoctors[index]),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        itemCount: filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = filteredDoctors[index];
                          return _buildDoctorCard(doctor);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateAccountPage()),
          ).then((value) {
            // تحديث جميع البيانات بعد إضافة دكتور جديد
            if (value == true) {
              _fetchAllData();
            }
          });
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryColor),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.darkColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No doctors available',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.darkColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _fetchAllData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: AppColors.darkColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No doctors found',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkColor.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    ),
                  )
                : Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? '...' : value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showDoctorDetails(doctor),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: (doctor['color'] as Color).withValues(
                    alpha: 0.1,
                  ),
                  radius: 24,
                  child: Text(
                    doctor['avatar'],
                    style: TextStyle(
                      color: doctor['color'] as Color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Doctor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (doctor['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: ${doctor['id']}',
                              style: TextStyle(
                                color: doctor['color'] as Color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        doctor['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 14,
                            color: AppColors.darkColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor['email'],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkColor.withValues(
                                  alpha: 0.7,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.code,
                            size: 14,
                            color: AppColors.darkColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doctor['universityCode'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.darkColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (doctor['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.doctors,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDoctorDetails(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 700 : double.infinity,
            maxHeight:
                MediaQuery.of(context).size.height *
                (Responsive.isMobile(context) ? 0.6 : 0.85),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),

                // Doctor Details
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with Avatar
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: (doctor['color'] as Color)
                                  .withValues(alpha: 0.1),
                              radius: Responsive.isMobile(context) ? 32 : 45,
                              child: Text(
                                doctor['avatar'],
                                style: TextStyle(
                                  color: doctor['color'] as Color,
                                  fontSize: Responsive.isMobile(context)
                                      ? 24
                                      : 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              doctor['name'],
                              style: TextStyle(
                                fontSize: Responsive.isMobile(context)
                                    ? 20
                                    : 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1D3557),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Doctor Profile',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (doctor['color'] as Color).withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ID: ${doctor['id']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: doctor['color'] as Color,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Information Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'General Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D3557),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildDetailItem(
                        icon: Icons.badge_outlined,
                        label: 'University Code',
                        value: doctor['universityCode'],
                        color: doctor['color'] as Color,
                      ),
                      _buildDetailItem(
                        icon: Icons.alternate_email,
                        label: 'Email Address',
                        value: doctor['email'],
                        color: doctor['color'] as Color,
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteDoctorDirectly(
                                  doctor['universityCode'],
                                  doctor['name'],
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE63946),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.darkColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
