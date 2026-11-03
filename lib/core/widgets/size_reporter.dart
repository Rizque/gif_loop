import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SizeReporter extends SingleChildRenderObjectWidget {
  const new({required this.onSizeChanged, super.key, super.child});

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSizeReporter(onSizeChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSizeReporter renderObject,
  ) => renderObject.onSizeChanged = onSizeChanged;
}

class RenderSizeReporter extends RenderProxyBox {
  new(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _reportedSize;

  // Reported after the frame: listeners may rebuild, which is not allowed
  // during layout.
  @override
  void performLayout() {
    super.performLayout();
    if (size == _reportedSize) return;
    _reportedSize = size;
    final reported = size;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => onSizeChanged(reported),
    );
  }
}
