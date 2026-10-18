import 'package:flutter/material.dart';

import '../refer/refer_and_earn_view.dart';

class AdminEditReferEarnView extends StatelessWidget {
  const AdminEditReferEarnView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferAndEarnView(
      referralCode: 'WINXXXX',
      editable: true,
    );
  }
}
