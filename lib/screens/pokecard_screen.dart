import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokemontcg/providers/pokemon_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokemontcg/screens/card_detail_screen.dart';
import '../models/pokemon_card.dart';
import 'dart:async';

class PokeCardScreen extends StatefulWidget {
  const PokeCardScreen({super.key});

  @override
  State<PokeCardScreen> createState() => _PokeCardScreenState();
}

class _PokeCardScreenState extends State<PokeCardScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isThreeColumns = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCards();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCards() async {
    await Provider.of<PokemonProvider>(context, listen: false).fetchCards();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        Provider.of<PokemonProvider>(context, listen: false).searchCards(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokemon Cards'),
        actions: [
          IconButton(
            icon: Icon(_isThreeColumns ? Icons.grid_view : Icons.grid_on),
            onPressed: () {
              setState(() {
                _isThreeColumns = !_isThreeColumns;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search Pokemon cards...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<PokemonProvider>(
                  builder: (context, provider, child) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All Types'),
                            selected: provider.selectedType == null,
                            onSelected: (selected) {
                              if (selected) {
                                provider.setSelectedType(null);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ...provider.types
                              .map(
                                (type) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(type),
                                    selected: type == provider.selectedType,
                                    onSelected: (selected) {
                                      provider.setSelectedType(
                                        selected ? type : null,
                                      );
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PokemonProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.cards.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.cards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${provider.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCards,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.cards.isEmpty) {
                  return const Center(child: Text('No cards found'));
                }

                return RefreshIndicator(
                  onRefresh: _loadCards,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _isThreeColumns ? 3 : 2,
                      childAspectRatio: _isThreeColumns ? 0.6 : 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.cards.length,
                    itemBuilder: (context, index) {
                      final card = provider.cards[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      CardDetailScreen(cardId: card.id),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: CachedNetworkImage(
                                            imageUrl: card.imageUrl,
                                            fit: BoxFit.contain,
                                            placeholder:
                                                (context, url) => const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (provider.isLoading)
                                      Container(
                                        color: Colors.black26,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (card.type != null)
                                      Text(
                                        card.type!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
