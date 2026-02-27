import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../api_service.dart';
import '../providers/picking_upload_provider.dart';
import 'login_screen.dart';

class PickingListScreen extends StatefulWidget {
  const PickingListScreen({super.key});

  @override
  _PickingListScreenState createState() => _PickingListScreenState();
}

class _PickingListScreenState extends State<PickingListScreen> {
  final _numberController = TextEditingController();
  final PickingUploadProvider _uploadProvider = PickingUploadProvider();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _numberController.dispose();
    _uploadProvider.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    // Usar file picker para soporte genérico de Windows y celular
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      _uploadProvider
          .addFiles(result.paths.map((path) => File(path!)).toList());
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _uploadProvider.addFiles([File(photo.path)]);
    }
  }

  Future<void> _scanOcr() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Simulador rápido para Desktop
      showDialog(
        context: context,
        builder: (context) {
          String mockValue = "PK-889922";
          return AlertDialog(
            title: Text('Simulador OCR (Escritorio)'),
            content: Text(
                'En un dispositivo móvil, aquí se abriría la cámara para leer el texto con ML Kit.\n\nSimularemos que la cámara escaneó el código: $mockValue'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _numberController.text = mockValue;
                  });
                  Navigator.pop(context);
                },
                child: Text('Usar Valor Simulado'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              )
            ],
          );
        },
      );
    } else {
      // Implementación real ML Kit para Android/iOS
      try {
        final XFile? image =
            await _picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          final inputImage = InputImage.fromFilePath(image.path);
          final textRecognizer =
              TextRecognizer(script: TextRecognitionScript.latin);
          final RecognizedText recognizedText =
              await textRecognizer.processImage(inputImage);

          String extracted = "";
          for (TextBlock block in recognizedText.blocks) {
            for (TextLine line in block.lines) {
              // Buscar patrón de números o letras de picking list
              if (line.text.isNotEmpty) {
                extracted = line.text.trim();
                break;
              }
            }
            if (extracted.isNotEmpty) break;
          }

          textRecognizer.close();

          if (extracted.isNotEmpty) {
            setState(() {
              _numberController.text = extracted;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'No detectamos un texto legible. Inténtalo de nuevo.')));
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al procesar OCR: $e')));
      }
    }
  }

  void _submit() async {
    if (_numberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingresa el número de Picking List')));
      return;
    }

    try {
      await _uploadProvider.savePickingList(_numberController.text);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Evidencia enviada con éxito!')));

      setState(() {
        _numberController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  void _logout() async {
    await ApiService.logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Nuevo Picking List', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: _logout),
        ],
      ),
      body: AnimatedBuilder(
          animation: _uploadProvider,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _numberController,
                        decoration: InputDecoration(
                          labelText: 'Número de Picking List',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.document_scanner,
                          color: Colors.blue[800], size: 32),
                      onPressed: _scanOcr,
                      tooltip: 'Escanear OCR con Cámara',
                    )
                  ]),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: Icon(Icons.photo_library),
                          label: Text('Galería'),
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: Icon(Icons.camera_alt),
                          label: Text('Cámara'),
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Evidencias Adjuntas (${_uploadProvider.totalCount})',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        if (_uploadProvider.totalCount > 0)
                          Text(
                              'Subidas: ${_uploadProvider.uploadedCount}/${_uploadProvider.totalCount}',
                              style: TextStyle(
                                  color: _uploadProvider.uploadingCount > 0
                                      ? Colors.orange
                                      : Colors.green[700],
                                  fontWeight: FontWeight.bold)),
                      ]),
                  if (_uploadProvider.uploadingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: LinearProgressIndicator(
                        value: _uploadProvider.totalCount == 0
                            ? null
                            : _uploadProvider.uploadedCount /
                                _uploadProvider.totalCount,
                      ),
                    ),
                  SizedBox(height: 8),
                  Expanded(
                    child: _uploadProvider.items.isEmpty
                        ? Center(
                            child: Text('Ninguna imagen seleccionada',
                                style: TextStyle(color: Colors.grey)))
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _uploadProvider.items.length,
                            itemBuilder: (context, index) {
                              final item = _uploadProvider.items[index];
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(item.file,
                                        fit: BoxFit.cover),
                                  ),
                                  if (item.isUploading)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white),
                                      ),
                                    ),
                                  if (item.hasError)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: IconButton(
                                          icon: Icon(Icons.refresh,
                                              color: Colors.white, size: 36),
                                          onPressed: () => _uploadProvider
                                              .retryUpload(index),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _uploadProvider.removeFile(index),
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle),
                                        child: Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (_uploadProvider.isSaving ||
                            _uploadProvider.uploadingCount > 0)
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green[700],
                      disabledBackgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                    ),
                    child: _uploadProvider.isSaving
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _uploadProvider.uploadingCount > 0
                                ? 'ESPERANDO SUBIDA...'
                                : 'ENVIAR AUDITORÍA',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
    );
  }
}
