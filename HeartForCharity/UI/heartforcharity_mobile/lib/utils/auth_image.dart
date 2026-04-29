import 'package:flutter/material.dart';
import 'package:heartforcharity_mobile/providers/auth_provider.dart';

Map<String, String> get _authHeaders =>
    AuthProvider.token != null ? {'Authorization': 'Bearer ${AuthProvider.token}'} : {};

/// NetworkImage with the current auth token in the Authorization header.
NetworkImage authNetworkImage(String url) => NetworkImage(url, headers: _authHeaders);

/// Drop-in replacement for Image.network() for API-uploaded images.
Widget authImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
}) {
  return Image(
    image: authNetworkImage(url),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, _, _) =>
        errorWidget ??
        Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
  );
}
