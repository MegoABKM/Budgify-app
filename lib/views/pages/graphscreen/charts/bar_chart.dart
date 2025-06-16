import 'package:budgify/core/utils/no_data_widget.dart';
import 'package:budgify/core/utils/parrot_animation_waiting.dart';
import 'package:budgify/core/utils/format_amount.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../../domain/models/expense.dart';
import '../../../../data/repo/expenses_repository.dart';
import 'package:budgify/core/utils/scale_config.dart'; // Import the ScaleConfig

class SimpleBarChart extends ConsumerWidget {
  final int day;
  final int month;
  final int year;
  final bool isYear;
  final bool isMonth;
  final bool isDay;
  final bool isIncome;

  const SimpleBarChart({
    super.key,
    required this.day,
    required this.month,
    required this.year,
    required this.isYear,
    required this.isMonth,
    required this.isDay,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context); // Initialize ScaleConfig
    final repository = ExpensesRepository();

    return StreamBuilder<List<CashFlow>>(
      stream: repository.getExpensesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ParrotAnimation();
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return NoDataWidget();
        }

        final now = DateTime.now();
        final filteredExpenses =
            snapshot.data!.where((expense) {
              final expenseDate = expense.date;
              bool yearMatches = isYear ? expenseDate.year == year : true;
              if (!isYear && (isMonth || isDay)) {
                yearMatches = expenseDate.year == now.year;
              }
              bool monthMatches = isMonth ? expenseDate.month == month : true;
              bool dayMatches = isDay ? expenseDate.day == day : true;

              return yearMatches &&
                  monthMatches &&
                  dayMatches &&
                  expense.isIncome == isIncome;
            }).toList();

        if (filteredExpenses.isEmpty) {
          return NoDataWidget();
        }

        final Map<String, double> categoryTotals = {};
        final Map<String, CashFlow> categoryDetails = {};

        for (var expense in filteredExpenses) {
          final categoryName = expense.category.name;
          categoryTotals[categoryName] =
              (categoryTotals[categoryName] ?? 0) + expense.amount;
          categoryDetails[categoryName] = expense;
        }

        final double maxAmount =
            categoryTotals.values.isNotEmpty
                ? categoryTotals.values.reduce((a, b) => a > b ? a : b)
                : 0;

        List<BarChartGroupData> barGroups =
            categoryTotals.entries.map((entry) {
              final categoryExpense = categoryDetails[entry.key]!;
              return BarChartGroupData(
                x: categoryTotals.keys.toList().indexOf(entry.key),
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: categoryExpense.category.color,
                    width: scaleConfig.scale(8), // Scaled bar width
                  ),
                ],
                showingTooltipIndicators: [],
              );
            }).toList();

        return Padding(
          padding: EdgeInsets.only(
            right: scaleConfig.scale(5),
          ), // Scaled padding
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAmount,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxAmount / 5,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        getFormattedAmount(value, ref),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: scaleConfig.scaleText(8), // Scaled text
                        ),
                      );
                    },
                    reservedSize: scaleConfig.scale(
                      40,
                    ), // Scaled reserved space
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < categoryTotals.keys.length) {
                        final category = categoryTotals.keys.elementAt(index);
                        return Padding(
                          padding: EdgeInsets.only(top: scaleConfig.scale(4)),
                          child: Text(
                            category.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: scaleConfig.scaleText(8), // Scaled text
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: scaleConfig.scale(30), // Space for labels
                  ),
                ),
              ),

              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine:
                    (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: scaleConfig.scale(0.5), // Scaled line width
                    ),
                verticalInterval: 1,
              ),
              borderData: FlBorderData(show: false),

              // barTouchData: BarTouchData(
              //   enabled: false,
              //   touchTooltipData: BarTouchTooltipData(
              //     // ignore: deprecated_member_use
              //     // getTooltipColor: Colors.black.withOpacity(0.8),
              //     getTooltipItem: (group, groupIndex, rod, rodIndex) {
              //       final category = categoryTotals.keys.elementAt(group.x);
              //       return BarTooltipItem(
              //         '$category\n${rod.toY.toStringAsFixed(2)}',
              //         TextStyle(
              //           color: Colors.white,
              //           fontSize: scaleConfig.scaleText(12), // Scaled tooltip
              //         ),
              //       );
              //     },
              //   ),
              // ),
            ),
          ),
        );
      },
    );
  }
}
