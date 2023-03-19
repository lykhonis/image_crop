import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ButtonState { ready, disabled, processing }

class ButtonStateNotifier extends ChangeNotifier
    implements ValueListenable<ButtonState> {
  var _state = ButtonState.ready;

  ButtonStateNotifier();

  @override
  ButtonState get value => _state;

  void ready() {
    _tryUpdate(ButtonState.ready);
  }

  void disable() {
    _tryUpdate(ButtonState.disabled);
  }

  void process() {
    _tryUpdate(ButtonState.processing);
  }

  void _tryUpdate(ButtonState state) {
    if (_state != state) {
      _state = state;
      notifyListeners();
    }
  }
}

class ConfirmButton extends StatelessWidget {
  final ButtonStateNotifier state;
  final VoidCallback submit;

  ConfirmButton({
    super.key,
    required this.submit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: state,
      builder: (context, ButtonState state, _) {
        return _ButtonShape(state, submit);
      },
    );
  }
}

class _ButtonShape extends StatelessWidget {
  final ButtonState _state;
  final VoidCallback _submit;

  static Widget get _icon => Icon(Icons.done, size: 36);

  const _ButtonShape(this._state, this._submit);

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onPressed;
    final Widget child;

    switch (_state) {
      case ButtonState.ready:
        onPressed = _submit;
        child = _icon;
        break;
      case ButtonState.disabled:
        onPressed = null;
        child = _icon;
        break;
      case ButtonState.processing:
        onPressed = null;
        child = const CircularProgressIndicator();
        break;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(15),
      ),
      child: child,
    );
  }
}
