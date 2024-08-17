import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventoryapp/db/database_helper.dart';

class ItemForm extends StatefulWidget {
  final Map<String, dynamic>? item;

  const ItemForm({super.key, this.item});

  @override
  _ItemFormState createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!['name'];
      _priceController.text = widget.item!['price'].toString();
      _stockController.text = widget.item!['stock'].toString();
      if (widget.item!['image'] != null) {
        _image = File(widget.item!['image']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_image != null)
                Image.file(
                  _image!,
                  height: 150,
                  fit: BoxFit.cover,
                )
              else
                const Icon(
                  Icons.inventory,
                  size: 150,
                  color: Colors.grey,
                ),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveItem,
                child: Text(widget.item == null ? 'Add Item' : 'Update Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _saveItem() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _stockController.text.isEmpty) {
      _showErrorDialog('All fields are required.');
      return;
    }

    final item = {
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'stock': int.tryParse(_stockController.text) ?? 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'image': _image?.path, // Store the image path if available
    };

    try {
      if (widget.item == null) {
        await DatabaseHelper.instance.insert(item);
      } else {
        await DatabaseHelper.instance
            .update({...item, 'id': widget.item!['id']});
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to save item. Please try again.');
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
