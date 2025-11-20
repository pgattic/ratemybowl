import 'package:flutter/material.dart';

class AddRestroomBottomSheet extends StatefulWidget {
  final Widget Function(BuildContext) screenBuilder;

  const AddRestroomBottomSheet({super.key, required this.screenBuilder});

  @override
  State<AddRestroomBottomSheet> createState() => _AddRestroomBottomSheetState();
}

class _AddRestroomBottomSheetState extends State<AddRestroomBottomSheet> {
  Map<String, Object>? display;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(64, 196, 255, 1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (display != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'restroom: $display',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: widget.screenBuilder),
                      );

                      if (result != null) {
                        setState(() {
                          display = result is Map
                              ? Map<String, Object>.from(result)
                              : {'result': result.toString()};
                        });

                        Navigator.of(context).pop(result);
                      }
                    },
                    child: const Text('Add restroom'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
