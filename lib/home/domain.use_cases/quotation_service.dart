
abstract class QuotationService {

  void setAppItemSize(String selectedSize);
  void setAppItemDuration();
  void setAppItemQty();
  void setIsPhysical();
  void setProcessARequired();
  void setProcessBRequired();
  void setCoverDesignRequired();
  void updateQuotation();
  void addRevenuePercentage();
  Future<void> sendWhatsappQuotation();

}
