import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../constant/colors.dart';
import '../../providers/goldrate.dart';
import '../../providers/user.dart';

class TransactionForm extends StatefulWidget {
  final String? userid;
  final String? token;
  final double? balance;
  final Map? user;
  final User? dbUser;
  final String? custName;

  const TransactionForm({
    Key? key,
    this.userid,
    this.token,
    this.balance,
    this.dbUser,
    this.user,
    this.custName,
  }) : super(key: key);

  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _gramController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _staffDetails;
  double _currentGoldPrice = 0; // You might want to fetch this dynamically

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() {
      _amountController.text = widget.balance!.toStringAsFixed(2);
      _noteController.text = "Discount";
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? staffString = prefs.getString('staff');

      if (staffString != null) {
        setState(() {
          _staffDetails = jsonDecode(staffString);
        });
      }
    } catch (e) {
      print('Error loading staff data: $e');
    }
    Goldrate? dbGoldrate;
    dbGoldrate = Goldrate();
    dbGoldrate!.initiliase();
    dbGoldrate!.read().then((value) => {
          setState(() {
            List goldrateList = value!;
            _currentGoldPrice = goldrateList[0]['gram'];
          }),
        });
  }

  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      Map<String, dynamic> transactionData = {
        "amount": widget.balance,
        "category": "Gold",
        "currentBalance": 0,
        "currentBalanceGram": 0,
        "customerId": widget.userid,
        "customerName": widget.custName,
        "date": Timestamp.now(),
        "discount": widget.balance,
        "gramPriceInvestDay": _currentGoldPrice,
        "gramWeight": 0,
        "invoiceNo": "",
        "merchentTransactionId": "",
        "note": "Discount",
        "staffId": _staffDetails?['id'],
        "staffName": _staffDetails?['staffName'],
        "timestamp": Timestamp.now(),
        "transactionMode": "Direct",
        "transactionType": 2
      };

      DocumentReference docRef =
          await firestore.collection("transactions").add(transactionData);
      String documentId = docRef.id;
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userid)
          .update({
        'balance': 0.0,
        'total_gram': 0.0,
      });
      // await FirebaseFirestore.instance.collection('collection').add({
      //   'staffId': _staffDetails?['id'],
      //   'staffname': _staffDetails?['staffName'],
      //   'recievedAmount': double.parse(_amountController.text),
      //   'paidAmount': 0,
      //   'balance': 0,
      //   'date': FieldValue.serverTimestamp(),
      //   'timestamp': FieldValue.serverTimestamp(),
      //   'type': 0,
      //   'branch': 1,
      //   "transactionMode": "Direct",
      //   "transactionId": documentId
      // });
      if (widget.token != null) {
        sendNotification("Transaction Completed", widget.token!,
            double.parse(_amountController.text));
      }
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
      // Clear form fields
      _clearForm();
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _amountController.clear();
    _gramController.clear();
    _noteController.clear();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _amountController.dispose();
    _gramController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return
        // Scaffold(
        // backgroundColor: Colors.blueGrey.shade50,
        // appBar: AppBar(
        //   backgroundColor: useColor.homeIconColor,
        //   title: Text('Add Opening Balance'),
        //   elevation: 0,
        // ),
        // body:
        //   SingleChildScrollView(
        // padding: const EdgeInsets.all(16.0),
        // child:
        Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 10),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildAmountField(),
          const SizedBox(height: 16),
          // _buildGramField(),
          // const SizedBox(height: 16),
          _buildNoteField(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
      // ),
      // ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Customer Name', widget.custName ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Receive Staff', _staffDetails?['staffName'] ?? 'Loading...'),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Current Balance', '₹ ${widget.balance!.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Amount",
        prefixIcon: Icon(Icons.monetization_on_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return "Enter amount";
        if (double.tryParse(value) == null) return "Enter a valid number";
        return null;
      },
    );
  }

  Widget _buildGramField() {
    return TextFormField(
      controller: _gramController,
      decoration: InputDecoration(
        labelText: "Gram",
        prefixIcon: Icon(Icons.scale_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return "Enter Gram";
        if (double.tryParse(value) == null) return "Enter a valid number";
        return null;
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: "Note (Optional)",
        prefixIcon: Icon(Icons.notes),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      maxLines: 3,
      minLines: 1,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _addTransaction,
      style: ElevatedButton.styleFrom(
        backgroundColor: useColor.homeIconColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: _isLoading
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : Text(
              "Submit Transaction",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  sendNotification(String title, String token, double amt) async {
    final data = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': 1,
      'status': 'done',
      'message': title,
    };
    try {
      http.Response response =
          await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
              headers: <String, String>{
                'Content-Type': 'application/json',
                'Authorization':
                    'key=AAAAYxF4bUQ:APA91bE-vvHQIfOI27flf420DjMEb1fkc0rlrFLz6N5HqVKvstpVEl-HzVmubii6ZDHDO5AYHVdvauIbGC0T-dS9yXskwgi4XVd38HOaix_hwBt7riU3tjDBdYx4mGAgglXPP3cEp5jX'
              },
              body: jsonEncode(<String, dynamic>{
                'notification': <String, dynamic>{
                  'title': title,
                  'body': 'Add RS $amt to your account'
                },
                'priority': 'high',
                'data': data,
                'to': "$token"
              }));

      if (response.statusCode == 200) {
        // print("notification is sended");
      } else {
        // print("error");
      }
    } catch (e) {}
  }
}
