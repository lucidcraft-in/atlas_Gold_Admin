// First, let's create a reusable MonthPicker widget
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime) onDateSelected;

  const MonthPicker({
    Key? key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  _MonthPickerState createState() => _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker> {
  late DateTime _currentDate;
  late DateTime _displayedYear;
  late PageController _yearController;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _displayedYear = DateTime(_currentDate.year, 1);
    _yearController = PageController(
      initialPage: _displayedYear.year -
          (widget.firstDate?.year ?? DateTime.now().year - 5),
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Widget _buildMonthItem(int month) {
    final monthDate = DateTime(_displayedYear.year, month);
    final isSelected =
        _currentDate.year == monthDate.year && _currentDate.month == month;
    final isDisabled = (widget.firstDate != null &&
            monthDate.isBefore(
                DateTime(widget.firstDate!.year, widget.firstDate!.month))) ||
        (widget.lastDate != null &&
            monthDate.isAfter(
                DateTime(widget.lastDate!.year, widget.lastDate!.month)));

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: isDisabled
            ? null
            : () {
                setState(() {
                  _currentDate = DateTime(_displayedYear.year, month);
                });
                widget.onDateSelected(_currentDate);
              },
        child: Text(
          DateFormat('MMM').format(DateTime(_displayedYear.year, month)),
          style: TextStyle(
              color: isSelected
                  ? const Color.fromARGB(255, 64, 34, 34)
                  : Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: 300,
      child: Column(
        children: [
          // Year navigation header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _displayedYear = DateTime(_displayedYear.year - 1, 1);
                      if (_yearController.hasClients) {
                        _yearController.animateToPage(
                          _yearController.page!.round() - 1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
                ),
                Text(
                  _displayedYear.year.toString(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      _displayedYear = DateTime(_displayedYear.year + 1, 1);
                      if (_yearController.hasClients) {
                        _yearController.animateToPage(
                          _yearController.page!.round() + 1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          // Month grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return _buildMonthItem(index + 1);
              },
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onDateSelected(_currentDate);
                    Navigator.of(context).pop(_currentDate);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Function to show the month picker dialog
Future<DateTime?> showCustomMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: MonthPicker(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          onDateSelected: (date) {
            // This callback is triggered when a month is selected within the picker
          },
        ),
      );
    },
  );
}
