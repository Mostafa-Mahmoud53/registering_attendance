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

class TAsListPage extends StatefulWidget {
  const TAsListPage({super.key});

  @override
  _TAsListPageState createState() => _TAsListPageState();
}

class _TAsListPageState extends State<TAsListPage> {
  final TextEditingController _searchController = TextEditingController();
  final StreamController<List<Map<String, dynamic>>> _tasStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, int>> _statsStreamController =
      StreamController<Map<String, int>>.broadcast();

  String _searchQuery = '';
  String? _authToken;
  Timer? _refreshTimer;

  static const String _tasUrl = 'http://77.83.242.94:5000/api/Admin/list-TAs';
  static const String _tasCountUrl =
      'http://77.83.242.94:5000/api/Admin/number-of-tas';

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
    _tasStreamController.close();
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
      _tasStreamController.add([]);
      _statsStreamController.add({'tas': 0});
      return;
    }

    await _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    if (_authToken == null) return;

    try {
      // جلب البيانات بالتوازي
      await Future.wait([_fetchTAs(), _fetchStatistics()]);
    } catch (e) {
      print('Error fetching all data: $e');
    }
  }

  Future<void> _fetchTAs() async {
    try {
      final response = await http.get(
        Uri.parse(_tasUrl),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasData = jsonDecode(response.body);
        final tas = _processTAsData(tasData);
        _tasStreamController.add(tas);
      } else if (response.statusCode == 401) {
        print('Unauthorized - Token may be expired');
        _tasStreamController.add([]);
      } else {
        throw Exception('Failed to load TAs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching TAs: $e');
      _tasStreamController.add([]);
      _statsStreamController.add({'total': 0, 'active': 0});
    }
  }

  Future<void> _deleteTADirectly(String universityCode, String name) async {
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
          'Are you sure you want to delete TA "$name"?\n\nThis will permanently remove their account and access.',
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
            content: Text('TA deleted successfully!'),
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
              'Cannot delete this TA because they are currently assigned to one or more courses. Please unassign them first.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        var errorMsg = 'Failed to delete TA';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) errorMsg = data['message'];
        } catch (_) {}
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

  Future<void> _fetchStatistics() async {
    try {
      // جلب عدد المعيدين
      final tasCountResponse = await http.get(
        Uri.parse(_tasCountUrl),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $_authToken'},
      );

      int tasCount = 0;

      if (tasCountResponse.statusCode == 200) {
        final data = jsonDecode(tasCountResponse.body);
        tasCount = data['count'] ?? 0;
      }

      _statsStreamController.add({'tas': tasCount});
    } catch (e) {
      print('Error fetching statistics: $e');
      _statsStreamController.add({'tas': 0});
    }
  }

  List<Map<String, dynamic>> _processTAsData(List<dynamic> tasData) {
    List<Map<String, dynamic>> tas = [];

    // قائمة ألوان للبطاقات
    final colors = [
      AppColors.primaryColor,
      AppColors.successColor,
      AppColors.accentColor,
      AppColors.secondaryColor,
      AppColors.warningColor,
      AppColors.errorColor,
    ];

    for (int i = 0; i < tasData.length; i++) {
      var ta = tasData[i];

      Map<String, dynamic> taMap = {
        'id': ta['id']?.toString() ?? '0',
        'name': ta['name']?.toString() ?? 'Unknown',
        'email': ta['email']?.toString() ?? 'No email',
        'universityCode': ta['universityCode']?.toString() ?? 'No code',
        'status': 'Active', // يمكنك إضافة status من الـ API إذا كان موجوداً
        'avatar': _getAvatarInitials(ta['name']?.toString() ?? '?'),
        'color': colors[i % colors.length],
      };

      tas.add(taMap);
    }

    return tas;
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

  List<Map<String, dynamic>> _filterTAs(List<Map<String, dynamic>> tas) {
    if (_searchQuery.isEmpty) return tas;

    return tas.where((ta) {
      final name = ta['name'].toString().toLowerCase();
      final email = ta['email'].toString().toLowerCase();
      final code = ta['universityCode'].toString().toLowerCase();

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
                AppLocalizations.of(context)!.teachingAssistantsList,
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
                        stream: _tasStreamController.stream,
                        builder: (context, snapshot) {
                          final tas = snapshot.data ?? [];
                          final filteredTAs = _filterTAs(tas);

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.taCount(filteredTAs.length.toString()),
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
                              hintText: AppLocalizations.of(context)!.searchTAs,
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
                StreamBuilder<Map<String, int>>(
                  stream: _statsStreamController.stream,
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.data ?? {'tas': 0};
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
                                    icon: Icons.school,
                                    title: 'Teaching Assistants',
                                    value: stats['tas']?.toString() ?? '0',
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
                                    icon: Icons.school,
                                    title: 'Teaching Assistants',
                                    value: stats['tas']?.toString() ?? '0',
                                    color: AppColors.primaryColor,
                                    isLoading: !statsSnapshot.hasData,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),

                // TAs List
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _tasStreamController.stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return _buildLoadingState();
                      }

                      final tas = snapshot.data!;
                      final filteredTAs = _filterTAs(tas);

                      if (tas.isEmpty) {
                        return _buildEmptyState();
                      }

                      if (filteredTAs.isEmpty) return _buildNoResultsState();

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
                          itemCount: filteredTAs.length,
                          itemBuilder: (context, index) =>
                              _buildTACard(filteredTAs[index]),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        itemCount: filteredTAs.length,
                        itemBuilder: (context, index) {
                          final ta = filteredTAs[index];
                          return _buildTACard(ta);
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
            Icons.school_outlined,
            size: 80,
            color: AppColors.darkColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No Teaching Assistants available',
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
            'No TAs found',
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

  Widget _buildTACard(Map<String, dynamic> ta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showTADetails(ta),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: (ta['color'] as Color).withValues(
                    alpha: 0.1,
                  ),
                  radius: 24,
                  child: Text(
                    ta['avatar'],
                    style: TextStyle(
                      color: ta['color'] as Color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // TA Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (ta['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: ${ta['id']}',
                          style: TextStyle(
                            color: ta['color'] as Color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        ta['name'],
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
                              ta['email'],
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
                            ta['universityCode'],
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
                              color: (ta['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TA',
                              style: TextStyle(
                                fontSize: 10,
                                color: ta['color'] as Color,
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

  void _showTADetails(Map<String, dynamic> ta) {
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
                (Responsive.isMobile(context) ? 0.65 : 0.85),
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

                // TA Details
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
                              backgroundColor: (ta['color'] as Color)
                                  .withValues(alpha: 0.1),
                              radius: Responsive.isMobile(context) ? 32 : 45,
                              child: Text(
                                ta['avatar'],
                                style: TextStyle(
                                  color: ta['color'] as Color,
                                  fontSize: Responsive.isMobile(context)
                                      ? 24
                                      : 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ta['name'],
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
                              'Teaching Assistant Profile',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ta['status'] == 'Active'
                                        ? AppColors.successColor.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.errorColor.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    ta['status'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: ta['status'] == 'Active'
                                          ? AppColors.successColor
                                          : AppColors.errorColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (ta['color'] as Color).withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'ID: ${ta['id']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: ta['color'] as Color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
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
                        value: ta['universityCode'],
                        color: ta['color'] as Color,
                      ),
                      _buildDetailItem(
                        icon: Icons.alternate_email,
                        label: 'Email Address',
                        value: ta['email'],
                        color: ta['color'] as Color,
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
                                _deleteTADirectly(
                                  ta['universityCode'],
                                  ta['name'],
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
