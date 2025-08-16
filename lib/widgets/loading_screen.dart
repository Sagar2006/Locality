import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final String? message;
  final bool modal;

  const LoadingScreen({Key? key, this.message, this.modal = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 24),
          Text(
            message!,
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onBackground,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (modal) {
      return Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    } else {
      return Center(child: content);
    }
  }
}
