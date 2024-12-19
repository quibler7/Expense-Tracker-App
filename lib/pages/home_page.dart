// ignore_for_file: prefer_const_constructors, unused_field, prefer_final_fields, prefer_const_literals_to_create_immutables, unused_element, unused_local_variable, unused_import, body_might_complete_normally_nullable, prefer_interpolation_to_compose_strings

import 'package:expense_tracker/bar_graph/bar_graph.dart';
import 'package:expense_tracker/components/my_list_tile.dart';
import 'package:expense_tracker/helper/helper_functions.dart';
import 'package:expense_tracker/db/expense_db.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Text controllers to access name and amount user typed
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // futures to load the graph data & monthly total
  Future<Map<String, double>>? _monthlyTotalsFutures;
  Future<double>? _calculateCurrentMonthTotal;

  @override
  void initState() {
    // read the db on initial startup
    Provider.of<ExpenseDb>(context, listen: false).readExpense();

    // load futures
    refreshData();

    super.initState();
  }

  // refresh graph data
  void refreshData() {
    _monthlyTotalsFutures =
        Provider.of<ExpenseDb>(context, listen: false).calculateMonthlyTotals();
    _calculateCurrentMonthTotal = Provider.of<ExpenseDb>(context, listen: false)
        .calculateCurrentMonthTotol();
  }

  // open new expense box upon clicking floating action button
  void openNewExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'expense name',
              ),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
              ),
            ),
          ],
        ),
        actions: [
          // save buttion
          _saveNewExpenseButton(),
          // cancel button
          _cancelButton(),
        ],
      ),
    );
  }

  // open Edit Box
  void openEditBox(Expense expense) {
    // prefill the existing value into Textfields as we are editing
    String existingName = expense.name;
    String existingAmount = expense.amount.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: existingName,
              ),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: existingAmount,
              ),
            ),
          ],
        ),
        actions: [
          // save buttion
          _editExpenseButton(expense),
          // cancel button
          _cancelButton(),
        ],
      ),
    );
  }

  // open Delete Box
  void openDeleteBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Expense?'),
        actions: [
          // canel buttion
          _cancelButton(),
          // delete button
          _deleteExpenseButton(expense.id),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDb>(
      builder: (context, value, child) {
        // get dates
        int startMonth = value.getStartMonth();
        int startYear = value.getStartYear();
        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;

        // calculate number of months since first month
        int monthCount = calculateMonthCount(
            startMonth, startYear, currentMonth, currentYear);

        // display the expenses only for the current month
        List<Expense> currentMonthExpenses = value.allExpense.where((expense) {
          return expense.date.year == currentYear &&
              expense.date.month == currentMonth;
        }).toList();

        // return UI
        return Scaffold(
          backgroundColor: Colors.blueGrey[100],
          floatingActionButton: FloatingActionButton(
            onPressed: openNewExpenseBox,
            backgroundColor: Colors.blueGrey.shade700,
            elevation: 0,
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
          appBar: AppBar(
            title: FutureBuilder<double>(
              future: _calculateCurrentMonthTotal,
              builder: (context, snapshot) {
                // loaded
                if (snapshot.connectionState == ConnectionState.done) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // amount total
                      Text(
                        '₹ ' + snapshot.data!.toStringAsFixed(2),
                      ),
                      // display month
                      Text(currentMonthName()),
                    ],
                  );
                }
                // loading
                else {
                  return Text("Loading...");
                }
              },
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // GRAPH UI
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    height: 250,
                    child: FutureBuilder(
                      future: _monthlyTotalsFutures,
                      builder: (context, snapshot) {
                        // data is loaded
                        if (snapshot.connectionState == ConnectionState.done) {
                          // get the data
                          Map<String, double> monthlyTotals =
                              snapshot.data ?? {};
                          // create the list of monthly summery
                          List<double> monthlySummery =
                              List.generate(monthCount, (index) {
                            // calculate year-month considering startMonth & index
                            int year =
                                startYear + (startMonth + index - 1) ~/ 12;
                            int month = (startMonth + index - 1) % 12 + 1;
                            // create the key in the format of year-month
                            String yearMonthKey = "$year-$month";
                            // return the total for year-month combo or zero if doesn't exist
                            return monthlyTotals[yearMonthKey] ?? 0.0;
                          });
                          return MyBarGraph(
                              monthlySummery: monthlySummery,
                              startMonth: startMonth);
                        }
                        // loading
                        else {
                          return const Center(
                            child: Text("Loading..."),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // EXPENSE LIST UI
                Expanded(
                  child: ListView.builder(
                    itemCount: currentMonthExpenses.length,
                    itemBuilder: (context, index) {
                      // reverse the list to show the latest expense at the top
                      int reversedIndex =
                          currentMonthExpenses.length - 1 - index;
                      // get individual expense
                      Expense individualExpense =
                          currentMonthExpenses[reversedIndex];
                      // return list tile UI
                      return MyListTile(
                        title: individualExpense.name,
                        trailing: formatAmount(individualExpense.amount),
                        onEditPressed: (context) =>
                            openEditBox(individualExpense),
                        onDeletePressed: (context) =>
                            openDeleteBox(individualExpense),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // cancel button
  Widget _cancelButton() {
    return TextButton(
      onPressed: () {
        // close the dialog box
        Navigator.pop(context);
        // clear the controllers if user has types something
        nameController.clear();
        amountController.clear();
      },
      child: const Text('Cancel'),
    );
  }

  // save button
  Widget _saveNewExpenseButton() {
    return TextButton(
      onPressed: () async {
        // save the expense to the db only if both the fields are non empty
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          // pop the box
          Navigator.pop(context);
          // create a new expense
          Expense newExpense = Expense(
              name: nameController.text,
              amount: convertStringToDouble(amountController.text),
              date: DateTime.now());
          // save to db
          await context.read<ExpenseDb>().createNewExpense(newExpense);
          // refresh bar graph data
          refreshData();
          // clear the controllers
          nameController.clear();
          amountController.clear();
        }
      },
      child: Text('Save'),
    );
  }

  // edit existing expense button
  Widget _editExpenseButton(Expense expense) {
    return TextButton(
      onPressed: () async {
        // save if at least one field has changed
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          // pop the box
          Navigator.pop(context);
          // create new updated expense
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty
                ? nameController.text
                : expense.name,
            amount: amountController.text.isNotEmpty
                ? convertStringToDouble(amountController.text)
                : expense.amount,
            date: DateTime.now(),
          );

          // old expense id - keep the ID same as we are editing the existing expense
          int existingId = expense.id;

          // save to db
          await context
              .read<ExpenseDb>()
              .updateExpense(existingId, updatedExpense);
          // refresh the bar graph data
          refreshData();
          // clear the controllers
          nameController.clear();
          amountController.clear();
        }
      },
      child: Text("Save"),
    );
  }

  // delete button
  Widget _deleteExpenseButton(int id) {
    return TextButton(
      onPressed: () async {
        // pop the box
        Navigator.pop(context);
        // delete from db
        await context.read<ExpenseDb>().deleteExpense(id);
        // refresh the bar graph data
        refreshData();
      },
      child: Text("Delete"),
    );
  }
}
