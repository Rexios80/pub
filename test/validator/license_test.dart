// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:pub_hosted/src/io.dart';
import 'package:pub_hosted/src/validator.dart';
import 'package:pub_hosted/src/validator/license.dart';
import 'package:test/test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator license() => LicenseValidator();

void main() {
  group('should consider a package valid if it', () {
    test('looks normal', () async {
      await d.validPackage().create();
      await expectValidationDeprecated(license);
    });

    test('has both LICENSE and UNLICENSE file', () async {
      await d.validPackage().create();
      await d.file(p.join(appPath, 'UNLICENSE'), '').create();
      await expectValidationDeprecated(license);
    });
  });

  group('should warn if it', () {
    test('has only a COPYING file', () async {
      await d.validPackage().create();
      deleteEntry(p.join(d.sandbox, appPath, 'LICENSE'));
      await d.file(p.join(appPath, 'COPYING'), '').create();
      await expectValidationDeprecated(license, warnings: isNotEmpty);
    });

    test('has only an UNLICENSE file', () async {
      await d.validPackage().create();
      deleteEntry(p.join(d.sandbox, appPath, 'LICENSE'));
      await d.file(p.join(appPath, 'UNLICENSE'), '').create();
      await expectValidationDeprecated(license, warnings: isNotEmpty);
    });

    test('has only a prefixed LICENSE file', () async {
      await d.validPackage().create();
      deleteEntry(p.join(d.sandbox, appPath, 'LICENSE'));
      await d.file(p.join(appPath, 'MIT_LICENSE'), '').create();
      await expectValidationDeprecated(license, warnings: isNotEmpty);
    });

    test('has only a suffixed LICENSE file', () async {
      await d.validPackage().create();
      deleteEntry(p.join(d.sandbox, appPath, 'LICENSE'));
      await d.file(p.join(appPath, 'LICENSE.md'), '').create();
      await expectValidationDeprecated(license, warnings: isNotEmpty);
    });
  });

  group('should consider a package invalid if it', () {
    test('has no LICENSE file', () async {
      await d.validPackage().create();
      deleteEntry(p.join(d.sandbox, appPath, 'LICENSE'));
      await expectValidationDeprecated(license, errors: isNotEmpty);
    });

    test('has a prefixed UNLICENSE file', () async {
      await d.validPackage().create();
      deleteEntry(p.join(d.sandbox, appPath, 'LICENSE'));
      await d.file(p.join(appPath, 'MIT_UNLICENSE'), '').create();
      await expectValidationDeprecated(license, errors: isNotEmpty);
    });

    test('has a .gitignored LICENSE file', () async {
      final repo = d.git(appPath, [d.file('.gitignore', 'LICENSE')]);
      await d.validPackage().create();
      await repo.create();
      await expectValidationDeprecated(license, errors: isNotEmpty);
    });
  });
}
