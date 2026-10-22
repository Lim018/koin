import 'package:flutter/material.dart';

import '../calendar/calendar_page.dart';
import '../insight/insight_page.dart';

enum _View { calendar, chart }

/// "Statistik" tab: the monthly calendar and the spending chart, one at a
/// time. Both stay alive so each keeps its month/period when switching.
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  var _view = _View.calendar;

  @override
  Widget build(BuildContext context) {
    final viewSwitch = SegmentedButton<_View>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: const [
        ButtonSegment(
          value: _View.calendar,
          icon: Icon(Icons.calendar_month_rounded),
          label: Text('Kalender'),
        ),
        ButtonSegment(
          value: _View.chart,
          icon: Icon(Icons.bar_chart_rounded),
          label: Text('Grafik'),
        ),
      ],
      selected: {_view},
      onSelectionChanged: (s) => setState(() => _view = s.first),
    );
    return IndexedStack(
      index: _view.index,
      children: [
        CalendarView(viewSwitch: viewSwitch),
        InsightView(viewSwitch: viewSwitch),
      ],
    );
  }
}
