import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_collab/widgets/cover_image.dart';

class TeamImagePicker extends StatefulWidget {
  // imageOnSelect
  final void Function(File selectedImage) imageOnSelect;
  // default image file
  final String? defaultImageUrl;
  const TeamImagePicker(
      {super.key, required this.imageOnSelect, this.defaultImageUrl});

  @override
  State<TeamImagePicker> createState() => _TeamImagePickerState();
}

class _TeamImagePickerState extends State<TeamImagePicker> {
  File? _pickedImage;
  @override
  void initState() {
    super.initState();
    print('Default image url: ${widget.defaultImageUrl}');
    if (widget.defaultImageUrl?.isNotEmpty == true) {
      setState(() {
        _pickedImage = File(widget.defaultImageUrl!);
      });
    }
  }

  void _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 0,
    );
    if (pickedImage == null) {
      return;
    }
    final bytes = await pickedImage.length();
    print('Picked image size: ${bytes ~/ 1024} KB');
    final pickedImageFile = File(pickedImage.path);
    widget.imageOnSelect(pickedImageFile);
    setState(() {
      _pickedImage = pickedImageFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // image size
        // GreyDescription(
        //   'Image size: ${_pickedImage?.lengthSync() ?? 0} bytes',
        // ),
        InkWell(
          onTap: () => _pickImage(),
          child: ClipPath(
            clipper: ShapeBorderClipper(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Container(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              width: double.infinity,
              height: 128,
              child: _pickedImage != null
                  ? widget.defaultImageUrl?.isNotEmpty == true &&
                          _pickedImage!.path == widget.defaultImageUrl
                      ? // network image
                      CoverImage(
                          imageUrl: widget.defaultImageUrl!,
                          canViewFullImage: false,
                        )
                      : Image.file(
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
        ),
      ],
    );
  }
}
