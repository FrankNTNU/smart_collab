import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TeamImagePicker extends StatefulWidget {
  // imageOnSelect
  final void Function(File selectedImage) imageOnSelect;
  const TeamImagePicker({super.key, required this.imageOnSelect});

  @override
  State<TeamImagePicker> createState() => _TeamImagePickerState();
}

class _TeamImagePickerState extends State<TeamImagePicker> {
  File? _pickedImage;

  void _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage == null) {
      return;
    }
    final pickedImageFile = File(pickedImage.path);
    widget.imageOnSelect(pickedImageFile);
    setState(() {
      _pickedImage = pickedImageFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickImage(),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 128,        
          child: _pickedImage != null
              ? Image.file(
                  _pickedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : // add image icon
              const Icon(
                  Icons.image,
                ),
        ),
      ),
    );
  }
}
