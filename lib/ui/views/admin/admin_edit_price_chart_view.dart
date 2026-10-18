import 'package:flutter/material.dart';

import '../price_chart/price_chart_view.dart';

class AdminEditPriceChartView extends StatelessWidget {
  const AdminEditPriceChartView({super.key});

  @override
  Widget build(BuildContext context) {
    return const PriceChartView(editable: true);
  }
}
