import 'package:flutter/material.dart';

const kReferEarnPageKey = 'refer_earn';
const kPriceChartPageKey = 'price_chart';

const kReferEarnDefaults = <String, String>{
  'pageTitle': "Refer & Earn",
  'heroImageUrl': "",
  'title': "നിങ്ങളുടെ സ്വന്തം Agent",
  'body1': "വേണ്ടത് ഇത്ര മാത്രം — നിങ്ങളുടെ മൂന്നക്ക നമ്പർ ലോട്ടറി എഴുത്തുകാരായ സുഹൃത്തുക്കൾക്ക് Win App share ചെയ്യുക.",
  'body2': "അവരെ നമ്മുടെ ആപ്പിൽ അക്കൗണ്ട് create ചെയ്യിക്കുക. അവർ ആദ്യ deposit ചെയ്യുന്നത് മുതൽ നിങ്ങൾക്ക് വരുമാനം കിട്ടി തുടങ്ങുന്നതാണ്.",
  'benefit1Icon': "card_giftcard_outlined",
  'benefit1Text': "സുഹൃത്തിന് ₹50 വെൽക്കം ബോണസ്!",
  'benefit2Icon': "show_chart_rounded",
  'benefit2Text': "നിങ്ങൾക്ക് 5% ലൈഫ് ടൈം കമ്മീഷൻ!",
  'exampleNote': "(അവർ പണം ചേർക്കുമ്പോൾ നിങ്ങൾക്ക് ലഭിക്കുന്നത്. ഉദാഹരണത്തിന്: ₹600 ചേർത്താൽ, നിങ്ങൾക്ക് ₹30)",
  'inviteCodeLabel': "നിങ്ങളുടെ ഇൻവൈറ്റ് കോഡ്:",
  'shareButtonLabel': "ഷെയർ ചെയ്യൂ, വിജയിക്കൂ!",
  'shareIconUrl': "",
};

const kPriceChartDefaults = <String, String>{
  'pageTitle': "സമ്മാന ചാർട്ട്",
  'headerEmoji': "🏆",
  'headerTitle': "സമ്മാന ചാർട്ട്",
  'headerSubtitle': "നിങ്ങളുടെ വിജയ വിവരങ്ങൾ ഇവിടെ കാണാം",
  'superTitle': "3 അക്ക സൂപ്പർ ടിക്കറ്റ്",
  'ticketPrice': "ടിക്കറ്റ് വില: ₹10",
  'prize1Title': "ഒന്നാം സമ്മാനം",
  'prize1Amount': "₹5,000",
  'prize1Note': "",
  'prize2Title': "രണ്ടാം സമ്മാനം",
  'prize2Amount': "₹500",
  'prize2Note': "",
  'prize3Title': "മൂന്നാം സമ്മാനം",
  'prize3Amount': "₹250",
  'prize3Note': "",
  'prize4Title': "നാലാം സമ്മാനം",
  'prize4Amount': "₹100",
  'prize4Note': "",
  'prize5Title': "അഞ്ചാം സമ്മാനം",
  'prize5Amount': "₹50",
  'prize5Note': "",
  'prize6Title': "ആറാം സമ്മാനം",
  'prize6Amount': "₹20",
  'prize6Note': "(30 വ്യത്യസ്ത നമ്പറുകൾക്ക്)",
  'abcTitle': "എ, ബി, സി (A, B, C)",
  'abcSubtitle': "ടിക്കറ്റുകൾ",
  'singleTitle': "സിംഗിൾ ടിക്കറ്റ് (A, B, C)",
  'singlePrice': "ടിക്കറ്റ് വില: ₹12",
  'singlePrize': "₹100",
  'doubleTitle': "ഡബിൾ ടിക്കറ്റ് (AB, BC, AC)",
  'doublePrice': "ടിക്കറ്റ് വില: ₹10",
  'doublePrize': "₹700",
  'prizeWord': "സമ്മാനം",
  'boxDirectLabel': "നേരിട്ട് വന്നാൽ",
  'boxChangedLabel': "മാറി വന്നാൽ (ബോക്സ്)",
  'pair1Left': "₹3,300",
  'pair1Right': "₹800",
  'repeat2Title': "2 അക്കങ്ങൾ ആവർത്തിച്ചാൽ",
  'repeat2Subtitle': "(ഉദാ: 556, 667)",
  'pair2Left': "₹3,800",
  'pair2Right': "₹800",
  'tripleTitle': "3 അക്കങ്ങളും ഒന്നായാൽ",
  'tripleSubtitle': "(ഉദാ: 666, 444, 777)",
  'triplePrizeTitle': "ഒന്നാം സമ്മാനം",
  'tripleAmount': "₹7,000",
  'tripleSuffix': " (box)",
  'noteTitle': "ഒന്നിലധികം സമ്മാനങ്ങൾ ലഭിച്ചാൽ:",
  'noteBody': "ഒരേ നമ്പർ തന്നെ പല സമ്മാനങ്ങൾക്ക് അർഹമായാൽ, എല്ലാ സമ്മാനത്തുകയും ഒരുമിച്ച് ലഭിക്കുന്നതാണ്.",
  'noteExample': "(ഉദാഹരണത്തിന്: 123 എന്ന നമ്പറിന് ഒന്നാമത്തെയും രണ്ടാമത്തെയും സമ്മാനം ലഭിച്ചാൽ ₹5000 + ₹500 = ₹5500 ലഭിക്കും).",
};

const kPageDefaults = <String, Map<String, String>>{
  kReferEarnPageKey: kReferEarnDefaults,
  kPriceChartPageKey: kPriceChartDefaults,
};

Map<String, String> mergePageData(String key, Map<String, dynamic>? data) {
  final defaults = Map<String, String>.from(kPageDefaults[key] ?? const {});
  for (final entry in (data ?? const {}).entries) {
    if (entry.value == null) continue;
    defaults[entry.key] = entry.value.toString();
  }
  return defaults;
}

const kPageIconChoices = <String, IconData>{
  'card_giftcard_outlined': Icons.card_giftcard_outlined,
  'show_chart_rounded': Icons.show_chart_rounded,
  'stars_rounded': Icons.stars_rounded,
  'people_alt_outlined': Icons.people_alt_outlined,
  'payments_outlined': Icons.payments_outlined,
  'workspace_premium_outlined': Icons.workspace_premium_outlined,
  'volunteer_activism_outlined': Icons.volunteer_activism_outlined,
  'trending_up_rounded': Icons.trending_up_rounded,
  'savings_outlined': Icons.savings_outlined,
  'redeem_outlined': Icons.redeem_outlined,
  'emoji_events_outlined': Icons.emoji_events_outlined,
  'favorite_outline_rounded': Icons.favorite_outline_rounded,
};

IconData pageIconData(String name) {
  return kPageIconChoices[name] ?? Icons.star_outline_rounded;
}
