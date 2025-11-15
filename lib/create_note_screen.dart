import 'package:flutter/material.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:note_taker/create_note_view_model.dart';
import 'package:provider/provider.dart';

class CreateNoteScreen extends StatelessWidget {
  final String? templateTitle;
  final String? templateContent;
  final String? templateNoteType;

  const CreateNoteScreen({
    super.key,
    this.templateTitle,
    this.templateContent,
    this.templateNoteType,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateNoteViewModel(
        templateTitle: templateTitle,
        templateContent: templateContent,
        templateNoteType: templateNoteType,
      ),
      child: Consumer<CreateNoteViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color(0xFF000000),
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, viewModel),
                  Expanded(child: _buildBody(viewModel)),
                  if (!viewModel.showVoiceRecorder)
                    _buildQuillToolbar(viewModel),
                  _buildBottomToolbar(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuillToolbar(CreateNoteViewModel viewModel) {
    return quill.QuillToolbar(
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
            quill.QuillToolbarToggleStyleButton(
              controller: viewModel.quillController,
              attribute: quill.Attribute.bold,
            ),
            quill.QuillToolbarToggleStyleButton(
              controller: viewModel.quillController,
              attribute: quill.Attribute.italic,
            ),
            quill.QuillToolbarToggleStyleButton(
              controller: viewModel.quillController,
              attribute: quill.Attribute.underline,
            ),
            quill.QuillToolbarClearFormatButton(
              controller: viewModel.quillController,
            ),
            quill.QuillToolbarToggleStyleButton(
              controller: viewModel.quillController,
              attribute: quill.Attribute.strikeThrough,
            ),
            quill.QuillToolbarToggleStyleButton(
              controller: viewModel.quillController,
              attribute: quill.Attribute.ul,
            ),
            quill.QuillToolbarToggleStyleButton(
              controller: viewModel.quillController,
              attribute: quill.Attribute.ol,
            ),
            quill.QuillToolbarColorButton(
              isBackground: true,
              controller: viewModel.quillController,
            ),
            quill.QuillToolbarToggleStyleButton(
              controller: viewModel.quillController,
              attribute: quill.Attribute.codeBlock,
            ),
            quill.QuillToolbarToggleStyleButton(
              controller: viewModel.quillController,
              attribute: quill.Attribute.blockQuote,
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
    );
  }

  Widget _buildHeader(BuildContext context, CreateNoteViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // TODO: Implement more options
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CreateNoteViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            controller: viewModel.titleController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: 'Title',
              hintStyle: TextStyle(color: Color(0xFF8E8E93)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: viewModel.showVoiceRecorder
                ? _buildVoiceRecorder(viewModel)
                : _buildTextEditor(viewModel),
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
      ),
    );
  }

  Widget _buildVoiceRecorder(CreateNoteViewModel viewModel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (viewModel.isRecording)
          const Text('Recording...',
              style: TextStyle(color: Colors.red, fontSize: 16)),
        if (viewModel.audioPath != null && !viewModel.isRecording)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Recording saved!', style: TextStyle(color: Colors.green)),
            ],
          ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: viewModel.isRecording
              ? viewModel.stopRecording
              : viewModel.startRecording,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  viewModel.isRecording ? Colors.red : const Color(0xFFFF9500),
            ),
            child: Icon(
              viewModel.isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomToolbar(CreateNoteViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(
          top: BorderSide(color: Color(0xFF2C2C2E)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolbarButton(
              Icons.check_box_outline_blank, const Color(0xFF34C759), () {
            // TODO: Implement To-Do List
          }),
          _buildToolbarButton(Icons.mic, const Color(0xFFFF9500),
              viewModel.toggleVoiceRecorder),
          _buildToolbarButton(Icons.image, const Color(0xFF0A84FF), () {
            // TODO: Implement Add Image
          }),
          _buildToolbarButton(Icons.label, const Color(0xFF8E8E93), () {
            // TODO: Implement Tag/Label
          }),
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
