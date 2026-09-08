import 'package:flutter/material.dart';

import '../models/career.dart';
import '../models/career_shortlist.dart';
import '../repositories/career_shortlist_repository.dart';
import 'career_detail_screen.dart';
import 'edit_interested_career_screen.dart';

class InterestedCareersScreen extends StatefulWidget {
  const InterestedCareersScreen({
    super.key,
    this.repository,
    this.detailBuilder,
    this.editBuilder,
  });

  final CareerShortlistRepository? repository;
  final Widget Function(Career career)? detailBuilder;
  final Widget Function(
    CareerShortlist shortlist,
    CareerShortlistRepository repository,
  )?
  editBuilder;

  @override
  State<InterestedCareersScreen> createState() =>
      _InterestedCareersScreenState();
}

class _InterestedCareersScreenState extends State<InterestedCareersScreen> {
  late final CareerShortlistRepository _repository;
  List<CareerShortlist> _items = const [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseCareerShortlistRepository();
    _load();
  }

  Future<void> _load() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await _repository.getShortlistedCareers();
      if (mounted) setState(() => _items = _sort(items));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to load interested careers.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CareerShortlist> _sort(List<CareerShortlist> items) {
    const order = {'High': 0, 'Medium': 1, 'Low': 2};
    return [...items]..sort((a, b) {
      final priority = (order[a.priority] ?? 3).compareTo(
        order[b.priority] ?? 3,
      );
      return priority != 0
          ? priority
          : a.career.careerName.compareTo(b.career.careerName);
    });
  }

  Future<void> _edit(CareerShortlist item) async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute<Object>(
        builder: (_) =>
            widget.editBuilder?.call(item, _repository) ??
            EditInterestedCareerScreen(
              shortlist: item,
              repository: _repository,
            ),
      ),
    );
    if (!mounted || result == null) return;
    await _load();
  }

  Future<void> _remove(CareerShortlist item) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove interested career?'),
            content: Text('Remove ${item.career.careerName} from your list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _repository.removeCareer(item.id);
      if (!mounted) return;
      setState(
        () => _items = _items.where((value) => value.id != item.id).toList(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Career removed from interested careers.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to remove this career.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interested Careers')),
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No interested careers yet. Explore careers and save one to begin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final details = <String>[
            item.career.category,
            if (item.priority != null) '${item.priority} priority',
            if (item.notes != null) item.notes!,
          ];
          return Card(
            child: ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      widget.detailBuilder?.call(item.career) ??
                      CareerDetailScreen(career: item.career),
                ),
              ),
              title: Text(item.career.careerName),
              subtitle: Text(
                details.join('\n'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _edit(item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () => _remove(item),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
