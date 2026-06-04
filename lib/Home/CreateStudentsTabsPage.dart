import 'package:flutter/material.dart';
import '../Auth/colors.dart';
import '../l10n/app_localizations.dart';
import 'CreateSingleStudentPage.dart';
import 'CreateMultipleStudentsPage.dart';
import 'CreateExcelStudentsPage.dart';

class CreateStudentsTabsPage extends StatelessWidget {
  const CreateStudentsTabsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.lightColor2,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          title: Text(
            AppLocalizations.of(context)!.createStudentsScreen,
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
              Tab(text: AppLocalizations.of(context)!.createSingle, icon: const Icon(Icons.person_add_alt_1)),
              Tab(text: AppLocalizations.of(context)!.createMultiple, icon: const Icon(Icons.group_add)),
              Tab(text: AppLocalizations.of(context)!.excelSheet, icon: const Icon(Icons.upload_file)),
            ],
          ),
          elevation: 0,
        ),
        body: const TabBarView(
          children: [
            CreateSingleStudentPage(isTab: true),
            CreateMultipleStudentsPage(isTab: true),
            CreateExcelStudentsPage(isTab: true),
          ],
        ),
      ),
    );
  }
}
