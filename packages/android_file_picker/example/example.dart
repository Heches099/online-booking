// An example demonstrating the usage of android_file_picker.
import 'dart:developer' as developer;

import 'package:android_file_picker/android_file_picker.dart';

void main() {
  FilePickerAndroid.registerWith();
  developer.log('Registered android_file_picker implementation.');
}
