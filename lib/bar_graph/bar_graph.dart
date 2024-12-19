// ignore_for_file: prefer_const_constructors, sort_child_properties_last, unused_local_variable

import 'package:expense_tracker/bar_graph/individual_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyBarGraph extends StatefulWidget {
  final List<double> monthlySummery; // of expenses - 250, 1200, 560, .....
  final int startMonth; // 0 - jan , 1- feb, 2- march
  const MyBarGraph(
      {super.key, required this.monthlySummery, required this.startMonth});

  @override
  State<MyBarGraph> createState() => _MyBarGraphState();
}

class _MyBarGraphState extends State<MyBarGraph> {
  // this list will hold the data for each bar - daily expenses
  List<IndividualBar> barData = [];

  @override
  void initState() {
    super.initState();
    // we need to scroll to the latest month automatically
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => scrollToEnd());
  }

  // initialize bar data - use our monthly summery to create list of bars
  void initializeBarData() {
    barData = List.generate(
      widget.monthlySummery.length,
      (index) => IndividualBar(
        x: index,
        y: widget.monthlySummery[index],
      ),
    );
  }

  // calculate maximum upper limit for the Bar Graph Data depending upon the expenses of the
  // particular user...
  double calculateMaxBarHeight() {
    // Initially set it to the 1000 rs but adjust it according to the max spending
    double max = 500;
    // get the month with the highest amount
    widget.monthlySummery.sort();
    // increse the upper limit by a bit
    // keep the total limit 5 percent more than max expense
    max = (widget.monthlySummery.last * 1.05);
    if (max < 500) {
      return 500;
    }
    return max;
  }

  // scroll control to make sure that it scrolls to the end/ latest month
  final ScrollController _scrollController = ScrollController();
  void scrollToEnd() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    initializeBarData();

    // bar dimensions sizes
    double barWidth = 20;
    double spaceBetweenBars = 15;

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: SizedBox(
          width: (barWidth * barData.length) +
              (spaceBetweenBars * (barData.length - 1)),
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: calculateMaxBarHeight(),
              // to hide the bar graph lines
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                // only show bottom titles
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: getBottomTitles,
                    reservedSize: 24,
                  ),
                ),
              ),
              barGroups: barData
                  .map(
                    (data) => BarChartGroupData(
                      x: data.x,
                      barRods: [
                        BarChartRodData(
                          toY: data.y,
                          // decorating the bar graph
                          width: barWidth,
                          color: Colors.blueGrey.shade700,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: calculateMaxBarHeight(),
                            color: Colors.blueGrey.shade200,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
              alignment: BarChartAlignment.center,
              groupsSpace: spaceBetweenBars,
            ),
          ),
        ),
      ),
    );
  }
}

Widget getBottomTitles(double value, TitleMeta meta) {
  const textStyle = TextStyle(
    color: Colors.black54,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  String text;
  switch (value.toInt() % 12) {
    case 0:
      text = 'J';
      break;
    case 1:
      text = 'F';
      break;
    case 2:
      text = 'M';
      break;
    case 3:
      text = 'A';
      break;
    case 4:
      text = 'M';
      break;
    case 5:
      text = 'J';
      break;
    case 6:
      text = 'J';
      break;
    case 7:
      text = 'A';
      break;
    case 8:
      text = 'S';
      break;
    case 9:
      text = 'O';
      break;
    case 10:
      text = 'N';
      break;
    case 11:
      text = 'D';
      break;
    default:
      text = '';
      break;
  }
  return SideTitleWidget(
      child: Text(
        text,
        style: textStyle,
      ),
      axisSide: meta.axisSide);
}
