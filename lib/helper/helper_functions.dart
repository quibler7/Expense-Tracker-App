// ignore_for_file: unused_local_variable

/*
Helpful functions used across the app
*/

import 'package:intl/intl.dart';

// convert the string to the double
double convertStringToDouble(String string) {
  double? amount = double.tryParse(string);
  return amount ?? 0;
}

// format double amount into the rupeees and paise
String formatAmount(double amount) {
  final format =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  return format.format(amount);
}

// calculate the number of months since first start month
int calculateMonthCount(
    int startMonth, int startYear, int currentMonth, int currentYear) {
  int monthCount =
      (currentYear - startYear) * 12 + (currentMonth - startMonth) + 1;
  return monthCount;
}

// get current month name
String currentMonthName() {
  DateTime now = DateTime.now();
  List<String> months = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
  ];
  return months[now.month - 1];
}
