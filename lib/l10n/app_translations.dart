import 'package:get/get.dart';

/// UI strings in English, French and Arabic. Use them as `'key'.tr` (or
/// `'key'.trParams({...})` for `@name` placeholders). Add every new
/// user-facing string here in all three languages.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en': _en,
    'fr': _fr,
    'ar': _ar,
  };
}

const _en = {
  'wallet_title': 'SAIMPEX Wallet',
  'wallet_balance': 'Available balance',
  'wallet_topup': 'Top up',
  'wallet_topup_amount': 'Amount',
  'wallet_topup_continue': 'Continue to payment',
  'wallet_topup_limits': 'Between @min and @max MRU',
  'wallet_topup_paid': 'Money added to your wallet.',
  'wallet_topup_failed': 'Top-up failed. Nothing was added.',
  'wallet_topup_pending':
      'Top-up not confirmed yet. Your balance updates when the payment arrives.',
  'wallet_history': 'History',
  'wallet_no_history': 'No transactions yet.',
  'wallet_credit': 'Added to wallet',
  'wallet_debit': 'Paid from wallet',
  'wallet_split': 'Wallet @wallet MRU + Online @online MRU',
  'search_hint': 'Search stores and products',
  'search_prompt': 'Type what you are looking for',
  'search_no_results': 'No results for "@query"',
  'search_products': 'Products',
  'search_vertical_food': 'Food',
  'search_vertical_grocery': 'Grocery',
  'search_vertical_local_store': 'Local Store',
  'search_vertical_pharmacy': 'Pharmacy',
  'search_vertical_water': 'Water',
  'language_switched': 'Language switched to @language',
  'cancel': 'Cancel',
  'retry': 'Retry',
  'close': 'Close',
  'loading': 'Loading…',
  'mru': '@amount MRU',
  'payment_page_failed': 'Could not open the payment page. Please try again.',
  'payment_not_completed': 'Payment not completed.',
  // Pay After Delivery
  'pad_title': 'Pay Later',
  'pad_option': 'Pay After Delivery',
  'pad_option_hint':
      "Enjoy your order first. Pay within the time shown after it's delivered.",
  'pad_blocked_unpaid': 'Pay your earlier order first. Tap to pay it.',
  'pad_blocked_removed':
      'Not available: an earlier order was paid late. Contact support.',
  'pad_blocked_not_trusted':
      'Available after @needed paid orders (@done so far).',
  'pad_nothing_due': 'You have no orders to pay.',
  'pad_after_delivery': 'You can pay once it has been delivered.',
  'pad_due_now': 'Delivered: please pay now.',
  'pad_pay_by': 'Pay by @time',
  'pad_pay_wallet': 'Pay from wallet',
  'pad_pay_online': 'Pay online',
  'pad_paid': 'Payment received. Thank you!',
  'courier_payment_retry':
      'Payment not completed. Tap the pay button to pay for this order.',
};

const _fr = {
  'wallet_title': 'Portefeuille SAIMPEX',
  'wallet_balance': 'Solde disponible',
  'wallet_topup': 'Recharger',
  'wallet_topup_amount': 'Montant',
  'wallet_topup_continue': 'Continuer vers le paiement',
  'wallet_topup_limits': 'Entre @min et @max MRU',
  'wallet_topup_paid': 'Montant ajouté à votre portefeuille.',
  'wallet_topup_failed': "Recharge échouée. Rien n'a été ajouté.",
  'wallet_topup_pending':
      "Recharge pas encore confirmée. Votre solde sera mis à jour à la réception du paiement.",
  'wallet_history': 'Historique',
  'wallet_no_history': 'Aucune transaction pour le moment.',
  'wallet_credit': 'Ajouté au portefeuille',
  'wallet_debit': 'Payé avec le portefeuille',
  'wallet_split': 'Portefeuille @wallet MRU + En ligne @online MRU',
  'search_hint': 'Rechercher des magasins et des produits',
  'search_prompt': 'Tapez ce que vous cherchez',
  'search_no_results': 'Aucun résultat pour « @query »',
  'search_products': 'Produits',
  'search_vertical_food': 'Restauration',
  'search_vertical_grocery': 'Épicerie',
  'search_vertical_local_store': 'Commerce local',
  'search_vertical_pharmacy': 'Pharmacie',
  'search_vertical_water': 'Eau',
  'language_switched': 'Langue changée : @language',
  'cancel': 'Annuler',
  'retry': 'Réessayer',
  'close': 'Fermer',
  'loading': 'Chargement…',
  'mru': '@amount MRU',
  'payment_page_failed':
      "Impossible d'ouvrir la page de paiement. Veuillez réessayer.",
  'payment_not_completed': 'Paiement non effectué.',
  'pad_title': 'Payer plus tard',
  'pad_option': 'Payer après la livraison',
  'pad_option_hint':
      'Profitez de votre commande, puis payez dans le délai indiqué après la livraison.',
  'pad_blocked_unpaid':
      "Réglez d'abord votre commande précédente. Touchez pour payer.",
  'pad_blocked_removed':
      'Indisponible : une commande précédente a été payée en retard. Contactez le support.',
  'pad_blocked_not_trusted':
      'Disponible après @needed commandes payées (@done pour le moment).',
  'pad_nothing_due': "Vous n'avez aucune commande à payer.",
  'pad_after_delivery': 'Vous pourrez payer une fois la commande livrée.',
  'pad_due_now': 'Livrée : veuillez payer maintenant.',
  'pad_pay_by': 'À payer avant le @time',
  'pad_pay_wallet': 'Payer avec le portefeuille',
  'pad_pay_online': 'Payer en ligne',
  'pad_paid': 'Paiement reçu. Merci !',
  'courier_payment_retry':
      'Paiement non effectué. Touchez le bouton de paiement pour régler cette commande.',
};

