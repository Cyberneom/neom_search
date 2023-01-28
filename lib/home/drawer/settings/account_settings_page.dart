import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'account_settings_controller.dart';
import 'widgets/header_widget.dart';
import 'widgets/settings_row_widget.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountSettingsController>(
      init: AccountSettingsController(),
      builder: (_) => Scaffold(
      appBar: AppBarChild(title: AppTranslationConstants.accountSettings.tr),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: ListView(
        children: <Widget>[
          HeaderWidget(AppTranslationConstants.loginAndSecurity.tr),
          SettingRowWidget(
            AppTranslationConstants.username.tr,
            subtitle: _.userController.user!.name,
          ),
          const Divider(height: 0),
          SettingRowWidget(
            AppTranslationConstants.phone.tr,
            subtitle: _.userController.user!.phoneNumber.isEmpty ? AppTranslationConstants.notSpecified.tr : "${_.userController.user!.countryCode}${_.userController.user!.phoneNumber}",
          ),
          SettingRowWidget(
            AppTranslationConstants.emailAddress.tr,
            subtitle: _.userController.user!.email,
          ),
          const Divider(height: 0),
          // SettingRowWidget("Security"),
          // HeaderWidget('Data and Permission', secondHeader: true,),
          // SettingRowWidget("Country"),
          // SettingRowWidget("Your Gigmeout data"),
          //SettingRowWidget("Apps and sessions"),
          _.userController.user?.profiles.length == 1 ? Container() :
          SettingRowWidget(AppTranslationConstants.removeProfile.tr,  textColor: AppColor.ceriseRed,
            onPressed: (){
              showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      backgroundColor: AppColor.main50,
                      title: Text(AppTranslationConstants.removeThisAccount.tr),
                      children: <Widget>[
                        SimpleDialogOption(
                          child: Text(
                            AppTranslationConstants.remove.tr,
                            style: const TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Get.toNamed(AppRouteConstants.profileRemove, arguments: [AppRouteConstants.accountSettings, AppRouteConstants.profileRemove]);
                          },
                        ),
                        SimpleDialogOption(
                          child: Text(
                            AppTranslationConstants.cancel.tr,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  }
              );

            },
          ),
          SettingRowWidget(AppTranslationConstants.removeAccount.tr,  textColor: AppColor.ceriseRed,
              onPressed: (){
                showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        backgroundColor: AppColor.main50,
                        title: Text(AppTranslationConstants.removeThisAccount.tr),
                        children: <Widget>[
                          SimpleDialogOption(
                            child: Text(
                              AppTranslationConstants.remove.tr,
                              style: const TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              Get.toNamed(AppRouteConstants.accountRemove, arguments: [AppRouteConstants.accountSettings, AppRouteConstants.accountRemove]);
                            },
                          ),
                          SimpleDialogOption(
                            child: Text(
                              AppTranslationConstants.cancel.tr,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    }
                    );

             },
          ),
        ],
      ),
    ),),
    );
  }
}
