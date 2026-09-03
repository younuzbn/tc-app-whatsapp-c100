import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';

const referShareAssetPath = 'assets/refer_share.png';

String referralShareText(String code) {
  return '''
🌟 Join WIN APP and Start Winning Today! 🌟
Use my Invite Code: $code
📲 Download Link: ${AppConfig.appDownloadUrl}

💸 MASSIVE REFER & EARN BENEFITS 💸
 * Get ₹50 Instantly: You get ₹50 as a welcome bonus the moment you join with my code!
 * Lifetime 5% Commission: Invite your friends and earn 5% whenever they add money to their wallet. If they add ₹600, you get ₹30, and they still keep their full ₹600!
 * Easy Withdrawals: You can withdraw 50% of your Refer & Earn balance and 100% of your actual winnings. (Note: Deposited amounts cannot be withdrawn directly).
 * Smart Wallet Usage: When you play, the app saves your real money by debiting in this exact order: first from your withdrawable referral winnings, second from entry winnings, third from non-withdrawable referral winnings, and finally from your deposit balance.

🏆 OFFICIAL PRIZE CHART (₹10 Tickets) 🏆
 * 🥇 1st Prize: ₹5000 (Super Tickets)
 * 🥈 2nd Prize: ₹500
 * 🥉 3rd Prize: ₹250
 * 🏅 4th Prize: ₹100
 * 🏅 5th Prize: ₹50
 * 🏅 6th Prize: ₹20 (Valid for 30 different 3-digit combinations)
 * 📦 First Prize Box Match: ₹3300 per box for an exact match of the 1st prize winning 3 digits!
 * 🔄 Other Combinations: ₹700 for any other combinations!

🚀 Don't miss out on the daily winnings! Download the app, enter code $code, and claim your ₹50 bonus now!
'''
      .trim();
}

Future<void> shareWinAppInvite(String code) async {
  final data = await rootBundle.load(referShareAssetPath);
  final file = File('${Directory.systemTemp.path}/win-app-refer.png');
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  await SharePlus.instance.share(
    ShareParams(
      text: referralShareText(code),
      files: [
        XFile(file.path, mimeType: 'image/png', name: 'win-app-refer.png'),
      ],
    ),
  );
}
