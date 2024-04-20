import 'dart:math';

import 'package:flutter/material.dart';

class ColorPallete extends StatefulWidget {
  // onSelected
  final Function(String) onSelected;
  final String? initialColor;
  const ColorPallete({super.key, required this.onSelected, this.initialColor});

  @override
  State<ColorPallete> createState() => _ColorPalleteState();
}

class _ColorPalleteState extends State<ColorPallete> {
  List<String> generatedHexColors = [];
  // currently selected hex color
  String? _selectedHexColor;
  @override
  void initState() {
    super.initState();
    setGenerateRandomColors(10);
    if (widget.initialColor != null) {
      setState(() {
        _selectedHexColor = '#${widget.initialColor}';
        // add the initial color to the generated colors
        generatedHexColors.insert(0, '#${widget.initialColor}');
      });
    }
  }

  void setGenerateRandomColors(int num) {
    Random random = Random();
    setState(() {
      generatedHexColors = List.generate(
        num,
        (index) {
          // Generate random values biased towards higher values for lighter colors
          final r =
              random.nextInt(128) + 128; // Random value between 128 and 255
          final g =
              random.nextInt(128) + 128; // Random value between 128 and 255
          final b =
              random.nextInt(128) + 128; // Random value between 128 and 255

          // Add a fixed offset to each component to make the colors lighter
          const offset = 20;
          final adjustedR = min(255, r + offset);
          final adjustedG = min(255, g + offset);
          final adjustedB = min(255, b + offset);

          return '#${adjustedR.toRadixString(16).padLeft(2, '0')}${adjustedG.toRadixString(16).padLeft(2, '0')}${adjustedB.toRadixString(16).padLeft(2, '0')}';
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        itemCount: generatedHexColors.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedHexColor = generatedHexColors[index];
                });
                widget.onSelected(generatedHexColors[index].replaceAll('#', ''));
              },
              child: CircleAvatar(
                  radius: MediaQuery.of(context).size.width * 0.06,
                  backgroundColor: Color(int.parse(
                      generatedHexColors[index].replaceFirst('#', '0xFF'))),
                  child: // if it is selected, show a check icon
                      _selectedHexColor == generatedHexColors[index]
                          ? const Icon(Icons.check, color: Colors.black)
                          : null),
            ),
          );
        },
      ),
    );
  }
}
