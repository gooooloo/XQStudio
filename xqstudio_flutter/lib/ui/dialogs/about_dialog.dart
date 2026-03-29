import 'package:flutter/material.dart';

class XQAboutDialog extends StatelessWidget {
  const XQAboutDialog({super.key});

  static void show(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'XQStudio',
      applicationVersion: '2.0.0 (Flutter)',
      applicationLegalese: '© 1998-2008 DONG Shiwei\nFlutter port © 2026',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('Chinese Chess (象棋) game record editor.'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
