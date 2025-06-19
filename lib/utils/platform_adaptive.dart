import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformAdaptive {
  static bool isApplePlatform() {
    if (kIsWeb) {
      // For web, we can't detect the platform reliably
      return false;
    }
    return Platform.isIOS || Platform.isMacOS;
  }

  static Widget scaffold({
    required BuildContext context,
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Widget? drawer,
    Color? backgroundColor,
    bool resizeToAvoidBottomInset = true,
  }) {
    if (isApplePlatform()) {
      return CupertinoPageScaffold(
        navigationBar: appBar as CupertinoNavigationBar?,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        child: body,
      );
    } else {
      return Scaffold(
        appBar: appBar,
        body: body,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    }
  }

  static PreferredSizeWidget appBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (isApplePlatform()) {
      return CupertinoNavigationBar(
        middle: Text(title),
        trailing: actions != null && actions.isNotEmpty
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: actions,
        )
            : null,
        leading: leading,
        backgroundColor: backgroundColor,
      );
    } else {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      );
    }
  }

  static Widget button({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    if (isApplePlatform()) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: backgroundColor,
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor ?? Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(color: textColor ?? Colors.white),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
        ),
        child: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white),
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      );
    }
  }

  static Widget textField({
    required TextEditingController controller,
    String? placeholder,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefix,
    Widget? suffix,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    FocusNode? focusNode,
    InputDecoration? decoration,
  }) {
    if (isApplePlatform()) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        prefix: prefix != null
            ? Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: prefix,
        )
            : null,
        suffix: suffix != null
            ? Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: suffix,
        )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          border: Border.all(
            color: CupertinoColors.systemGrey4,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onEditingComplete: onEditingComplete,
        onChanged: onChanged,
        enabled: enabled,
        focusNode: focusNode,
      );
    } else {
      return TextField(
        controller: controller,
        decoration: decoration ??
            InputDecoration(
              hintText: placeholder,
              prefixIcon: prefix,
              suffixIcon: suffix,
              enabled: enabled,
            ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onEditingComplete: onEditingComplete,
        onChanged: onChanged,
        enabled: enabled,
        focusNode: focusNode,
      );
    }
  }

  static Widget progressIndicator({Color? color}) {
    if (isApplePlatform()) {
      return CupertinoActivityIndicator(
        color: color,
        radius: 12,
      );
    } else {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
        strokeWidth: 3,
      );
    }
  }

  static Widget switchWidget({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    if (isApplePlatform()) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    } else {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    }
  }
}
