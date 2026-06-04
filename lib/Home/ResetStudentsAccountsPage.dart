import 'package:flutter/material.dart';
import '../Auth/colors.dart';
import '../l10n/app_localizations.dart';
import 'ResetStudentAccountPage.dart';
import 'ResetStudentsForNewYearPage.dart';

class ResetStudentsAccountsPage extends StatelessWidget {
  const ResetStudentsAccountsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.lightColor2,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          title: Text(
            AppLocalizations.of(context)!.resetAccounts,
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
              Tab(text: AppLocalizations.of(context)!.singleAccount, icon: const Icon(Icons.person_off)),
              Tab(text: AppLocalizations.of(context)!.newYearReset, icon: const Icon(Icons.autorenew)),
            ],
          ),
          elevation: 0,
        ),
        body: const TabBarView(
          children: [
            ResetStudentAccountPage(isTab: true),
            ResetStudentsForNewYearPage(isTab: true),
          ],
        ),
      ),
    );
  }
}
