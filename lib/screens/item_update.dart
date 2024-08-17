import 'package:flutter/material.dart';
import 'package:inventoryapp/db/database_helper.dart';

class ItemUpdate extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemUpdate({super.key, required this.item});

  @override
  _ItemUpdateState createState() => _ItemUpdateState();
}

class _ItemUpdateState extends State<ItemUpdate> {
  final _soldController = TextEditingController();
  final _receivedController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _soldController.text = '0'; // Initialize with 0
    _receivedController.text = '0'; // Initialize with 0
    _priceController.text = widget.item['price'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              initialValue: widget.item['stock'].toString(),
              decoration: const InputDecoration(labelText: 'Available Stock'),
              enabled: false, // Disable editing for available stock
              style: const TextStyle(color: Colors.grey), // Gray out the text
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _receivedController,
              decoration: const InputDecoration(labelText: 'Add Stock'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _soldController,
              decoration: const InputDecoration(labelText: 'Sold'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Change Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateItem,
              child: const Text('Update Item'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateItem() async {
    final sold = int.tryParse(_soldController.text) ?? 0;
    final received = int.tryParse(_receivedController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? widget.item['price'];

    final updatedStock = widget.item['stock'] + received - sold;

    final updatedItem = {
      'id': widget.item['id'],
      'name': widget.item['name'],
      'price': price,
      'stock': updatedStock,
      'sold': widget.item['sold'] + sold,
      'image': widget.item['image'], // Keep the original image path
    };

    try {
      await DatabaseHelper.instance.update(updatedItem);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to update item. Please try again.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
