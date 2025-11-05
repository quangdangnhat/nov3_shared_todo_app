import 'package:flutter/material.dart';
import '../../../../data/models/folder.dart';
import '../../../../data/repositories/folder_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Un dialog per creare o modificare una cartella.
class FolderDialog extends StatefulWidget {
  final String todoListId;
  final String? parentId; // ID della cartella padre in cui creare/modificare
  final Folder? folderToEdit; // Se non è null, siamo in modalità modifica

  const FolderDialog({
    super.key,
    required this.todoListId,
    this.parentId,
    this.folderToEdit,
  });

  @override
  State<FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<FolderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final FolderRepository _folderRepo = FolderRepository();
  bool _isLoading = false;

  bool get _isEditing => widget.folderToEdit != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.folderToEdit?.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // Logica di Modifica
        await _folderRepo.updateFolder(
          id: widget.folderToEdit!.id,
          title: _titleController.text.trim(),
        );
        // --- RIMOSSA SnackBar DA QUI ---
      } else {
        // Logica di Creazione
        await _folderRepo.createFolder(
          todoListId: widget.todoListId,
          title: _titleController.text.trim(),
          parentId: widget.parentId,
        );
        // --- RIMOSSA SnackBar DA QUI ---
      }
      // Chiudi il dialog in caso di successo
      if (mounted)
        Navigator.of(context).pop(true); // Passa true per indicare successo
    } catch (error) {
      // Mostra errore nel dialog (va bene qui perché il dialog non si chiude)
      if (mounted) {
        showErrorSnackBar(context,
            message:
                'Failed to ${_isEditing ? 'update' : 'create'} folder: $error');
      }
    } finally {
      // Disattiva il loading anche se c'è stato un errore
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing
          ? 'Edit Folder'
          : (widget.parentId == null
              ? 'Create New Folder'
              : 'Create Subfolder')),
      content: Form(
        key: _formKey,
        child: TextFormField(
          // Avvolto direttamente nel Form se è l'unico campo
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            prefixIcon: Icon(Icons.folder),
          ),
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a folder name';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.of(context).pop(false), // Passa false
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
