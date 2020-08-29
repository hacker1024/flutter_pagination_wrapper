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

/// This library provides a [Paginator] widget that builds a child [ScrollView] and supplies
/// methods and properties to use pagination with the child [ScrollView].
library flutter_pagination_wrapper;

import 'package:flutter/material.dart';

typedef PageLoadFuture<PageType> = Future<PageType> Function(int pageNumber);
typedef PageErrorChecker<PageType> = bool Function(PageType page);
typedef TotalItemsGetter<PageType> = int Function(PageType page);
typedef PageItemsGetter<PageType, ItemType> = List<ItemType> Function(
    PageType page);
typedef ItemListTileBuilder<ItemType> = Widget Function(
    BuildContext context, ItemType item, int index);
typedef LoadingListTileBuilder = Widget Function(BuildContext context);
typedef ErrorListTileBuilder<PageType> = Widget Function(
    BuildContext context, PageType page, int existingItemCount);
typedef EmptyListWidgetBuilder<PageType> = Widget Function(
    BuildContext context, PageType page);
typedef PaginatorChildBuilder = BoxScrollView Function(
    BuildContext context, IndexedWidgetBuilder itemBuilder, int itemCount);

/// A widget to supply data to a child [ScrollView] page-by-page.
///
/// This is made to be used with something like a [ListView] or [GridView],
/// and works well with their builder constructors.
///
/// The constructor takes a [PaginatorChildBuilder], which should use the
/// given itemBuilder method and itemCount integer to create and return a
/// [ScrollView]. The itemBuilder method and itemCount integer can be directly
/// passed into a [ListView.builder] or [GridView.builder]'s respective arguments.
///
/// The [initialPage] and [initialPageNumber] arguments may also be passed in.
/// These provide initial data to the list, and default to null and 0
/// respectively.
///
/// The constructor also takes several additional required methods:
///
/// [PageLoadFuture]
///  * Returns a new page (of type [PageType]). This should contain the data
///    to display in that page, as well as any other info to be used by other
///    callbacks.
///
/// [PageErrorChecker]
///  * Checks the passed page for errors.
///  * Returns true if there are any errors.
///
/// [TotalItemsGetter]
///  * Returns an [int] with the value of the total number of items that
///  will ever be displayed.
///  * The widget will not attempt to load any more data once this count
///  has been reached.
///  * This number can be updated after each new page is loaded.
///
/// [PageItemsGetter]
///  * This method should receive the page object from the [PageLoadFuture]
///  (of type [PageType]), and return a list of type [ItemType].
///
/// [ItemListTileBuilder]
///  * This method should take an item from the list returned from the
///  [PageItemsGetter], and return a [Widget] to be rendered in the list.
///
/// [LoadingListTileBuilder]
///  * This method should return a [Widget] to be displayed at the bottom of
///  the list, as the next page loads.
///
/// [ErrorListTileBuilder]
///  * This method should return a [Widget] to be displayed at the bottom of
///  the list if there's an error fetching the new page (that is, if the
///  [PageErrorChecker] returns true).
///
/// [EmptyListWidgetBuilder]
///  * This method should return a [Widget] that displays when there are no
///  items.
class Paginator<PageType, ItemType> extends StatefulWidget {
  final PageLoadFuture<PageType> _pageLoadFuture;
  final PageErrorChecker<PageType> _pageErrorChecker;
  final TotalItemsGetter<PageType> _totalItemsGetter;
  final PageItemsGetter<PageType, ItemType> _pageItemsGetter;
  final ItemListTileBuilder<ItemType> _itemListTileBuilder;
  final LoadingListTileBuilder _loadingListTileBuilder;
  final ErrorListTileBuilder<PageType> _errorListTileBuilder;
  final EmptyListWidgetBuilder<PageType> _emptyListWidgetBuilder;
  final PaginatorChildBuilder _childBuilder;
  final PageType _initialPage;
  final int _initialPageNumber;

