import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constant/colors.dart';
import 'package:provider/provider.dart';
import '../../providers/user.dart';
import '../../widget/monthPicker.dart';

class CloseReport extends StatefulWidget {
  const CloseReport({super.key});

  @override
  State<CloseReport> createState() => _CloseReportState();
}

class _CloseReportState extends State<CloseReport> {
  final ScrollController _scrollController = ScrollController();
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> userList = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _lastDocument = null;
      userList.clear();
    });

    try {
      final result = await Provider.of<User>(context, listen: false)
          .getClosedUserPaginated(
        selectDate: selectedDate,
        lastDocument: null,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          userList = List<Map<String, dynamic>>.from(result["users"] ?? []);
          _lastDocument = result["lastDocument"];
          _hasMore = result["hasMore"] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading initial closed users: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await Provider.of<User>(context, listen: false)
          .getClosedUserPaginated(
        selectDate: selectedDate,
        lastDocument: _lastDocument,
        limit: _pageSize,
      );

      final List<Map<String, dynamic>> newUsers =
          List<Map<String, dynamic>>.from(result["users"] ?? []);

      if (mounted) {
        setState(() {
          userList.addAll(newUsers);
          _lastDocument = result["lastDocument"];
          _hasMore = result["hasMore"] ?? false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print("Error loading more closed users: $e");
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: useColor.homeIconColor,
        title: const Text("Close Report"),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Select Month",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () {
                    showCustomMonthPicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(DateTime.now().year - 1, 5),
                      lastDate: DateTime(DateTime.now().year + 1, 14),
                    ).then((date) {
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                        _loadInitialData();
                      }
                    });
                  },
                  icon: const Icon(Icons.calendar_today),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Selected Month : ${DateFormat('yyyy MMMM').format(selectedDate)}",
            ),
            const Divider(),
            Expanded(
              child: _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (userList.isEmpty) {
      return const Center(
        child: Text(
          "No Data Found...",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: userList.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == userList.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }

          final user = userList[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            tileColor: const Color.fromARGB(37, 128, 23, 23),
            title: Text(
              user["name"]?.toString() ?? "",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "Closing Balance : ${user["balaceAtClose"]?.toString() ?? '0'}",
            ),
            trailing: IconButton(
              onPressed: () {
                _showCloseCustomerDialog(context, user);
              },
              icon: const Icon(FontAwesomeIcons.refresh),
            ),
          );
        },
        separatorBuilder: (context, index) {
          return const SizedBox(height: 10);
        },
      ),
    );
  }

  void _showCloseCustomerDialog(BuildContext context, var cust) {
    DateTime? selectedDate = DateTime.now(); // Holds the selected date

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Reactivating Customer'),
              content: Container(
                height: MediaQuery.of(context).size.height * .25,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Are you sure you want to reactivate this customer?'),
                    SizedBox(height: 10),
                    Text("Customer Name: ${cust['name']}"),
                    Text("Customer Balance: ${cust['balaceAtClose']}"),
                    SizedBox(height: 10),
                    // Select Date button and display selected date
                    TextButton(
                      onPressed: () async {
                        // DateTime? pickedDate = await showDatePicker(
                        //   context: context,
                        //   initialDate: DateTime.now(),
                        //   firstDate: DateTime(2000),
                        //   lastDate: DateTime(2101),
                        // );
                        // if (pickedDate != null) {
                        //   setState(() {
                        //     selectedDate = pickedDate;
                        //   });
                        // }
                      },
                      child: Text(
                        selectedDate == null
                            ? 'Select Reactivation Date'
                            : 'Reactivation Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
                TextButton(
                  child: Text('Reactivate'),
                  onPressed: () {
                    if (selectedDate != null) {
                      Provider.of<User>(context, listen: false)
                          .ReactivityCloseUser(
                              cust['id'],
                              cust['balaceAtClose'],
                              cust['closeTotal_gram'],
                              DateTime.now());
                      // Handle the reactivation logic here
                      _loadInitialData();
                      Navigator.of(context)
                          .pop(); // Close the dialog after reactivation
                    } else {
                      // Optionally show an alert that the date has not been selected
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
