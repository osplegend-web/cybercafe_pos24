import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Most USB barcode scanners act as a keyboard: they "type" the barcode
/// characters very fast and finish with an Enter key. This widget wraps
/// its child, listens for that fast burst of keystrokes anywhere on the
/// screen, and calls [onBarcodeScanned] once Enter is received - without
/// needing a visible focused text field. Wrap your POS screen body with it.
class UsbBarcodeListener extends StatefulWidget {
  final Widget child;
  final ValueChanged<String> onBarcodeScanned;

  /// Keystrokes arriving further apart than this are treated as normal
  /// typing, not a scanner burst.
  final Duration maxKeystrokeGap;

  const UsbBarcodeListener({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
    this.maxKeystrokeGap = const Duration(milliseconds: 50),
  });

  @override
  State<UsbBarcodeListener> createState() => _UsbBarcodeListenerState();
}

class _UsbBarcodeListenerState extends State<UsbBarcodeListener> {
  final FocusNode _focusNode = FocusNode();
  final StringBuffer _buffer = StringBuffer();
  DateTime? _lastKeyTime;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final now = DateTime.now();
    if (_lastKeyTime != null && now.difference(_lastKeyTime!) > widget.maxKeystrokeGap * 4) {
      _buffer.clear();
    }
    _lastKeyTime = now;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final code = _buffer.toString();
      _buffer.clear();
      if (code.length >= 4) {
        widget.onBarcodeScanned(code);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final char = event.character;
    if (char != null && char.isNotEmpty) {
      _buffer.write(char);
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: widget.child,
    );
  }
}
