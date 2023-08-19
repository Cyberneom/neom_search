import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_widget.dart';
import 'package:neom_commons/core/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_settings_controller.dart';

class SettingsPrivacyPage extends StatelessWidget {

  const SettingsPrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSettingsController>(
      id: AppPageIdConstants.settingsPrivacy,
      init: AppSettingsController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppConstants.settingsPrivacy.tr),
        body: Obx(()=>Container(
          decoration: AppTheme.appBoxDecoration,
          child: _.isLoading ? Container(
              decoration: AppTheme.appBoxDecoration,
              child: const Center(
                  child: CircularProgressIndicator()
              )
          ) : ListView(
          children: <Widget>[
            HeaderWidget(_.userController.user!.name),
            TitleSubtitleRow(AppTranslationConstants.account.tr, navigateTo: AppRouteConstants.settingsAccount),
            TitleSubtitleRow(AppTranslationConstants.privacyAndPolicy.tr, navigateTo: AppRouteConstants.privacyAndTerms),
            TitleSubtitleRow(AppTranslationConstants.contentPreferences.tr, navigateTo: AppRouteConstants.contentPreferences),
            const HeaderWidget(AppTranslationConstants.general, secondHeader: true,),
            TitleSubtitleRow(AppTranslationConstants.aboutApp.tr, navigateTo: AppRouteConstants.about),
            TitleSubtitleRow(AppTranslationConstants.likeMyWork.tr, subtitle: AppTranslationConstants.buyCoffee.tr,
              onPressed: () => launchUrl(Uri.parse(AppFlavour.getBuyMeACoffeURL(),),)),
            TitleSubtitleRow(AppTranslationConstants.contactUs.tr, subtitle: AppTranslationConstants.contactUsSub.tr,
                onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 100,
                      child: Container(
                        decoration: AppTheme.appBoxDecoration75,
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    MdiIcons.gmail,
                                  ),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.gmail.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    final email = Uri.encodeFull('gigmeoutmx@gmail.com');
                                    final subject = Uri.encodeFull('Regarding Mobile App');
                                    final uri = Uri.parse(
                                      'mailto:$email?subject=$subject',
                                    );
                                    launchUrl(uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                                Text(
                                  AppTranslationConstants.gmail.tr,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    MdiIcons.whatsapp,
                                  ),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.whatsContact.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    CoreUtilities.launchWhatsappURL("5575162623", "¡Hola!");
                                  },
                                ),
                                Text(AppTranslationConstants.whatsapp.tr,),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    MdiIcons.instagram,
                                  ),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.insta.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    launchUrl(Uri.parse('https://instagram.com/gigmeoutmx',),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                                Text(
                                  AppTranslationConstants.insta.tr,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            TitleSubtitleRow(AppTranslationConstants.joinWhats.tr, subtitle: AppTranslationConstants.joinWhatsSub.tr,
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 100,
                      child: Container(
                        decoration: AppTheme.appBoxDecoration75,
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    MdiIcons.whatsapp,
                                  ),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.whatsRock.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    launchUrl(Uri.parse('https://chat.whatsapp.com/FX7m5OJrtodLePy9YtfHo5',),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                                Text(
                                  AppTranslationConstants.whatsRock.tr,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    MdiIcons.whatsapp,
                                  ),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.whatsCommunity.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    launchUrl(Uri.parse('https://chat.whatsapp.com/EtXFBdRIWFf00rDmYNen3n',),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                                Text(
                                  AppTranslationConstants.whatsCommunity.tr,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            //TODO
            _.userController.user!.userRole != UserRole.subscriber ?
            Column(
              children: [
                HeaderWidget(AppTranslationConstants.adminCenter.tr, secondHeader: true),
                TitleSubtitleRow(AppTranslationConstants.createCoupon.tr, navigateTo: AppRouteConstants.createCoupon),
                TitleSubtitleRow(AppTranslationConstants.createSponsor.tr, navigateTo: AppRouteConstants.createSponsor),
                TitleSubtitleRow(AppTranslationConstants.seeAnalytics.tr, navigateTo: AppRouteConstants.analytics),
                _.userController.user!.userRole == UserRole.superAdmin ?
                Column(
                  children: [
                    TitleSubtitleRow(AppTranslationConstants.runAnalyticsJobs.tr, onPressed: _.runAnalyticJobs),
                    TitleSubtitleRow(AppTranslationConstants.runProfileJobs.tr, onPressed: _.runProfileJobs),
                ],) : Container(),
              ],
            ) : Container(),
            TitleSubtitleRow("", showDivider: false, vPadding: 10, subtitle: AppTranslationConstants.settingPrivacyMsg.tr),
          ],
        ),
        ),),
    ),);
  }
}
