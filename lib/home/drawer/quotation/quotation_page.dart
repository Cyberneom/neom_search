import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/ui/widgets/header_widget.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_item_size.dart';

import 'quotation_controller.dart';

class QuotationPage extends StatelessWidget {

  const QuotationPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetBuilder<QuotationController>(
      init: QuotationController(),
      id: AppPageIdConstants.quotation,
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppTranslationConstants.appItemQuotation.tr),
        body:  Container(
        decoration: AppTheme.appBoxDecoration,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            HeaderWidget(AppTranslationConstants.appItemDuration.tr, secondHeader: true),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: AppTheme.fullWidth(context)/2,
                      child: TextFormField(
                        controller: _.itemDurationController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d{0,2}")),
                          LengthLimitingTextInputFormatter(5),
                        ],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            filled: true,
                            hintText: AppTranslationConstants.specifyAppItemDuration.tr,
                            labelText: AppTranslationConstants.appItemDuration.tr,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            )),
                        onChanged: (text) {
                          _.setAppItemDuration();
                        },
                      ),
                    ),
                    DropdownButton<String>(
                      items: AppItemSize.values.map((AppItemSize size) {
                        return DropdownMenuItem<String>(
                          value: size.value,
                          child: SizedBox(
                            width: AppTheme.fullWidth(context)/4,
                            child: Text(size.value.toUpperCase().tr,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? chosenSize) {
                        _.setAppItemSize(chosenSize!);
                      },
                      value: _.itemToQuote.size.value ?? AppItemSize.a4.value,
                      elevation: 20,
                      dropdownColor: AppColor.getMain(),
                      underline: Container(),
                    ),
                  ],
                )
            ),
            _.itemToQuote.size == AppItemSize.a4 ?
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                AppTranslationConstants.appSizeWarningMsg.tr,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w400),
              )
            ) : Container(),
            HeaderWidget(AppTranslationConstants.appItemQty.tr, secondHeader: true),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: AppTheme.fullWidth(context)/2,
                      child: TextFormField(
                        controller: _.itemQtyController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d{0,2}")),
                          LengthLimitingTextInputFormatter(5),
                        ],
                        keyboardType: TextInputType.number,
                        enabled: _.isPhysical,
                        decoration: InputDecoration(
                            filled: true,
                            hintText: AppTranslationConstants.specifyAppItemQty.tr,
                            labelText: AppTranslationConstants.appItemQty.tr,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            )),
                        onChanged: (text) {
                          _.setAppItemQty() ;
                        },
                      ),
                    ),
                    SizedBox(
                      width: AppTheme.fullWidth(context)/3,
                      child: GestureDetector(
                        child: Row(
                          children: <Widget>[
                            Checkbox(
                              value: !_.isPhysical,
                              onChanged: (bool? newValue) {
                                _.setIsPhysical();
                              },
                            ),
                            Text(AppTranslationConstants.appDigitalItem.tr),
                          ],
                        ),
                        onTap: ()=>_.setIsPhysical(),
                      ),
                    ),
                  ],
                )
            ),
            HeaderWidget(AppTranslationConstants.processAAndB.tr, secondHeader: true),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCheckBoxItem(_.processARequired,
                      action: _.setProcessARequired,
                      title: AppTranslationConstants.processA.tr
                  ),
                  buildCheckBoxItem(_.processBRequired,
                      action: _.setProcessBRequired,
                      title: AppTranslationConstants.processB.tr
                  ),
                  buildCheckBoxItem(_.coverDesignRequired,
                      action: _.setCoverDesignRequired,
                      title: AppTranslationConstants.coverDesignRequired.tr
                  ),
                ],
              ),
            ),
            const Divider(),
            _.totalCost != 0 ? HeaderWidget(AppTranslationConstants.total.tr, secondHeader: true) : Container(),
            _.totalCost != 0 ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _.processARequired
                      ? buildQuotationInfo(
                      title: AppTranslationConstants.processA.tr,
                      subtitle: _.proccessACost.toString()
                  ) : Container(),
                  _.processBRequired
                      ? buildQuotationInfo(
                      title: AppTranslationConstants.processB.tr,
                      subtitle: _.proccessBCost.toString()
                  ) : Container(),
                  _.coverDesignRequired
                      ? buildQuotationInfo(
                      title: AppTranslationConstants.coverDesign.tr,
                      subtitle: _.coverDesignCost.toString(),
                  ) : Container(),
                  _.isPhysical
                      ? buildQuotationInfo(
                      title: "${AppTranslationConstants.pricePerUnit.tr} x ${_.itemQty}",
                      subtitle: _.pricePerUnit.toString()
                  ) : Container(),
                  const Divider(),
                  _.totalCost != 0
                      ? buildQuotationInfo(
                      title: AppTranslationConstants.totalToPay.tr,
                      subtitle: _.totalCost.toString()
                  ) : Container(),
                  _.totalCost != 0 ? Text(
                      "${AppTranslationConstants.quotationTotalMsg1.tr} ${_.itemToQuote.duration} ${AppTranslationConstants.quotationTotalMsg2.tr}",
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w400),
                  ) : Container(),
                  const Divider(),
                  Center(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColor.bondiBlue
                    ),
                    child: InkWell(
                      child: Text(AppTranslationConstants.contactUsViaWhatsapp.tr,
                        style: const TextStyle(color: Colors.white),),
                      onTap: () {
                        String message = "${AppTranslationConstants.quotationWhatsappMsgA.tr}\n"
                            "${_.itemToQuote.duration != 0 ? "\n${AppTranslationConstants.appItemDuration.tr}: ${_.itemToQuote.duration}" : ""}"
                            "${(_.itemQty != 0 && _.isPhysical) ? "\n${AppTranslationConstants.appItemQty.tr}: ${_.itemQty}\n" : ""}"
                            "${_.proccessACost != 0 ? "\n${AppTranslationConstants.processA.tr}: \$${_.proccessACost} MXN" : ""}"
                            "${_.proccessBCost != 0 ? "\n${AppTranslationConstants.processB.tr}: \$${_.proccessBCost} MXN" : ""}"
                            "${_.coverDesignCost != 0 ? "\n${AppTranslationConstants.coverDesign.tr}: \$${_.coverDesignCost} MXN" : ""}"
                            "${_.pricePerUnit != 0 ? "\n${AppTranslationConstants.pricePerUnit.tr}: \$${_.pricePerUnit} MXN\n" : ""}"
                            "${_.totalCost != 0 ? "\n${AppTranslationConstants.totalToPay.tr}: \$${_.totalCost.toString()} MXN\n\n" : ""}"
                            "${AppTranslationConstants.thanksForYourAttention.tr}\n"
                            "${_.userController.profile.name}";
                        CoreUtilities.launchWhatsappURL(AppFlavour.getWhatsappBusinessNumber(), message);
                      },
                    ),
                  ),),
                  const HeaderIntro(showLogo: false),
                ],
              ),
            ) : Container(),
          ],
        ),
        ),
      ),
    );
  }

  Widget buildCheckBoxItem(bool checkedValue, {Function? action, String title = "",}) {
    return GestureDetector(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 15)),
          Checkbox(
            value: checkedValue,
            onChanged: (bool? newValue) => action != null ? action() : {},
          ),
        ],
      ),
      onTap: () => action != null ? action() : {},
    );
  }

  Widget buildQuotationInfo({String title = "", String subtitle = ""}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 18)),
          Text("\$$subtitle MXN", style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

}
