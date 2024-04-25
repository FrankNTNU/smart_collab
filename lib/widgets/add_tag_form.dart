import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:smart_collab/widgets/confirm_dialog.dart';

import '../services/tag_controller.dart';
import '../utils/translation_keys.dart';
import 'color_pallete.dart';
import 'title_text.dart';

class AddOrEditTagForm extends ConsumerStatefulWidget {
  const AddOrEditTagForm(
      {super.key,
      required this.teamId,
      required this.addOrEdit,
      this.initialTag});
  final String teamId;
  final AddorEdit addOrEdit;
  final IssueTag? initialTag;
  @override
  ConsumerState<AddOrEditTagForm> createState() => _AddTagFormState();
}

class _AddTagFormState extends ConsumerState<AddOrEditTagForm> {
  // formkey
  final _formKey = GlobalKey<FormState>();
  // selected hex color
  String? _selectedHexColor;
  // entered tag name
  String? _enteredTagName;
  // error message
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _selectedHexColor = null;
    _enteredTagName = null;
    _errorMessage = null;
    if (widget.addOrEdit == AddorEdit.edit && widget.initialTag != null) {
      _selectedHexColor = widget.initialTag!.color;
      _enteredTagName = widget.initialTag!.name;
    }
  }

  void _submit() async {
    // trim the entered tag name
    _enteredTagName = _enteredTagName!.trim();
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;
    if (_enteredTagName == null || _enteredTagName!.isEmpty) {
      setState(() {
        _errorMessage = TranslationKeys.pleaseEnterSomething.tr(args: [
          TranslationKeys.tagName.tr(),
        ]);
      });
      return;
    }
    if (_selectedHexColor == null) {
      setState(() {
        _errorMessage = TranslationKeys.pleaseSelectSomething.tr(args: [
          TranslationKeys.tagColor.tr(),
        ]);
      });
      return;
    }
    if (widget.addOrEdit == AddorEdit.add) {
      final isExist =
          await ref.read(tagProvider(widget.teamId).notifier).isTagNameExists(
                _enteredTagName!,
              );
      if (isExist) {
        setState(() {
          _errorMessage = TranslationKeys.xHasDuplicate.tr(
            args: [_enteredTagName!],
          );
        });
        return;
      }
      ref.read(tagProvider(widget.teamId).notifier).addTag(
            name: _enteredTagName!,
            color: _selectedHexColor!,
          );
    }
    if (widget.addOrEdit == AddorEdit.edit) {
      final hasNameChanged = widget.initialTag!.name != _enteredTagName;
      if (hasNameChanged) {
        final isExist =
            await ref.read(tagProvider(widget.teamId).notifier).isTagNameExists(
                  _enteredTagName!,
                );
        if (isExist) {
          setState(() {
            _errorMessage = TranslationKeys.xHasDuplicate.tr(
              args: [_enteredTagName!],
            );
          });
          return;
        }
      }
      ref.read(tagProvider(widget.teamId).notifier).updateTag(
            tagId: widget.initialTag!.id,
            oldTagName: widget.initialTag!.name,
            newTagName: _enteredTagName,
            newColor: _selectedHexColor,
          );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TitleText(
                widget.addOrEdit == AddorEdit.add
                    ? '${TranslationKeys.add.tr()} ${TranslationKeys.tag.tr()}'
                    : '${TranslationKeys.edit.tr()} ${TranslationKeys.tag.tr()}',
              ),
              const CloseButton(),
            ],
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Padding(
padding: const EdgeInsets.symmetric(horizontal: 16),          child: Form(
            key: _formKey,
            child: TextFormField(
              initialValue: _enteredTagName,
              decoration: InputDecoration(
                hintText: TranslationKeys.tagName.tr(),
              ),
              onChanged: (value) {
                setState(() {
                  _enteredTagName = value;
                  _formKey.currentState!.validate();
                });
              },
              validator: (value) => value!.isEmpty
                  ? TranslationKeys.pleaseEnterSomething.tr(args: [
                      TranslationKeys.tagName.tr(),
                    ])
                  : null,
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(TranslationKeys.tagColor.tr()),
        ),
        ColorPallete(
          initialColor: _selectedHexColor,
          onSelected: (color) {
            setState(() {
              _selectedHexColor = color;
            });
          },
        ),
        if (_errorMessage != null)
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        // submit button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  _submit();
                },
                child: Text(widget.addOrEdit == AddorEdit.add
                    ? TranslationKeys.create.tr()
                    : TranslationKeys.update.tr()),
              ),
              const Spacer(),
              if (widget.addOrEdit == AddorEdit.edit)
                IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ConfirmDialog(
                          confirmText: TranslationKeys.delete.tr(),
                          title: TranslationKeys.delete.tr(),
                          content: TranslationKeys.confirmSomething.tr(args: [
                            TranslationKeys.delete.tr(),
                          ]),
                          onConfirm: () {
                            ref
                                .read(tagProvider(widget.teamId).notifier)
                                .removeTag(widget.initialTag!.id);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete)),
            ],
          ),
        )
      ],
    );
  }
}
