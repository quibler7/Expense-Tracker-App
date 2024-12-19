// ignore_for_file: unused_field, prefer_final_fields, unused_element, dead_code, unused_local_variable, prefer_interpolation_to_compose_strings
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseDb extends ChangeNotifier {
  static late Isar isar;

  // list of all exoenses
  List<Expense> _allExpenses = [];

  /*
  S E T U P
  */

  // initialize db
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  /*
  G E T T E R S
  */
  List<Expense> get allExpense => _allExpenses;

  /*
  O P E R A T I O N S
  */

  // Create
  Future<void> createNewExpense(Expense newExpense) async {
    // add to db
    await isar.writeTxn(() => isar.expenses.put(newExpense));
    // re read the db again
    await readExpense();
  }

  // Read
  Future<void> readExpense() async {
    // fetch all the exiaating expenses form db
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();

    // give to local expense list
    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);

    // update the UI
    notifyListeners();
  }

  // Update - edit the existing expense
  Future<void> updateExpense(int id, Expense updatedExpense) async {
    // make sure new expense has same id as existing expense
    updatedExpense.id = id;
    // update in db
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));
    // read from db again
    await readExpense();
  }

  // Delete - delete expense from db
  Future<void> deleteExpense(int id) async {
    // delete from db
    await isar.writeTxn(() => isar.expenses.delete(id));
    // read from db again
    await readExpense();
  }

  /*
  H E L P E R  F U N C
  */

  // get all expenses of the month
  Future<Map<String, double>> calculateMonthlyTotals() async {
    // ensure expenses are read form db
    await readExpense();
    // map expenses per month,year wise
    Map<String, double> monthlyTotals = {};

    // iterate again
    for (var expense in _allExpenses) {
      // extract the year & month from the expense date
      String yearMonth = '${expense.date.year}-${expense.date.month}';

      // if its not there in the map then initialize the month to zero in the map
      if (!monthlyTotals.containsKey(yearMonth)) {
        monthlyTotals[yearMonth] = 0;
      }
      // add the expense to the monthly total
      monthlyTotals[yearMonth] = monthlyTotals[yearMonth]! + expense.amount;
    }
    return monthlyTotals;
  }

  // Move these methods outside calculateMonthlyTotals
  int getStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().month;
    }
    // sort expenses by the date to find the earliest
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));
    return _allExpenses.first.date.month;
  }

  int getStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().year;
    }
    // sort expenses by the date to find the earliest
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));
    return _allExpenses.first.date.year;
  }

  // calculate the current month total -> to show expenses of the current month only
  Future<double> calculateCurrentMonthTotol() async {
    // ensure the expenses are read from db first
    await readExpense();

    // get the current month, year
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    // filter the expenses to include only for this month
    List<Expense> currentMonthExpenses = _allExpenses.where(
      (expense) {
        return expense.date.month == currentMonth &&
            expense.date.year == currentYear;
      },
    ).toList();
    // calculate the total for the current month
    double total =
        currentMonthExpenses.fold(0, (sum, expense) => sum + expense.amount);
    return total;
  }
}
