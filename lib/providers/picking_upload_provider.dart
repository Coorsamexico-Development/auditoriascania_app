import 'dart:io';

import 'package:flutter/material.dart';

import '../api_service.dart';

class EvidenceItem {
  final File file;
  int? tempId;
  bool isUploading;
  bool hasError;

  EvidenceItem({
    required this.file,
    this.tempId,
    this.isUploading = false,
    this.hasError = false,
  });
}

class PickingUploadProvider extends ChangeNotifier {
  final List<EvidenceItem> items = [];
  bool isSaving = false;

  int get uploadingCount => items.where((i) => i.isUploading).length;
  int get uploadedCount => items.where((i) => i.tempId != null).length;
  int get totalCount => items.length;
  bool get hasErrors => items.any((i) => i.hasError);

  void addFiles(List<File> files) {
    for (var file in files) {
      final item = EvidenceItem(file: file, isUploading: true);
      items.add(item);
      _uploadSingleFile(item);
    }
    notifyListeners();
  }

  Future<void> _uploadSingleFile(EvidenceItem item) async {
    try {
      item.tempId = await ApiService.uploadTemporaryEvidence(item.file.path);
      item.isUploading = false;
      item.hasError = false;
    } catch (e) {
      item.isUploading = false;
      item.hasError = true;
    }
    notifyListeners();
  }

  void removeFile(int index) {
    items.removeAt(index);
    notifyListeners();
  }

  void retryUpload(int index) {
    final item = items[index];
    if (item.hasError) {
      item.isUploading = true;
      item.hasError = false;
      notifyListeners();
      _uploadSingleFile(item);
    }
  }

  Future<bool> savePickingList(String number) async {
    if (uploadingCount > 0) {
      throw Exception(
          'Todavía hay $uploadingCount imágenes subiéndose. Por favor espera.');
    }
    if (items.isEmpty) {
      throw Exception('Añade al menos una imagen de evidencia.');
    }
    if (hasErrors) {
      throw Exception(
          'Hay imágenes con error. Por favor reintenta o elimínalas.');
    }

    isSaving = true;
    notifyListeners();

    try {
      final tempIds = items.map((i) => i.tempId!).toList();
      await ApiService.createPickingList(number, tempIds);

      items.clear();
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      notifyListeners();
      throw e;
    }
  }
}
