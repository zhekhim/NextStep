import 'package:flutter/material.dart';

import '../models/career.dart';
import '../repositories/career_repository.dart';
import '../widgets/career_card.dart';
import 'career_detail_screen.dart';

typedef CareerLoader = Future<List<Career>> Function();

class CareerExplorerScreen extends StatefulWidget {
  const CareerExplorerScreen({
    super.key,
    this.loadCareers,
    this.careerDetailBuilder,
  });

  final CareerLoader? loadCareers;
  final Widget Function(Career career)? careerDetailBuilder;

  @override
  State<CareerExplorerScreen> createState() => _CareerExplorerScreenState();
}

class _CareerExplorerScreenState extends State<CareerExplorerScreen> {
  static const String _allCategories = 'All Categories';

  List<Career> _careers = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = _allCategories;

  CareerLoader get _loadFromSource =>
      widget.loadCareers ?? CareerRepository().getCareers;

  @override
  void initState() {
    super.initState();
    _loadCareers();
  }

  Future<void> _loadCareers() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final careers = await _loadFromSource();
      if (!mounted) return;
      setState(() {
        _careers = careers;
        final categories = careers.map((career) => career.category).toSet();
        if (!categories.contains(_selectedCategory)) {
          _selectedCategory = _allCategories;
        }
      });
    } catch (error) {
      debugPrint('Unable to load careers: $error');
      if (mounted) setState(() => _errorMessage = 'Unable to load careers.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Careers')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _careers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading careers...'),
          ],
        ),
      );
    }
    if (_errorMessage != null && _careers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _loadCareers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final categories =
        _careers.map((career) => career.category).toSet().toList()..sort();
    final query = _searchQuery.trim().toLowerCase();
    final filteredCareers = _careers.where((career) {
      return career.careerName.toLowerCase().contains(query) &&
          (_selectedCategory == _allCategories ||
              career.category == _selectedCategory);
    }).toList();

    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search careers...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: [_allCategories, ...categories]
              .map(
                (category) =>
                    DropdownMenuItem(value: category, child: Text(category)),
              )
              .toList(),
          onChanged: (category) {
            if (category != null) setState(() => _selectedCategory = category);
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredCareers.isEmpty
              ? const Center(child: Text('No careers found.'))
              : ListView.builder(
                  itemCount: filteredCareers.length,
                  itemBuilder: (context, index) {
                    final career = filteredCareers[index];
                    return CareerCard(
                      career: career,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              widget.careerDetailBuilder?.call(career) ??
                              CareerDetailScreen(career: career),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
