import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// iOS (especially iPad) requires a non-zero [ShareParams.sharePositionOrigin].
class ShareHelper {
  ShareHelper._();

  static Rect sharePositionOrigin(BuildContext context, {GlobalKey? anchorKey}) {
    final RenderBox? box = anchorKey?.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final origin = box.localToGlobal(Offset.zero);
      final size = box.size;
      if (size.width > 0 && size.height > 0) {
        return origin & size;
      }
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.75),
      width: 1,
      height: 1,
    );
  }

  static Future<ShareResult> share(
    ShareParams params, {
    required BuildContext context,
    GlobalKey? anchorKey,
  }) {
    if (Platform.isIOS) {
      return SharePlus.instance.share(
        ShareParams(
          text: params.text,
          files: params.files,
          subject: params.subject,
          sharePositionOrigin: sharePositionOrigin(context, anchorKey: anchorKey),
        ),
      );
    }
    return SharePlus.instance.share(params);
  }
}
