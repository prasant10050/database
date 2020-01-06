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

import 'package:datastore/adapters_framework.dart';
import 'package:datastore/datastore.dart';
import 'package:meta/meta.dart';
import 'package:search/search.dart';

class SearcheableDatastore extends DelegatingDatastoreAdapter {
  /// The scoring algorithm for documents.
  ///
  /// By default, [CanineDocumentScoring] is used.
  final DocumentScoring scoring;

  /// If true, state mutating operations throw [UnsupportedError].
  final bool isReadOnly;

  SearcheableDatastore({
    @required Datastore datastore,
    this.isReadOnly = false,
    this.scoring = const CanineDocumentScoring(),
  })  : assert(datastore != null),
        assert(isReadOnly != null),
        assert(scoring != null),
        super(datastore);

  @override
  Stream<QueryResult> performSearch(SearchRequest request) async* {
    final query = request.query;
    final filter = query?.filter;

    // If no keyword filters
    if (filter == null || !filter.descendants.any((f) => f is KeywordFilter)) {
      // Delegate this request
      yield* (super.performSearch(request));
      return;
    }

    final collection = request.collection;
    final dsCollection = super.collection(
      collection.collectionId,
    );
    final dsResults = dsCollection.searchChunked();
    final sortedItems = <QueryResultItem>[];
    final intermediateResultInterval = const Duration(milliseconds: 500);
    var intermediateResultAt = DateTime.now().add(intermediateResultInterval);
    final scoringState = scoring.newState(query.filter);

    //
    // For each document
    //
    await for (var dsResult in dsResults) {
      for (final dsSnapshot in dsResult.snapshots) {
        // Score
        var score = 1.0;
        if (filter != null) {
          score = scoringState.evaluateSnapshot(
            dsSnapshot,
          );
          if (score <= 0.0) {
            continue;
          }
        }

        final queryResultItem = QueryResultItem(
          snapshot: Snapshot(
            document: collection.document(dsSnapshot.document.documentId),
            data: dsSnapshot.data,
          ),
          score: score,
        );
        sortedItems.add(queryResultItem);

        // Should have an intermediate result?
        if (request.isIncremental &&
            DateTime.now().isAfter(intermediateResultAt)) {
          if (filter != null) {
            sortedItems.sort(
              (a, b) {
                return a.score.compareTo(b.score);
              },
            );
          }
          Iterable<QueryResultItem> items = sortedItems;
          final query = request.query;
          {
            final skip = query.skip ?? 0;
            if (skip != 0) {
              items = items.skip(skip);
            }
          }
          {
            final take = query.take;
            if (take != null) {
              items = items.take(take);
            }
          }
          yield (QueryResult.withDetails(
            collection: collection,
            query: query,
            items: List<QueryResultItem>.unmodifiable(items),
          ));
          intermediateResultAt = DateTime.now().add(intermediateResultInterval);
        }
      }
    }

    //
    // Sort snapshots
    //
    if (filter != null) {
      sortedItems.sort(
        (a, b) {
          final as = a.score;
          final bs = b.score;
          return as.compareTo(bs);
        },
      );
    }
    Iterable<QueryResultItem> items = sortedItems;
    {
      final skip = query.skip ?? 0;
      if (skip != 0) {
        items = items.skip(skip);
      }
    }
    {
      final take = query.take;
      if (take != null) {
        items = items.take(take);
      }
    }

    //
    // Yield
    //
    yield (QueryResult.withDetails(
      collection: collection,
      query: query,
      items: List<QueryResultItem>.unmodifiable(items),
    ));
  }
}
