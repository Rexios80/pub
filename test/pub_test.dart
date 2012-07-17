// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../lib/unittest/unittest.dart');

final USAGE_STRING = """
    Pub is a package manager for Dart.

    Usage: pub command [arguments]

    Global options:
    -h, --help          Prints this usage information
        --version       Prints the version of Pub
        --[no-]trace    Prints a stack trace when an error occurs

    The commands are:
      install   install the current package's dependencies
      list      print the contents of repositories
      update    update the current package's dependencies to the latest versions
      version   print Pub version

    Use "pub help [command]" for more information about a command.
    """;

final VERSION_STRING = '''
    Pub 0.0.0
    ''';

main() {
  test('running pub with no command displays usage', () =>
      runPub(args: [], output: USAGE_STRING));

  test('running pub with just --help displays usage', () =>
      runPub(args: ['--help'], output: USAGE_STRING));

  test('running pub with just -h displays usage', () =>
      runPub(args: ['-h'], output: USAGE_STRING));

  test('running pub with just --version displays version', () =>
      runPub(args: ['--version'], output: VERSION_STRING));

  group('an unknown command', () {
    test('displays an error message', () {
      runPub(args: ['quylthulg'],
          error: '''
          Unknown command "quylthulg".
          Run "pub help" to see available commands.
          ''',
          exitCode: 64);
    });
  });

  group('pub list', listCommand);
  group('pub install', installCommand);
  group('pub version', versionCommand);
}

listCommand() {
  // TODO(rnystrom): We don't currently have any sources that are cached, so
  // we can't test this right now.
  /*
  group('cache', () {
    test('treats an empty directory as a package', () {
      dir(cachePath, [
        dir('sdk', [
          dir('apple'),
          dir('banana'),
          dir('cherry')
        ])
      ]).scheduleCreate();

      runPub(args: ['list', 'cache'],
          output: '''
          From system cache:
            apple 0.0.0 (apple from sdk)
            banana 0.0.0 (banana from sdk)
            cherry 0.0.0 (cherry from sdk)
          ''');
    });
  });
  */
}

