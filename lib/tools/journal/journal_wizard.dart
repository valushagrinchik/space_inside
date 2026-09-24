import 'package:flutter/material.dart';

enum JournalInputType { text, slider }

class JournalStep {
  final String key;
  final String prompt;
  final JournalInputType inputType;
  final int minLines;
  final int maxLines;
  final double min;
  final double max;
  final int divisions;
  final String? label;

  const JournalStep({
    required this.key,
    required this.prompt,
    this.inputType = JournalInputType.text,
    this.minLines = 3,
    this.maxLines = 10,
    this.min = 0,
    this.max = 10,
    this.divisions = 10,
    this.label,
  });
}

class JournalWizard extends StatefulWidget {
  final String title;
  final List<JournalStep> steps;
  final String nextLabel;
  final String backLabel;
  final String saveLabel;

  const JournalWizard({
    super.key,
    required this.title,
    required this.steps,
    this.nextLabel = 'Далее',
    this.backLabel = 'Назад',
    this.saveLabel = 'Сохранить',
  });

  @override
  State<JournalWizard> createState() => _JournalWizardState();
}

class _JournalWizardState extends State<JournalWizard> {
  late final PageController _pageController;
  late final Map<String, TextEditingController> _textControllers;
  final Map<String, double> _sliderValues = {};
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _textControllers = <String, TextEditingController>{};
    for (final step in widget.steps) {
      if (step.inputType == JournalInputType.text) {
        _textControllers[step.key] = TextEditingController();
      } else {
        _sliderValues[step.key] = step.min;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _collect() {
    final result = <String, dynamic>{};
    for (final step in widget.steps) {
      if (step.inputType == JournalInputType.text) {
        result[step.key] = _textControllers[step.key]!.text;
      } else {
        result[step.key] = _sliderValues[step.key] ?? step.min;
      }
    }
    return result;
  }

  void _next() {
    if (_current < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop(_collect());
    }
  }

  void _back() {
    if (_current > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildStep(int index) {
    final step = widget.steps[index];
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.prompt,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: onSurface),
          ),
          const SizedBox(height: 16),
          if (step.inputType == JournalInputType.text)
            TextField(
              controller: _textControllers[step.key],
              minLines: step.minLines,
              maxLines: step.maxLines,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Введите ответ...',
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4)),
              ),
              style: TextStyle(color: onSurface),
            )
          else
            Column(
              children: [
                Slider(
                  value: _sliderValues[step.key] ?? step.min,
                  min: step.min,
                  max: step.max,
                  divisions: step.divisions,
                  label: (_sliderValues[step.key] ?? step.min)
                      .round()
                      .toString(),
                  onChanged: (value) =>
                      setState(() => _sliderValues[step.key] = value),
                ),
                Text(
                  '${(_sliderValues[step.key] ?? step.min).round()} / ${step.max.toInt()}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: onSurface),
                ),
                if (step.label != null)
                  Text(
                    step.label!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _current == widget.steps.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.steps.length,
              onPageChanged: (index) => setState(() => _current = index),
              itemBuilder: (context, index) => _buildStep(index),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_current > 0)
                    TextButton(onPressed: _back, child: Text(widget.backLabel))
                  else
                    const SizedBox(width: 80),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(isLast ? widget.saveLabel : widget.nextLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
