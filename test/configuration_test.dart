////////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////

// ignore_for_file: unused_local_variable
import 'dart:io';
import 'package:test/test.dart' hide test, throws;
import '../lib/realm.dart';
import 'test.dart';

Future<void> main([List<String>? args]) async {
  print("Current PID $pid");

  await setupTests(args);

  test('Configuration can be created', () {
    Configuration([Car.schema]);
  });

  test('Configuration exception if no schema', () {
    expect(() => Configuration([]), throws<RealmException>());
  });

  test('Configuration default path', () {
    if (Platform.isAndroid || Platform.isIOS) {
      expect(Configuration.defaultPath, endsWith(".realm"));
      expect(Configuration.defaultPath, startsWith("/"), reason: "on Android and iOS the default path should contain the path to the user data directory");
    } else {
      expect(Configuration.defaultPath, endsWith(".realm"));
    }
  });

  test('Configuration files path', () {
    if (Platform.isAndroid || Platform.isIOS) {
      expect(Configuration.filesPath, isNot(endsWith(".realm")), reason: "on Android and iOS the filesPath should be a directory");
      expect(Configuration.filesPath, startsWith("/"), reason: "on Android and iOS the filesPath should be a directory");
    } else {
      expect(Configuration.filesPath, equals(Directory.current.absolute.path), reason: "on Dart standalone the filesPath should be the current dir path");
    }
  });

  test('Configuration get/set path', () {
    final config = Configuration([Car.schema]);
    expect(config.path, endsWith('.realm'));

    const path = "my/path/default.realm";
    final explicitPathConfig = Configuration([Car.schema], path: path);
    expect(explicitPathConfig.path, equals(path));
  });

  test('Configuration get/set schema version', () {
    final config = Configuration([Car.schema]);
    expect(config.schemaVersion, equals(0));

    final explicitSchemaConfig = Configuration([Car.schema], schemaVersion: 3);
    expect(explicitSchemaConfig.schemaVersion, equals(3));
  });

  test('Configuration readOnly - opening non existing realm throws', () {
    Configuration config = Configuration([Car.schema], isReadOnly: true);
    expect(() => getRealm(config), throws<RealmException>("at path '${config.path}' does not exist"));
  });

  test('Configuration readOnly - open existing realm with read-only config', () {
    Configuration config = Configuration([Car.schema]);
    var realm = getRealm(config);
    realm.close();

    // Open an existing realm as readonly.
    config = Configuration([Car.schema], isReadOnly: true);
    realm = getRealm(config);
  });

  test('Configuration readOnly - reading is possible', () {
    Configuration config = Configuration([Car.schema]);
    var realm = getRealm(config);
    realm.write(() => realm.add(Car("Mustang")));
    realm.close();

    config = Configuration([Car.schema], isReadOnly: true);
    realm = getRealm(config);
    var cars = realm.all<Car>();
    expect(cars.length, 1);
  });

  test('Configuration readOnly - writing on read-only Realms throws', () {
    Configuration config = Configuration([Car.schema]);
    var realm = getRealm(config);
    realm.close();

    config = Configuration([Car.schema], isReadOnly: true);
    realm = getRealm(config);
    expect(() => realm.write(() {}), throws<RealmException>("Can't perform transactions on read-only Realms."));
  });

  test('Configuration inMemory - no files after closing realm', () {
    Configuration config = Configuration([Car.schema], isInMemory: true);
    var realm = getRealm(config);
    realm.write(() => realm.add(Car('Tesla')));
    realm.close();
    expect(Realm.existsSync(config.path), false);
  });

  test('Configuration inMemory can not be readOnly', () {
    Configuration config = Configuration([Car.schema], isInMemory: true);
    final realm = getRealm(config);

    expect(() {
      config = Configuration([Car.schema], isReadOnly: true);
      getRealm(config);
    }, throws<RealmException>("Realm at path '${config.path}' already opened with different read permissions"));
  });

  test('Configuration - FIFO files fallback path', () {
    Configuration config = Configuration([Car.schema], fifoFilesFallbackPath: "./fifo_folder");
    final realm = getRealm(config);
  });

  test('Configuration.operator== equal configs', () {
    final config = Configuration([Dog.schema, Person.schema]);
    final realm = getRealm(config);
    expect(config, realm.config);
  });

  test('Configuration.operator== different configs', () {
    var config = Configuration([Dog.schema, Person.schema]);
    final realm1 = getRealm(config);
    config = Configuration([Dog.schema, Person.schema]);
    final realm2 = getRealm(config);
    expect(realm1.config, isNot(realm2.config));
  });

  test('Configuration - disableFormatUpgrade=true throws error', () async {
    final realmBundleFile = "test/data/realm_files/old-format.realm";
    var config = Configuration([Car.schema], disableFormatUpgrade: true);
    await File(realmBundleFile).copy(config.path);
    expect(() {
      getRealm(config);
    }, throws<RealmException>("The Realm file format must be allowed to be upgraded in order to proceed"));
  }, skip: isFlutterPlatform);

  test('Configuration - disableFormatUpgrade=false', () async {
    final realmBundleFile = "test/data/realm_files/old-format.realm";
    var config = Configuration([Car.schema], disableFormatUpgrade: false);
    await File(realmBundleFile).copy(config.path);
    final realm = getRealm(config);
  }, skip: isFlutterPlatform);

  test('Configuration.initialDataCallback invoked', () {
    var invoked = false;
    var config = Configuration([Dog.schema, Person.schema], initialDataCallback: (realm) {
      invoked = true;
      realm.add(Dog('fido', owner: Person('john')));
    });

    final realm = getRealm(config);
    expect(invoked, true);

    final people = realm.all<Person>();
    expect(people.length, 1);
    expect(people[0].name, 'john');

    final dogs = realm.all<Dog>();
    expect(dogs.length, 1);
    expect(dogs[0].name, 'fido');
  });

  test('Configuration.initialDataCallback not invoked for existing realm', () {
    var invoked = false;
    final config = Configuration([Person.schema], initialDataCallback: (realm) {
      invoked = true;
      realm.add(Person('peter'));
    });

    final realm = getRealm(config);
    expect(invoked, true);
    expect(realm.all<Person>().length, 1);
    realm.close();

    var invokedAgain = false;
    final configAgain = Configuration([Person.schema], initialDataCallback: (realm) {
      invokedAgain = true;
      realm.add(Person('p1'));
      realm.add(Person('p2'));
    });

    final realmAgain = getRealm(configAgain);
    expect(invokedAgain, false);
    expect(realmAgain.all<Person>().length, 1);
  });

  test('Configuration.initialDataCallback with error', () {
    var invoked = false;
    var config = Configuration([Person.schema], initialDataCallback: (realm) {
      invoked = true;
      realm.add(Person('p1'));
      throw Exception('very careless developer');
    });

    expect(() => getRealm(config), throws<RealmException>("User-provided callback failed"));
    expect(invoked, true);

    // No data should have been written to the Realm
    config = Configuration([Person.schema]);
    final realm = getRealm(config);

    expect(realm.all<Person>().length, 0);
  }, skip: 'TODO: fails to delete Realm - https://github.com/realm/realm-core/issues/5363');

  test('Configuration.initialDataCallback with error, invoked on second attempt', () {
    var invoked = false;
    var config = Configuration([Person.schema], initialDataCallback: (realm) {
      invoked = true;
      realm.add(Person('p1'));
      throw Exception('very careless developer');
    });

    expect(() => getRealm(config), throws<RealmException>("User-provided callback failed"));
    expect(invoked, true);

    var secondInvoked = false;
    config = Configuration([Person.schema], initialDataCallback: (realm) {
      invoked = true;
      realm.add(Person('p1'));
    });

    final realm = getRealm(config);
    expect(secondInvoked, true);
    expect(realm.all<Person>().length, 1);
  }, skip: 'TODO: Realm gets created even though it errors out on open - https://github.com/realm/realm-core/issues/5364');

  test('Configuration.initialDataCallback is a no-op when opening an empty existing Realm', () {
    var config = Configuration([Person.schema]);

    // Create the Realm and close it
    getRealm(config).close();

    var invoked = false;
    config = Configuration([Person.schema], initialDataCallback: (realm) {
      invoked = true;
      realm.add(Person("john"));
    });

    // Even though the Realm was empty, since we're not creating it,
    // we expect initialDataCallback not to be invoked.
    final realm = getRealm(config);

    expect(invoked, false);
    expect(realm.all<Person>().length, 0);
  });

  test('Configuration.initialDataCallback can use non-add API in callback', () {
    Exception? callbackEx;
    final config = Configuration([Person.schema], initialDataCallback: (realm) {
      try {
        final george = realm.add(Person("George"));

        // We try to make sure some basic Realm API are available in the callback
        expect(realm.all<Person>().length, 1);
        realm.delete(george);
      } on Exception catch (ex) {
        callbackEx = ex;
      }
    });

    final realm = getRealm(config);

    expect(callbackEx, null);
    expect(realm.all<Person>().length, 0);
  });

  test('Configuration.initialDataCallback realm.write fails', () {
    Exception? callbackEx;
    final config = Configuration([Person.schema], initialDataCallback: (realm) {
      try {
        realm.write(() => null);
      } on RealmException catch (ex) {
        callbackEx = ex;
      }
    });

    final realm = getRealm(config);

    expect(callbackEx, isNotNull);
    expect(callbackEx.toString(), contains('The Realm is already in a write transaction'));
  });
  
  test('Configuration - do not compact on open realm', () {
    var config = Configuration([Dog.schema, Person.schema], shouldCompactCallback: (totalSize, usedSize) {
      return false;
    });
    final realm = getRealm(config);
  });

  test('Configuration - compact on open realm', () {
    var config = Configuration([Dog.schema, Person.schema], shouldCompactCallback: (totalSize, usedSize) {
      return totalSize > 0;
    });
    final realm = getRealm(config);
  });
}
