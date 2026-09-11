import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/certification.dart';
import '../repositories/certification_repository.dart';

class CertificationScreen extends StatefulWidget {
  const CertificationScreen({super.key, this.repository});

  final CertificationRepository? repository;

  @override
  State<CertificationScreen> createState() => _CertificationScreenState();
}

class _CertificationScreenState extends State<CertificationScreen> {
  late final CertificationRepository _repository;
  late Future<List<Certification>> _certifications;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CertificationRepository();
    _certifications = _repository.getCertifications();
  }

  Future<void> _reload() async {
    setState(() => _certifications = _repository.getCertifications());
    await _certifications;
  }

  Future<void> _openUpload() async {
    final certification = await showModalBottomSheet<Certification>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CertificationUploadSheet(repository: _repository),
    );
    if (certification != null && mounted) {
      await _reload();
      _message('Certification uploaded successfully.');
    }
  }

  Future<void> _delete(Certification certification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete certification?'),
        content: Text('Remove ${certification.title} from your profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteCertification(certification);
      if (mounted) {
        await _reload();
        _message('Certification removed.');
      }
    } catch (_) {
      if (mounted) _message('Unable to remove this certification.');
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certifications')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUpload,
        icon: const Icon(Icons.add),
        label: const Text('Add Certificate'),
      ),
      body: FutureBuilder<List<Certification>>(
        future: _certifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(onRetry: _reload);
          }
          final items = snapshot.data ?? const <Certification>[];
          if (items.isEmpty) {
            return const Center(child: Text('No certifications added yet.'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _CertificationCard(
                  certification: item,
                  onDelete: () => _delete(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CertificationUploadSheet extends StatefulWidget {
  const _CertificationUploadSheet({required this.repository});

  final CertificationRepository repository;

  @override
  State<_CertificationUploadSheet> createState() =>
      _CertificationUploadSheetState();
}

class _CertificationUploadSheetState extends State<_CertificationUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _issuerController = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _bytes;
  String? _fileName;
  String? _fileType;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _issuerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _bytes = bytes;
        _fileName = file.name;
        _fileType = 'image/${file.name.split('.').last.toLowerCase()}';
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Camera or gallery access was not available.');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      final file = files.isEmpty ? null : files.single;
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _fileName = file.name;
        _fileType = _contentType(file.extension);
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Unable to open the document picker.');
    }
  }

  String _contentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _bytes == null) {
      setState(() => _error = 'Please choose a certificate image or PDF.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final certification = await widget.repository.uploadCertification(
        title: _titleController.text,
        issuer: _issuerController.text,
        fileName: _fileName!,
        fileType: _fileType!,
        bytes: _bytes!,
      );
      if (mounted) Navigator.pop(context, certification);
    } catch (error) {
      debugPrint('Certificate upload failed: $error');
      if (mounted) {
        setState(() => _error = 'Upload failed: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add certification',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Certificate title',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Certificate title is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issuerController,
                decoration: const InputDecoration(labelText: 'Issuer'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickDocument,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('File'),
                  ),
                ],
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 12),
                Text('Selected: $_fileName'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFFF4D4D))),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Upload certificate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificationCard extends StatelessWidget {
  const _CertificationCard({
    required this.certification,
    required this.onDelete,
  });

  final Certification certification;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isImage = certification.fileType.startsWith('image/');
    return Card(
      child: ListTile(
        leading: isImage
            ? Image.network(
                certification.fileUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.picture_as_pdf_outlined, size: 36),
        title: Text(certification.title),
        subtitle: Text('${certification.issuer}\n${certification.fileName}'),
        isThreeLine: true,
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4D4D)),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
    );
  }
}
