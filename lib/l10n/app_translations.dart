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