const _ar = {
  'wallet_title': 'محفظة سايمبكس',
  'wallet_balance': 'الرصيد المتاح',
  'wallet_topup': 'شحن الرصيد',
  'wallet_topup_amount': 'المبلغ',
  'wallet_topup_continue': 'المتابعة إلى الدفع',
  'wallet_topup_limits': 'بين @min و@max أوقية',
  'wallet_topup_paid': 'تمت إضافة المبلغ إلى محفظتك.',
  'wallet_topup_failed': 'فشل الشحن. لم تتم إضافة أي مبلغ.',
  'wallet_topup_pending':
      'لم يتم تأكيد الشحن بعد. سيتم تحديث رصيدك عند وصول الدفع.',
  'wallet_history': 'السجل',
  'wallet_no_history': 'لا توجد معاملات بعد.',
  'wallet_credit': 'أضيف إلى المحفظة',
  'wallet_debit': 'دُفع من المحفظة',
  'wallet_split': 'المحفظة @wallet أوقية + عبر الإنترنت @online أوقية',
  'search_hint': 'ابحث عن المتاجر والمنتجات',
  'search_prompt': 'اكتب ما تبحث عنه',
  'search_no_results': 'لا توجد نتائج لـ "@query"',
  'search_products': 'المنتجات',
  'search_vertical_food': 'الطعام',
  'search_vertical_grocery': 'البقالة',
  'search_vertical_local_store': 'المتجر المحلي',
  'search_vertical_pharmacy': 'الصيدلية',
  'search_vertical_water': 'المياه',
  'language_switched': 'تم تغيير اللغة إلى @language',
  'cancel': 'إلغاء',
  'retry': 'إعادة المحاولة',
  'close': 'إغلاق',
  'loading': 'جارٍ التحميل…',
  'mru': '@amount أوقية',
  'payment_page_failed': 'تعذّر فتح صفحة الدفع. يُرجى المحاولة مرة أخرى.',
  'payment_not_completed': 'لم تكتمل عملية الدفع.',
  'pad_title': 'الدفع لاحقًا',
  'pad_option': 'الدفع بعد التوصيل',
  'pad_option_hint':
      'استمتع بطلبك أولًا، ثم ادفع خلال المهلة المحددة بعد التوصيل.',
  'pad_blocked_unpaid': 'ادفع طلبك السابق أولًا. اضغط للدفع.',
  'pad_blocked_removed': 'غير متاح: تم دفع طلب سابق متأخرًا. تواصل مع الدعم.',
  'pad_blocked_not_trusted': 'متاح بعد @needed طلبات مدفوعة (@done حتى الآن).',
  'pad_nothing_due': 'لا توجد طلبات بانتظار الدفع.',
  'pad_after_delivery': 'يمكنك الدفع بعد توصيل الطلب.',
  'pad_due_now': 'تم التوصيل: يُرجى الدفع الآن.',
  'pad_pay_by': 'ادفع قبل @time',
  'pad_pay_wallet': 'الدفع من المحفظة',
  'pad_pay_online': 'الدفع عبر الإنترنت',
  'pad_paid': 'تم استلام الدفع. شكرًا لك!',
  'courier_payment_retry':
      'لم تكتمل عملية الدفع. اضغط زر الدفع لدفع هذا الطلب.',
};
