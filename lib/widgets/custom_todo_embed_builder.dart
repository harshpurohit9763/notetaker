import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill; // Added this import
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class CustomTodoEmbedBuilder extends EmbedBuilder {
  const CustomTodoEmbedBuilder();

  @override
  String get key => quill.Attribute.list.key; // Changed to quill.Attribute.list.key

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final attributes = node.style.attributes;
    final isChecked = attributes[Attribute.list.key]?.value == 'checked' &&
        attributes[Attribute.checked.key]?.value == true;

    final text = node.toPlainText(); // Get the text content of the list item

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: readOnly
              ? null
              : () {
                  final newCheckedValue = !isChecked;
                  controller.formatText(
                    node.offset,
                    node.length,
                    quill.Attribute.fromKeyValue(quill.Attribute.checked.key, newCheckedValue),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 24.0, // Default size, can be customized later
              color: isChecked ? Colors.grey : Theme.of(context).iconTheme.color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: textStyle.copyWith(
              color: isChecked ? Colors.grey : textStyle.color,
              decoration:
                  isChecked ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}