installCommand() {
  test('checks out a package from the SDK', () {
    dir(sdkPath, [
      file('revision', '1234'),
      dir('lib', [
        dir('foo', [
          file('foo.dart', 'main() => "foo";')
        ])
      ])
    ]).scheduleCreate();

    dir(appPath, [
      file('pubspec.yaml', 'dependencies:\n  foo:')
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: '''
        Dependencies installed!
        ''');

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out a package from Git', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    dir(appPath, [
      file('pubspec.yaml', '''
dependencies:
  foo:
    git: ../foo.git
''')
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [
          dir(new RegExp(@'foo-[a-f0-9]+'), [
            file('foo.dart', 'main() => "foo";')
          ])
        ]),
        dir(new RegExp(@'foo-[a-f0-9]+'), [
          file('foo.dart', 'main() => "foo";')
        ])
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out packages transitively from Git', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";'),
      file('pubspec.yaml', '''
dependencies:
  bar:
    git: ../bar.git
''')
    ]).scheduleCreate();

    git('bar.git', [
      file('bar.dart', 'main() => "bar";')
    ]).scheduleCreate();

    dir(appPath, [
      file('pubspec.yaml', '''
dependencies:
  foo:
    git: ../foo.git
''')
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [
          dir(new RegExp(@'foo-[a-f0-9]+'), [
            file('foo.dart', 'main() => "foo";')
          ]),
          dir(new RegExp(@'bar-[a-f0-9]+'), [
            file('bar.dart', 'main() => "bar";')
          ])
        ]),
        dir(new RegExp(@'foo-[a-f0-9]+'), [
          file('foo.dart', 'main() => "foo";')
        ]),
        dir(new RegExp(@'bar-[a-f0-9]+'), [
          file('bar.dart', 'main() => "bar";')
        ])
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ]),
      dir('bar', [
        file('bar.dart', 'main() => "bar";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out and updates a package from Git', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    dir(appPath, [
      file('pubspec.yaml', '''
dependencies:
  foo:
    git: ../foo.git
''')
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [
          dir(new RegExp(@'foo-[a-f0-9]+'), [
            file('foo.dart', 'main() => "foo";')
          ])
        ]),
        dir(new RegExp(@'foo-[a-f0-9]+'), [
          file('foo.dart', 'main() => "foo";')
        ])
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    // TODO(nweiz): remove this once we support pub update
    dir(packagesPath).scheduleDelete();

    git('foo.git', [
      file('foo.dart', 'main() => "foo 2";')
    ]).scheduleCommit();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    // When we download a new version of the git package, we should re-use the
    // git/cache directory but create a new git/ directory.
    dir(cachePath, [
      dir('git', [
        dir('cache', [
          dir(new RegExp(@'foo-[a-f0-9]+'), [
            file('foo.dart', 'main() => "foo 2";')
          ])
        ]),
        dir(new RegExp(@'foo-[a-f0-9]+'), [
          file('foo.dart', 'main() => "foo";')
        ]),
        dir(new RegExp(@'foo-[a-f0-9]+'), [
          file('foo.dart', 'main() => "foo 2";')
        ])
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 2";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out a package from Git twice', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    dir(appPath, [
      file('pubspec.yaml', '''
dependencies:
  foo:
    git: ../foo.git
''')
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [
          dir(new RegExp(@'foo-[a-f0-9]+'), [
            file('foo.dart', 'main() => "foo";')
          ])
        ]),
        dir(new RegExp(@'foo-[a-f0-9]+'), [
          file('foo.dart', 'main() => "foo";')
        ])
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    // TODO(nweiz): remove this once we support pub update
    dir(packagesPath).scheduleDelete();

    // Verify that nothing breaks if we install a Git revision that's already
    // in the cache.
    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    run();
  });

  test('checks out a package at a specific revision from Git', () {
    ensureGit();

    var repo = git('foo.git', [
      file('foo.dart', 'main() => "foo 1";')
    ]);
    repo.scheduleCreate();
    var commitFuture = repo.revParse('HEAD');

    git('foo.git', [
      file('foo.dart', 'main() => "foo 2";')
    ]).scheduleCommit();

    dir(appPath, [
      async(commitFuture.transform((commit) {
        return file('pubspec.yaml', '''
dependencies:
  foo:
    git:
      url: ../foo.git
      ref: $commit
''');
      }))
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out a package from a pub server', () {
    servePackages("localhost", 3123, ['{name: foo, version: 1.2.3}']);

    dir(appPath, [
      file('pubspec.yaml', '''
dependencies:
  foo:
    repo:
      name: foo
      url: http://localhost:3123
    version: 1.2.3
''')
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    dir(cachePath, [
      dir('repo', [
        dir('localhost%583123', [
          dir('foo-1.2.3', [
            file('pubspec.yaml', '{name: foo, version: 1.2.3}'),
            file('foo.dart', 'main() => print("foo 1.2.3");')
          ])
        ])
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('pubspec.yaml', '{name: foo, version: 1.2.3}'),
        file('foo.dart', 'main() => print("foo 1.2.3");')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out packages transitively from a pub server', () {
    servePackages("localhost", 3123, [
      '''
name: foo
version: 1.2.3
dependencies:
  bar:
    repo: {name: bar, url: http://localhost:3123}
    version: 2.0.4
''',
      '{name: bar, version: 2.0.3}',
      '{name: bar, version: 2.0.4}',
      '{name: bar, version: 2.0.5}',
    ]);

    dir(appPath, [
      file('pubspec.yaml', '''
dependencies:
  foo:
    repo:
      name: foo
      url: http://localhost:3123
    version: 1.2.3
''')
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    dir(cachePath, [
      dir('repo', [
        dir('localhost%583123', [
          dir('foo-1.2.3', [
            file('pubspec.yaml', '''
name: foo
version: 1.2.3
dependencies:
  bar:
    repo: {name: bar, url: http://localhost:3123}
    version: 2.0.4
'''),
            file('foo.dart', 'main() => print("foo 1.2.3");')
          ]),
          dir('bar-2.0.4', [
            file('pubspec.yaml', '{name: bar, version: 2.0.4}'),
            file('bar.dart', 'main() => print("bar 2.0.4");')
          ])
        ])
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
            file('pubspec.yaml', '''
name: foo
version: 1.2.3
dependencies:
  bar:
    repo: {name: bar, url: http://localhost:3123}
    version: 2.0.4
'''),
        file('foo.dart', 'main() => print("foo 1.2.3");')
      ]),
      dir('bar', [
        file('pubspec.yaml', '{name: bar, version: 2.0.4}'),
        file('bar.dart', 'main() => print("bar 2.0.4");')
      ])
    ]).scheduleValidate();

    run();
  });

  test('resolves version constraints from a pub server', () {
    servePackages("localhost", 3123, [
      '''
name: foo
version: 1.2.3
dependencies:
  baz:
    repo: {name: baz, url: http://localhost:3123}
    version: ">=2.0.0"
''',
      '''
name: bar
version: 2.3.4
dependencies:
  baz:
    repo: {name: baz, url: http://localhost:3123}
    version: "<3.0.0"
''',
      '{name: baz, version: 2.0.3}',
      '{name: baz, version: 2.0.4}',
      '{name: baz, version: 3.0.1}',
    ]);

    dir(appPath, [
      file('pubspec.yaml', '''
dependencies:
  foo: {repo: {name: foo, url: http://localhost:3123}}
  bar: {repo: {name: bar, url: http://localhost:3123}}
''')
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    dir(cachePath, [
      dir('repo', [
        dir('localhost%583123', [
          dir('foo-1.2.3', [
            file('pubspec.yaml', '''
name: foo
version: 1.2.3
dependencies:
  baz:
    repo: {name: baz, url: http://localhost:3123}
    version: ">=2.0.0"
'''),
            file('foo.dart', 'main() => print("foo 1.2.3");')
          ]),
          dir('bar-2.3.4', [
            file('pubspec.yaml', '''
name: bar
version: 2.3.4
dependencies:
  baz:
    repo: {name: baz, url: http://localhost:3123}
    version: "<3.0.0"
'''),
            file('bar.dart', 'main() => print("bar 2.3.4");')
          ]),
          dir('baz-2.0.4', [
            file('pubspec.yaml', '{name: baz, version: 2.0.4}'),
            file('baz.dart', 'main() => print("baz 2.0.4");')
          ])
        ])
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('pubspec.yaml', '''
name: foo
version: 1.2.3
dependencies:
  baz:
    repo: {name: baz, url: http://localhost:3123}
    version: ">=2.0.0"
'''),
        file('foo.dart', 'main() => print("foo 1.2.3");')
      ]),
      dir('bar', [
        file('pubspec.yaml', '''
name: bar
version: 2.3.4
dependencies:
  baz:
    repo: {name: baz, url: http://localhost:3123}
    version: "<3.0.0"
'''),
        file('bar.dart', 'main() => print("bar 2.3.4");')
      ]),
      dir('baz', [
        file('pubspec.yaml', '{name: baz, version: 2.0.4}'),
        file('baz.dart', 'main() => print("baz 2.0.4");')
      ])
    ]).scheduleValidate();

    run();
  });
}

versionCommand() {
  test('displays the current version', () =>
    runPub(args: ['version'], output: VERSION_STRING));
}
