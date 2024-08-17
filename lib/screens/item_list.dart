import 'package:flutter/material.dart';
import 'package:inventoryapp/db/database_helper.dart';
import 'package:inventoryapp/screens/item_form.dart';
import 'package:inventoryapp/screens/item_update.dart';
import 'package:inventoryapp/screens/dashboard.dart';
import 'dart:io';

class ItemList extends StatefulWidget {
  const ItemList({super.key});

  @override
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  late Future<List<Map<String, dynamic>>> _items;
  List<int> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _refreshItemList();
  }

  Future<void> _refreshItemList() async {
    setState(() {
      _items = DatabaseHelper.instance.queryAll();
      _selectedItems.clear();
    });
  }

  void _toggleSelection(int itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    for (int id in _selectedItems) {
      await DatabaseHelper.instance.delete(id);
    }
    await _refreshItemList();
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Do you really want to delete the selected items?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSelectedItems();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory List'),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              final isSelected = _selectedItems.contains(item['id']);

              return ListTile(
                title: Text(item['name']),
                subtitle: Text(
                  'Price: KSH ${item['price'].toStringAsFixed(2)}, Stock: ${item['stock']}, Sold: ${item['sold']}',
                ),
                trailing: item['image'] != null
                    ? CircleAvatar(
                  backgroundImage: FileImage(File(item['image'])),
                  radius: 25,
                )
                    : const CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 25,
                  child: Icon(Icons.image, color: Colors.white),
                ),
                leading: _selectedItems.isNotEmpty
                    ? Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    _toggleSelection(item['id']);
                  },
                )
                    : null,
                onTap: () async {
                  if (_selectedItems.isNotEmpty) {
                    _toggleSelection(item['id']);
                  } else {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemUpdate(item: item),
                      ),
                    );
                    if (updated == true) {
                      _refreshItemList();
                    }
                  }
                },
                onLongPress: () {
                  _toggleSelection(item['id']);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ItemForm(),
            ),
          );
          if (added == true) {
            _refreshItemList();
          }
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
            // Already on the list screen, no action needed
              break;
            case 1:
            // Navigate to settings screen (implement this)
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
      ),
    );
  }
}
