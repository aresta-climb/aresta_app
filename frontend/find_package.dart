import 'dart:isolate';
import 'package:feedback/feedback.dart';

void main() async {
  final uri = await Isolate.resolvePackageUri(Uri.parse('package:feedback/feedback.dart'));
  print('Feedback package path: $uri');
}
