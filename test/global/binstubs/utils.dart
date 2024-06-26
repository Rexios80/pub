// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../../test_pub.dart';

/// The buildbots do not have the Dart SDK (containing "dart" and "pub") on
/// their PATH, so we need to spawn the binstub process with a PATH that
/// explicitly includes it.
///
/// The `pub`/`pub.bat` command on the PATH will be the one in tool/test-bin not
/// the one from the sdk.
Map<String, String> getEnvironment() {
  final binDir = p.dirname(Platform.resolvedExecutable);
  final separator = Platform.isWindows ? ';' : ':';
  final pubBin = p.absolute('tool', 'test-bin');
  final path =
      "$pubBin$separator${Platform.environment["PATH"]}$separator$binDir";

  final environment = getPubTestEnvironment();
  environment['PATH'] = path;
  return environment;
}
