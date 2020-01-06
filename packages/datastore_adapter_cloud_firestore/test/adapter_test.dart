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

import 'dart:io';

import 'package:datastore_adapter_cloud_firestore/adapter.dart';

import 'copy_of_datastore_test_suite.dart';

void main() {
  final serviceId = Platform.environment[serviceIdVar];
  final apiKey = Platform.environment[apiKeyVar];
  if (serviceId == null || apiKey == null) {
    print(
      'Skipping test: Environmental variables $serviceIdVar / $apiKeyVar are undefined.',
    );
    return;
  }
  DatastoreTestSuite(
    FirestoreFlutter(
      appId: serviceId,
      apiKey: apiKey,
    ),
  ).run();
}

const apiKeyVar = 'GOOGLE_CLOUD_FIRESTORE_API_KEY';

const serviceIdVar = 'GOOGLE_CLOUD_FIRESTORE_SERVICE_ID';
