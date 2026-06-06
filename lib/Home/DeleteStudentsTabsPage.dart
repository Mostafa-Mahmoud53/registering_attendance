import 'package:flutter/material.dart';
import '../Auth/colors.dart';
import '../l10n/app_localizations.dart';
import 'DeleteSingleStudentPage.dart';
import 'DeleteMultipleStudentsPage.dart';
import 'DeleteExcelStudentsPage.dart';

class DeleteStudentsTabsPage extends StatelessWidget {
  const DeleteStudentsTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.lightColor2,
        appBar: AppBar(
          backgroundColor: AppColors.errorColor,
          title: Text(
            AppLocalizations.of(context)!.deleteStudentsScreen,
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
              Tab(text: AppLocalizations.of(context)!.deleteSingle, icon: const Icon(Icons.person_remove_alt_1)),
              Tab(text: AppLocalizations.of(context)!.deleteMultiple, icon: const Icon(Icons.group_remove)),
              Tab(text: AppLocalizations.of(context)!.excelSheet, icon: const Icon(Icons.upload_file)),
            ],
          ),
          elevation: 0,
        ),
        body: const TabBarView(
          children: [
            DeleteSingleStudentPage(isTab: true),
            DeleteMultipleStudentsPage(isTab: true),
            DeleteExcelStudentsPage(isTab: true),
          ],
        ),
      ),
    );
  }
}
