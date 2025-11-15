import 'package:flutter/material.dart';

class RmbBottomSheet extends StatefulWidget {
  final Widget Function(BuildContext) screenBuilder;
  final String addType;
  const RmbBottomSheet({
    super.key,
    required this.addType,
    required this.screenBuilder,
  });

  @override
  State<RmbBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<RmbBottomSheet> {
  Map<String, Object>? display;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (display != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${widget.addType.toLowerCase()}: $display',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ElevatedButton(
              child: Text('Add ${widget.addType.toLowerCase()}'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: widget.screenBuilder),
                );

                if (result != null) {
                  setState(() {
                    display = result is Map ? Map<String, Object>.from(result) : {'result': result.toString()};
                  });
                  Navigator.of(context).pop(result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
