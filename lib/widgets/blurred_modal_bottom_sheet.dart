import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

const filterSheetDecoration = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF202449), Color(0xFF191526), Color(0xFF0D0F16)],
    stops: [0, .48, 1],
  ),
  borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
);

Future<T?> showBlurredModalBottomSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height * .9),
        child: SizedBox(
          width: double.infinity,
          child: Material(color: Colors.transparent, child: builder(context)),
        ),
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SizedBox(
                width: double.infinity,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(slideAnimation),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

InputDecoration filterDropdownDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: const Color.fromARGB(98, 12, 13, 27),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF292C38)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF292C38)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  );
}
