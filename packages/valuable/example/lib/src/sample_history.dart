// ignore_for_file: unused_element_parameter

import 'package:example/src/sample_text.dart';
import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleHistory extends StatefulWidget {
  const SampleHistory({super.key});

  @override
  State<SampleHistory> createState() => _SampleHistoryState();
}

class _SampleHistoryState extends State<SampleHistory>
    with StateValuableScopeMixin<SampleHistory> {
  late final _operand1 = vScope.stateful<double>(0).historizeRW();
  late final _operand2 = vScope.stateful<double>(0).historizeRW();

  late final _result = (_operand1 * _operand2).historize();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sample History")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ValuableMultiplicator(
            operand1: _operand1,
            operand2: _operand2,
            result: _result,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _HistoryViewer(_operand1, title: "Operand 1")),
                Expanded(child: _HistoryViewer(_operand2, title: "Operand 2")),
                Expanded(child: _HistoryViewer(_result, title: "Result")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuableMultiplicator extends StatefulWidget {
  const _ValuableMultiplicator({
    required this.operand1,
    required this.operand2,
    required this.result,
  });

  final StatefulValuable<double> operand1;
  final StatefulValuable<double> operand2;

  final Valuable<num> result;

  @override
  State<_ValuableMultiplicator> createState() => _ValuableMultiplicatorState();
}

class _ValuableMultiplicatorState extends State<_ValuableMultiplicator>
    with StateValuableScopeMixin<_ValuableMultiplicator> {
  late final Valuable<String> operand1Txt = interopValuableArg(
    (w) => w.operand1,
  ).map((p0) => p0.toString());

  late final Valuable<String> operand2Txt = interopValuableArg(
    (w) => w.operand2,
  ).map((p0) => p0.toString());

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _ValuableMultiplicatorOperand(operand: widget.operand1),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ValuableText(operand1Txt),
                  const Text("x"),
                  ValuableText(operand2Txt),
                ],
              ),
              _ValuableMultiplicatorOperand(operand: widget.operand2),
            ],
          ),
        ),
        const Center(child: Text("=")),
        Expanded(child: _ValuableMultiplicatorResult(widget.result)),
      ],
    );
  }
}

class _ValuableMultiplicatorOperand extends ValuableWidget {
  final StatefulValuable<double> operand;

  final double minValue;
  final double maxValue;

  final int? divisions;

  const _ValuableMultiplicatorOperand({
    required this.operand,
    this.minValue = 0,
    this.maxValue = 9,
    this.divisions = 9,
  });

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Slider(
      value: watch(operand),
      onChanged: operand.setValue,
      min: minValue,
      max: maxValue,
      divisions: divisions,
    );
  }
}

class _ValuableMultiplicatorResult extends ValuableWidget {
  final Valuable<num> result;

  const _ValuableMultiplicatorResult(this.result);

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Center(child: Text("${watch(result)}"));
  }
}

class _HistoryViewer<T> extends ValuableWidget {
  final String title;

  final HistorizedValuable<T> valuable;

  final ScrollController scrollController = ScrollController();

  _HistoryViewer(this.valuable, {this.title = ""});

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text("${watch(valuable)}"),
                subtitle: const Text("Current value"),
              ),
              if (valuable is ReWritableHistorizedValuable)
                _UndoRedo(valuable as ReWritableHistorizedValuable),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: valuable.history.length,
            itemBuilder: (context, index) {
              ValuableHistoryNode<T> node = valuable.history.elementAt(
                valuable.history.length - 1 - index,
              );

              return ListTile(
                selected: isSelected(valuable.history.length - 1 - index),
                selectedColor: Colors.blue,
                title: Text("${node.value}"),
                subtitle: Text("${node.timestamp}"),
              );
            },
          ),
        ),
      ],
    );
  }

  bool isSelected(int index) {
    if (valuable is ReWritableHistorizedValuable) {
      return index <=
          (valuable as ReWritableHistorizedValuable).currentHistoryHead;
    }

    return true;
  }
}

class _UndoRedo extends StatelessWidget {
  final ReWritableHistorizedValuable rwvaluable;

  const _UndoRedo(this.rwvaluable);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: rwvaluable.canUndo ? rwvaluable.undoToInitial : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          onPressed: rwvaluable.canUndo ? rwvaluable.undo : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          onPressed: rwvaluable.canRedo ? rwvaluable.redo : null,
          icon: const Icon(Icons.redo),
        ),
        IconButton(
          onPressed: rwvaluable.canRedo ? rwvaluable.redoToCurrent : null,
          icon: const Icon(Icons.last_page),
        ),
      ],
    );
  }
}
