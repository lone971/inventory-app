import 'package:flutter/material.dart';
import 'package:inventoryapp/db/database_helper.dart';
import 'package:inventoryapp/screens/item_form.dart';
import 'package:inventoryapp/screens/item_update.dart';
import 'package:inventoryapp/screens/dashboard.dart';
import 'package:inventoryapp/screens/sell.dart';
import 'dart:io';

class ItemList extends StatefulWidget {
  const ItemList({super.key});

  @override
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  List<Map<String, dynamic>> _filteredItems = [];
  List<int> _selectedItems = [];
  bool _isGridView = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshItemList();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _refreshItemList() async {
    final items = await DatabaseHelper.instance.queryAll();
    setState(() {
      _filteredItems = items;
      _selectedItems.clear();
    });
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _refreshItemList();
      } else {
        _filteredItems = _filteredItems
            .where((item) => item['name']
            .toLowerCase()
            .startsWith(_searchController.text.toLowerCase()))
            .toList();
      }
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

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    final isSelected = _selectedItems.contains(item['id']);
    return GestureDetector(
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
      child: Stack(
        children: [
          Card(
            elevation: 5,
            margin: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                item['image'] != null
                    ? Image.file(
                  File(item['image']),
                  fit: BoxFit.cover,
                  height: 80,
                  width: double.infinity,
                )
                    : Container(
                  height: 80,
                  color: Colors.grey,
                  child: const Icon(Icons.image, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buying Price: KSH ${item['buyingPrice'].toStringAsFixed(2)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Selling Price: KSH ${item['sellingPrice'].toStringAsFixed(2)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Stock: ${item['stock']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_isGridView)
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.attach_money, size: 16),
                                SizedBox(width: 4),
                                Text('Sell', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Sell(item: item),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _refreshItemList();
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 4),
                                Text('Update', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemUpdate(item: item),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _refreshItemList();
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  ButtonBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.attach_money, size: 16),
                            SizedBox(width: 4),
                            Text('Sell', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Sell(item: item),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _refreshItemList();
                            }
                          });
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 4),
                            Text('Update', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemUpdate(item: item),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _refreshItemList();
                            }
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 20,
                height: 60,
                margin: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.rectangle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedItems.isEmpty
            ? const Text('Inventory List')
            : Text('${_selectedItems.length} selected'),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  Dashboard()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(
              child: Text('No items found.'),
            )
                : _isGridView
                ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
              ),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return _buildItemCard(_filteredItems[index], index);
              },
            )
                : ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return _buildItemCard(_filteredItems[index], index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newItem = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ItemForm()),
          );
          if (newItem != null) {
            _refreshItemList();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