  /// See the [Paginator] widget docs for more documentation.
  Paginator({
    Key key,
    @required final PageLoadFuture<PageType> pageLoadFuture,
    @required final PageErrorChecker<PageType> pageErrorChecker,
    @required final TotalItemsGetter<PageType> totalItemsGetter,
    @required final PageItemsGetter<PageType, ItemType> pageItemsGetter,
    @required final ItemListTileBuilder<ItemType> itemListTileBuilder,
    @required final LoadingListTileBuilder loadingListTileBuilder,
    @required final ErrorListTileBuilder<PageType> errorListTileBuilder,
    @required final EmptyListWidgetBuilder<PageType> emptyListWidgetBuilder,
    @required final PaginatorChildBuilder listBuilder,
    final PageType initialPage,
    final int initialPageNumber = 0,
  })  : _pageLoadFuture = pageLoadFuture,
        _pageErrorChecker = pageErrorChecker,
        _totalItemsGetter = totalItemsGetter,
        _pageItemsGetter = pageItemsGetter,
        _itemListTileBuilder = itemListTileBuilder,
        _loadingListTileBuilder = loadingListTileBuilder,
        _errorListTileBuilder = errorListTileBuilder,
        _emptyListWidgetBuilder = emptyListWidgetBuilder,
        _childBuilder = listBuilder,
        _initialPage = initialPage,
        _initialPageNumber = initialPageNumber,
        super(key: key);

  @override
  State<Paginator<PageType, ItemType>> createState() =>
      PaginatorState<PageType, ItemType>();
}

class PaginatorState<PageType, ItemType>
    extends State<Paginator<PageType, ItemType>> {
  final List<ItemType> _list = [];
  int _currentPageNumber;
  int _totalCount = 1;
  bool _isLoading = false;
  bool _hasError = false;
  PageType _latestPage;

  /// The list item count. Passed to your
  /// [PaginatorChildBuilder].
  int get _listItemCount {
    if (_list.length < _totalCount) return _list.length + 1;
    return _totalCount;
  }

  /// Refreshes the list. Clears all data.
  void refresh() {
    setState(() {
      _latestPage = null;
      _hasError = false;
      _isLoading = false;
      _currentPageNumber = 0;
      _totalCount = 1;
      _list.clear();
    });
  }

  /// Builds the item for the [ListView]. Passed to your
  /// [PaginatorChildBuilder].
  Widget _buildItem(BuildContext context, int index) {
    // If there's been an error, show the error tile.
    if ((index == _list.length) && _hasError)
      return widget._errorListTileBuilder(context, _latestPage, _list.length);

    if (index < _list.length) {
      // If the item being built's data is downloaded, build it with that data.
      return widget._itemListTileBuilder(context, _list[index], index);
    } else {
      // If not, request a page load and build the loading tile.
      // This will only happen once per list build, as the count is never more than
      // one above what's downloaded.
      _requestLoadNextPage();
      return widget._loadingListTileBuilder(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPageNumber = widget._initialPageNumber ?? 0;
    if (widget._initialPage != null) {
      // Check for errors
      if (widget._pageErrorChecker(widget._initialPage)) {
        _flagError(widget._initialPage);
        return;
      }

      // Update the page data
      _updateData(widget._initialPage);
    } else {
      assert(widget._initialPageNumber == 0,
          'Initial page number given, but provided page is null!');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the total count's zero, show the empty list widget.
    if (_totalCount == 0)
      return widget._emptyListWidgetBuilder(context, _latestPage);

    // Build the child.
    return widget._childBuilder(
      context,
      _buildItem,
      _listItemCount,
    );
  }

  /// Update the internal data
  void _updateData(PageType newPage) {
    // Update the total item count
    _totalCount = widget._totalItemsGetter(newPage);

    // Add all the new list items
    _list.addAll(widget._pageItemsGetter(newPage));

    // Update the latest page
    _latestPage = newPage;
  }

  /// Requests a new page to be loaded.
  void _requestLoadNextPage() async {
    if (_isLoading) return;
    _isLoading = true;
    await _loadAndAddNextPage();
    _isLoading = false;
  }

  /// Loads the next page, and adds it to the list.
  /// Aborts if the error check is positive.
  Future<void> _loadAndAddNextPage() async {
    // Download the next page
    final newPage = await widget._pageLoadFuture(++_currentPageNumber);

    // Check for errors
    if (widget._pageErrorChecker(newPage)) {
      _flagError(newPage);
      return;
    }

    if (mounted) {
      setState(() {
        _updateData(newPage);
      });
    } else {
      _updateData(newPage);
    }
  }

  /// Flags an error.
  void _flagError(PageType page) {
    void updateData() {
      _latestPage = page;
      _hasError = true;
    }

    if (mounted) {
      setState(() {
        updateData();
      });
    } else {
      updateData();
    }
  }
}
