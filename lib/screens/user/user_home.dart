import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/providers/request_provider.dart';
import '../../models/cloth.dart';
import '../../providers/auth_providers.dart';
import '../../providers/clothes_provider.dart';

// Provider to manage the user's selected items (shopping cart)
final selectedItemsProvider = StateProvider<Map<String, int>>((ref) => {});

class UserHome extends ConsumerStatefulWidget {
  const UserHome({super.key});

  @override
  ConsumerState<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends ConsumerState<UserHome> {
  bool _isSubmitting = false;
  String _searchQuery = '';

  Future<void> _submitRequest() async {
    final selectedItems = ref.read(selectedItemsProvider);
    final requestService = ref.read(requestServiceProvider);
    final authService = ref.read(authServiceProvider);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in.')),
      );
      return;
    }

    if (selectedItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      await requestService.submitRequest(userId, selectedItems);
      if (!mounted) return;
      ref.read(selectedItemsProvider.notifier).state = {}; // Clear the cart
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Helper method to group clothes by category
  Map<String, List<Cloth>> _groupClothesByCategory(List<Cloth> clothes) {
    final Map<String, List<Cloth>> grouped = {};
    for (var cloth in clothes) {
      if (!grouped.containsKey(cloth.category)) {
        grouped[cloth.category] = [];
      }
      grouped[cloth.category]!.add(cloth);
    }
    return grouped;
  }

  // Helper method to filter clothes based on search query
  List<Cloth> _filterClothes(List<Cloth> clothes) {
    if (_searchQuery.isEmpty) {
      return clothes;
    }
    return clothes.where((cloth) {
      return cloth.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Helper method to build the quantity controls for each item
  Widget _buildQuantityControls(WidgetRef ref, Cloth cloth) {
    final selectedItems = ref.watch(selectedItemsProvider);
    final quantity = selectedItems[cloth.id] ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: quantity > 0
              ? () {
                  ref.read(selectedItemsProvider.notifier).update((state) {
                    final newState = Map<String, int>.from(state);
                    if (quantity == 1) {
                      newState.remove(cloth.id);
                    } else {
                      newState[cloth.id] = quantity - 1;
                    }
                    return newState;
                  });
                }
              : null,
        ),
        Text('$quantity'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: quantity < cloth.quantity
              ? () {
                  ref.read(selectedItemsProvider.notifier).update((state) {
                    final newState = Map<String, int>.from(state);
                    newState[cloth.id] = quantity + 1;
                    return newState;
                  });
                }
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final clothesAsyncValue = ref.watch(clothesProvider);
    final selectedItems = ref.watch(selectedItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clothes Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (!mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Enter a cloth name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: clothesAsyncValue.when(
              data: (clothes) {
                final filteredClothes = _filterClothes(clothes);
                final groupedClothes = _groupClothesByCategory(filteredClothes);

                if (filteredClothes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No clothes available.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: groupedClothes.entries.map((entry) {
                    final category = entry.key;
                    final categoryClothes = entry.value;
                    return ExpansionTile(
                      title: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: categoryClothes.map((cloth) {
                        return ListTile(
                          leading: Image.network(
                            cloth.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(cloth.name),
                          subtitle: Text('Available: ${cloth.quantity}'),
                          trailing: _buildQuantityControls(ref, cloth),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: selectedItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSubmitting ? null : _submitRequest,
              label: _isSubmitting
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Text('Submit Request'),
              icon: _isSubmitting ? null : const Icon(Icons.send),
            )
          : null,
    );
  }
}
