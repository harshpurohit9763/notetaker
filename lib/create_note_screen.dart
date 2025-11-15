import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:note_taker/create_note_view_model.dart';
import 'package:note_taker/widgets/custom_audio_embed_builder.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:note_taker/note_model.dart'; // Import Note model
import 'package:note_taker/widgets/custom_todo_embed_builder.dart'; // Import CustomTodoEmbedBuilder

extension ColorExtension on Color {
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

class CreateNoteScreen extends StatelessWidget {
  final String? templateTitle;
  final String? templateContent;
  final String? templateNoteType;
  final Note? note; // New optional parameter for editing

  const CreateNoteScreen({
    super.key,
    this.templateTitle,
    this.templateContent,
    this.templateNoteType,
    this.note, // Initialize new parameter
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateNoteViewModel(
        templateTitle: templateTitle,
        templateContent: templateContent,
        note: note, // Pass the note to the ViewModel
      ),
      child: Consumer<CreateNoteViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, viewModel),
                  Expanded(child: _buildBody(context, viewModel)),
                  if (viewModel.isRecordingUiVisible)
                    _buildRecordingUi(context, viewModel),
                  _buildQuillToolbar(viewModel, context),
                  _buildBottomToolbar(context, viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingUi(
      BuildContext context, CreateNoteViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: viewModel.togglePauseResume,
            icon: Icon(
              viewModel.recorderController.recorderState.isPaused
                  ? Icons.play_arrow
                  : Icons.pause,
              color: Colors.white,
            ),
          ),
          AudioWaveforms(
            size: Size(MediaQuery.of(context).size.width * 0.5, 50),
            recorderController: viewModel.recorderController,
            waveStyle: const WaveStyle(
              waveColor: Colors.white,
              showDurationLabel: true,
              spacing: 8.0,
              durationLinesColor: Colors.white,
              durationStyle: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () => viewModel.stopRecording(),
            icon: const Icon(Icons.stop, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuillToolbar(
      CreateNoteViewModel viewModel, BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: quill.QuillToolbar(
          configurations: const quill.QuillToolbarConfigurations(
            sharedConfigurations: quill.QuillSharedConfigurations(
              locale: Locale('en'),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                quill.QuillToolbarHistoryButton(
                  controller: viewModel.quillController,
                  isUndo: true,
                ),
                quill.QuillToolbarHistoryButton(
                  controller: viewModel.quillController,
                  isUndo: false,
                ),
                _CustomQuillToolbarToggleStyleButton(
                  icon: Icons.format_bold,
                  attribute: quill.Attribute.bold,
                  viewModel: viewModel,
                ),
                _CustomQuillToolbarToggleStyleButton(
                  icon: Icons.format_italic,
                  attribute: quill.Attribute.italic,
                  viewModel: viewModel,
                ),
                _CustomQuillToolbarToggleStyleButton(
                  icon: Icons.format_underline,
                  attribute: quill.Attribute.underline,
                  viewModel: viewModel,
                ),
                quill.QuillToolbarClearFormatButton(
                  controller: viewModel.quillController,
                ),
                _CustomQuillToolbarToggleStyleButton(
                  icon: Icons.format_strikethrough,
                  attribute: quill.Attribute.strikeThrough,
                  viewModel: viewModel,
                ),
                _CustomQuillToolbarToggleStyleButton(
                  icon: Icons.format_list_bulleted,
                  attribute: quill.Attribute.ul,
                  viewModel: viewModel,
                ),
                _CustomQuillToolbarToggleStyleButton(
                  icon: Icons.format_list_numbered,
                  attribute: quill.Attribute.ol,
                  viewModel: viewModel,
                ),
                // Custom Color Picker Button
                IconButton(
                  icon: const Icon(Icons.format_color_fill),
                  color: Theme.of(context)
                      .iconTheme
                      .color, // Access context from the build method
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        Color pickerColor = viewModel.quillController
                                    .getSelectionStyle()
                                    .attributes[quill.Attribute.background.key]
                                    ?.value !=
                                null
                            ? Color(viewModel.quillController
                                .getSelectionStyle()
                                .attributes[quill.Attribute.background.key]!
                                .value)
                            : Colors
                                .black; // Default to black if no background color is set

                        return AlertDialog(
                          title: const Text('Pick a color!'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: pickerColor,
                              onColorChanged: (color) {
                                pickerColor = color;
                              },
                              colorPickerWidth: 300.0,
                              pickerAreaHeightPercent: 0.7,
                              enableAlpha: false,
                              displayThumbColor: true,
                              paletteType: PaletteType.hueWheel,
                              labelTypes: const [], // Hide labels
                              pickerAreaBorderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2.0),
                                topRight: Radius.circular(2.0),
                              ),
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Got it'),
                              onPressed: () {
                                viewModel.quillController.formatSelection(
                                  quill.Attribute.fromKeyValue(
                                      quill.Attribute.background.key,
                                      pickerColor.toHex()),
                                );
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                _CustomQuillToolbarToggleStyleButton(
                  icon: Icons.code,
                  attribute: quill.Attribute.codeBlock,
                  viewModel: viewModel,
                ),
                _CustomQuillToolbarToggleStyleButton(
                  icon: Icons.format_quote,
                  attribute: quill.Attribute.blockQuote,
                  viewModel: viewModel,
                ),
                quill.QuillToolbarIndentButton(
                  controller: viewModel.quillController,
                  isIncrease: true,
                ),
                quill.QuillToolbarIndentButton(
                  controller: viewModel.quillController,
                  isIncrease: false,
                ),
                quill.QuillToolbarLinkStyleButton(
                  controller: viewModel.quillController,
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildHeader(BuildContext context, CreateNoteViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            icon: Icon(Icons.arrow_back_ios,
                color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => viewModel.saveNote(context),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, CreateNoteViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _TitleInputField(
            titleController: viewModel.titleController,
            titleFocusNode: viewModel.titleFocusNode,
            onRequestQuillFocus: viewModel.requestQuillFocus,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildTextEditor(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildTextEditor(CreateNoteViewModel viewModel) {
    return quill.QuillEditor.basic(
      configurations: quill.QuillEditorConfigurations(
        controller: viewModel.quillController,
        sharedConfigurations: const quill.QuillSharedConfigurations(
          locale: Locale('en'),
        ),
        customStyles: quill.DefaultStyles(
          code: quill.DefaultTextBlockStyle(
            const TextStyle(
              color: Color(0xFFD4D4D4), // VS Code text color
              fontFamily: 'monospace', // Generic monospace font
              fontSize: 14,
            ),
            // Positional argument 2
            const quill.VerticalSpacing(
                10, 10), // Positional argument 3 (block spacing)
            const quill.VerticalSpacing(
                0, 0), // Positional argument 4 (line spacing)
            BoxDecoration(
              // Positional argument 5
              color: const Color(0xFF1E1E1E), // VS Code background color
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        embedBuilders: [
          ...FlutterQuillEmbeds.editorBuilders()
              .where((builder) => builder.key != quill.Attribute.list.key),
          const CustomTodoEmbedBuilder(),
          AudioEmbedBuilder(),
        ],
      ),
      focusNode: viewModel.quillFocusNode,
    );
  }

  Widget _buildBottomToolbar(
      BuildContext context, CreateNoteViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(
          top: BorderSide(color: Color(0xFF2C2C2E)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolbarButton(
              Icons.check_box_outline_blank, const Color(0xFF34C759), () {
            viewModel.addTodoTemplate();
          }),
          _buildToolbarButton(
              Icons.mic, const Color(0xFFFF9500), viewModel.toggleRecordingUi),
          _buildToolbarButton(Icons.image, const Color(0xFF0A84FF), () {
            viewModel.insertImage();
          }),
          // _buildToolbarButton(Icons.color_lens, const Color(0xFF0A84FF), () {
          //   // TODO: Implement Change Color
          // }),
          // _buildToolbarButton(Icons.label, const Color(0xFF8E8E93), () {
          //   // TODO: Implement Tag/Label
          // }),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: color, size: 28),
      onPressed: onPressed,
    );
  }
}

class _TitleInputField extends StatelessWidget {
  const _TitleInputField({
    required this.titleController,
    required this.titleFocusNode,
    required this.onRequestQuillFocus,
  });

  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final VoidCallback onRequestQuillFocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: titleController,
      focusNode: titleFocusNode,
      onSubmitted: (_) => onRequestQuillFocus(),
      textInputAction: TextInputAction
          .next, // Indicate that pressing Enter will move to the next input field
      style: TextStyle(
        color: Theme.of(context).textTheme.titleLarge?.color,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      decoration: const InputDecoration(
        hintText: 'Title',
        hintStyle: TextStyle(color: Color(0xFF8E8E93)),
        border: InputBorder.none,
      ),
    );
  }
}

class _CustomQuillToolbarToggleStyleButton extends StatefulWidget {
  const _CustomQuillToolbarToggleStyleButton({
    required this.icon,
    required this.attribute,
    required this.viewModel,
  });

  final IconData icon;
  final quill.Attribute attribute;
  final CreateNoteViewModel viewModel;

  @override
  State<_CustomQuillToolbarToggleStyleButton> createState() =>
      _CustomQuillToolbarToggleStyleButtonState();
}

class _CustomQuillToolbarToggleStyleButtonState
    extends State<_CustomQuillToolbarToggleStyleButton> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(milliseconds: 300)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    widget.viewModel.toggleAttribute(widget.attribute, _tapCount);
  }

  @override
  Widget build(BuildContext context) {
    final isToggled = widget.viewModel.quillController
        .getSelectionStyle()
        .attributes
        .containsKey(widget.attribute.key);
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToggled ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          widget.icon,
          color: Theme.of(context).iconTheme.color,
          size: 22,
        ),
      ),
    );
  }
}
