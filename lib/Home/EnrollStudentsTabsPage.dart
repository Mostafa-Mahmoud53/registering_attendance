import 'package:flutter/material.dart';
import '../Auth/colors.dart';
import '../l10n/app_localizations.dart';
import 'CourseEnrollmentPage.dart';
import 'EnrollMultiplePage.dart';
import 'BulkCourseEnrollmentPage.dart';

class EnrollStudentsTabsPage extends StatelessWidget {
  final String courseId;
  const EnrollStudentsTabsPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.lightColor2,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          title: Text(
            AppLocalizations.of(context)!.enrollStudentsScreen,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: AppLocalizations.of(context)!.enrollSingle, icon: const Icon(Icons.person_add_alt_1)),
              Tab(text: AppLocalizations.of(context)!.enrollMultiple, icon: const Icon(Icons.group_add)),
              Tab(text: AppLocalizations.of(context)!.excelSheet, icon: const Icon(Icons.upload_file)),
            ],
          ),
          elevation: 0,
        ),
        body: TabBarView(
          children: [
            CourseEnrollmentPage(initialCourseId: courseId, isTab: true),
            EnrollMultiplePage(courseId: courseId, isTab: true),
            BulkCourseEnrollmentPage(initialCourseId: courseId, isTab: true),
          ],
        ),
      ),
    );
  }
}
