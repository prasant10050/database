// Copyright 2019 terrier989@gmail.com.
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

import 'package:database/database.dart';
import 'package:database/database_adapter.dart';

/// A superclass for requests not supported by the standard [Database].
///
/// The corresponding response is [DatabaseExtensionResponse].
abstract class DatabaseExtensionRequest<T extends DatabaseExtensionResponse> {
  Stream<T> delegateTo(DatabaseAdapter database) {
    // ignore: invalid_use_of_protected_member
    return database.performExtension(this);
  }

  Stream<T> unsupported(Database database) {
    return Stream<T>.error(
      UnsupportedError('Request class $this is unsupported by $database'),
    );
  }
}

/// A superclass for responses not supported by the standard [Database].
///
/// The corresponding request class is [DatabaseExtensionRequest].
abstract class DatabaseExtensionResponse {}