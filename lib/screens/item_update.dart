import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventoryapp/db/database_helper.dart';
import 'dart:io';

class ItemUpdate extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemUpdate({super.key, required this.item});

  @override
  _ItemUpdateState createState() => _ItemUpdateState();
}

class _ItemUpdateState extends State<ItemUpdate> {
  final _receivedController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _receivedController.text = ''; // Empty text field
    _sellingPriceController.text = ''; // Empty text field

    // Initialize selected image
    if (widget.item['image'] != null) {
      _selectedImage = File(widget.item['image']);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _updateItem() async {
    final received = int.tryParse(_receivedController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? widget.item['sellingPrice'];
    final updatedStock = widget.item['stock'] + received;

    final updatedItem = {
      'id': widget.item['id'],
      'name': widget.item['name'],
      'buyingPrice': widget.item['buyingPrice'], // Keep original buying price
      'sellingPrice': sellingPrice,
      'stock': updatedStock,
      'image': _selectedImage?.path ?? widget.item['image'], // Update image if new one is selected
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                        image: _selectedImage != null
                            ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _selectedImage == null && widget.item['image'] == null
                          ? Center(
                        child: Text('Add Image', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      )
                          : _selectedImage == null
                          ? Center(
                        child: Text('Change Image', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      child: Text(_selectedImage == null ? 'Add Image' : 'Change Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.item['stock'].toString(),
                decoration: const InputDecoration(labelText: 'Available Stock'),
                enabled: false,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _receivedController,
                decoration: const InputDecoration(
                  labelText: 'Add Stock',
                  hintText: 'Enter quantity received',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price',
                  hintText: 'Enter new selling price',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _updateItem,
                    child: const Text('Update Item'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the screen without saving
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // Optional: change color to distinguish from Update button
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
