/*
 *  Copyright 2020 hacker1024
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pagination_wrapper/flutter_pagination_wrapper.dart';
import 'package:http/http.dart';

const _endpointHost = '5f4487133fb92f0016753854.mockapi.io';
const _endpointPaths = const ['api', 'v1', 'foods'];

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Pagination Wrapper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

/// The key used to access the [Paginator]'s state.
final _key = GlobalKey<PaginatorState<FoodPage, String>>();

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping list'),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Paginator<FoodPage, String>(
          key: _key,
          pageLoadFuture: _pageLoadFuture,
          pageErrorChecker: _pageErrorChecker,
          totalItemsGetter: _totalItemsGetter,
          pageItemsGetter: _pageItemsGetter,
          itemListTileBuilder: _itemListTileBuilder,
          loadingListTileBuilder: _loadingListTileBuilder,
          errorListTileBuilder: _errorListTileBuilder,
          emptyListWidgetBuilder: _emptyListWidgetBuilder,
          listBuilder: (context, itemBuilder, itemCount) {
            return ListView.builder(
              itemBuilder: itemBuilder,
              itemCount: itemCount,
            );
          },
        ),
      ),
    );
  }

  /// Gets page data.
  /// Generated with https://www.mockaroo.com/
  /// Served by https://mockapi.io
  Future<FoodPage> _pageLoadFuture(int pageNumber) async {
    const pageSize = '10'; // Use a page size of 10 for the request

    try {
      // Grab and decode the JSON from the API
      final List<dynamic> apiResponse = jsonDecode(
        (await get(
          Uri(
            scheme: 'https',
            host: _endpointHost,
            pathSegments: _endpointPaths,
            queryParameters: {
              'limit': pageSize,
              'page': pageNumber.toString(),
            },
          ),
        ))
            .body,
      );

      // Create the FoodPage object
      // Usually, this total count would be returned by the API.
      // The mock API used in this example doesn't do that, so we hardcode 40.
      return FoodPage(
        40,
        apiResponse.map<String>((e) => e['food']).toList(growable: false),
      );
    } on SocketException {
      // If there's a network problem, make a new page with
      // a null item array.
      // This will be checked later.
      return FoodPage(0, null);
    }
  }

  // Checks for page errors
  bool _pageErrorChecker(FoodPage page) => page.foods == null;

  // Return the total count of items
  int _totalItemsGetter(FoodPage page) => page.totalCount;

  // Return the list of food items
  List<String> _pageItemsGetter(FoodPage page) => page.foods;

  // Build a list tile for an item
  Widget _itemListTileBuilder(BuildContext context, String food, int index) {
    return ListTile(
      leading: Text(food),
    );
  }

  // Build a loading tile
  Widget _loadingListTileBuilder(BuildContext context) {
    return const Align(
      alignment: Alignment.center,
      child: const Padding(
        padding: const EdgeInsets.all(16),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  // Build an error tile, to be shown at the end of the list when there's a network error.
  Widget _errorListTileBuilder(BuildContext context, FoodPage page, int index) {
    return const Align(
      alignment: Alignment.topCenter,
      child: const Text('There was an error fetching the data.'),
    );
  }

  // Build a widget to show when there are no items
  Widget _emptyListWidgetBuilder(BuildContext context, FoodPage page) {
    return const Center(
      child: const Text('No items.'),
    );
  }

  Future<void> _onRefresh() async {
    // Call the [Paginator] state's refresh method
    _key.currentState.refresh();
  }
}

class FoodPage {
  final totalCount;
  final List<String> foods;

  FoodPage(this.totalCount, this.foods);
}
