import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

import '../providers/picking_upload_provider.dart';

class MultipleCameraScreen extends StatefulWidget {
  final PickingUploadProvider uploadProvider;

  const MultipleCameraScreen({super.key, required this.uploadProvider});

  @override
  _MultipleCameraScreenState createState() => _MultipleCameraScreenState();
}

class _MultipleCameraScreenState extends State<MultipleCameraScreen> {
  final List<File> _capturedImages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.custom(
        saveConfig: SaveConfig.photo(),
        builder: (cameraState, preview) {
          return cameraState.when(
                onPreparingCamera: (state) =>
                    const Center(child: CircularProgressIndicator()),
                onPhotoMode: (state) => _buildCameraUI(state),
              ) ??
              const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildCameraUI(CameraState state) {
    return SafeArea(
      child: Column(
        children: [
          // Header with close button and count
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_capturedImages.length} fotos',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                SizedBox(width: 48), // Balance the row
              ],
            ),
          ),
          Spacer(),
          // Footer with capture button and finish button
          Container(
            padding: EdgeInsets.all(24),
            color: Colors.black38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Switch camera button
                AwesomeBouncingWidget(
                  onTap: () {
                    if (state is PhotoCameraState) {
                      state.switchCameraSensor();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.flip_camera_ios, color: Colors.white),
                  ),
                ),

                // Capture button
                AwesomeBouncingWidget(
                  onTap: () async {
                    if (state is PhotoCameraState) {
                      final captureRequest = await state.takePhoto();
                      captureRequest.when(
                          single: (single) {
                            if (single.file != null) {
                              final newFile = File(single.file!.path);
                              setState(() {
                                _capturedImages.add(newFile);
                              });
                              // Upload immediately
                              widget.uploadProvider.addFiles([newFile]);
                            }
                          },
                          multiple: (multiple) {} // Not used for normal photo
                          );
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // Finish button
                AwesomeBouncingWidget(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
