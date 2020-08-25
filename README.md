# Flutter Pagination Wrapper

A widget that wraps a ListView or any type of ScrollView, and provides pagination functionality.

## Instalation
Add to your pubspec:
```yaml
dependencies:
  flutter_paginator: ^0.1.2
```

Import:
```dart
import 'package:flutter_pagination_wrapper/flutter_pagination_wrapper.dart';
```

## Usage
Now, you can use a `Paginator` widget.  

The `Paginator` takes many different methods used to supply it with data
and to provide builders to build the list items.

It also takes a `PaginatorChildBuilder`, which should use the
given `itemBuilder` method and `temCount` integer to create and return a
ScrollView. The itemBuilder method and itemCount integer can be directly
passed into a `ListView.builder` or `GridView.builder`'s respective arguments.

The various method arguments are documented in the constructor
documentation (and in this README), and allow a lot of flexibility.  

Here, the `listBuilder` returns a `ListView.builder` as an example - but it can be
anything, as long as it uses the passed arguments properly. The one rule is that
the `itemBuilder` should not be called unless the item is going to be displayed on-screen.
```dart
Paginator<ItemType, ItemType>(
  key: _paginationKey,
  pageLoadFuture: pageLoadFuture,
  pageErrorChecker: pageErrorChecker,
  totalItemsGetter: totalItemsGetter,
  pageItemsGetter: pageItemsGetter,
  itemListTileBuilder: itemListTileBuilder,
  loadingListTileBuilder: loadingListTileBuilder,
  errorListTileBuilder: errorListTileBuilder,
  emptyListWidgetBuilder: emptyListWidgetBuilder,
  listBuilder: (context, itemBuilder, itemCount) {
    return ListView.builder(
      itemBuilder: itemBuilder,
      itemCount: itemCount,
    );
  },
 );
```

## Method types for the constructor
This section describes the types of methods that this widget's constructor takes.

**PageLoadFuture**
* Returns a new page (of type PageType). This should contain the data
  to display in that page, as well as any other info to be used by other
  callbacks.

**PageErrorChecker**
* Checks the passed page for errors.
* Returns true if there are any errors.

**TotalItemsGetter**
* Returns an int with the value of the total number of items that
  will ever be displayed.
* The widget will not attempt to load any more data once this count
  has been reached.
* This number can be updated after each new page is loaded.

**PageItemsGetter**
* This method should receive the page object from the PageLoadFuture
  (of type PageType), and return a list of type ItemType.

**ItemListTileBuilder**
* This method should take an item from the list returned from the
  PageItemsGetter, and return a Widget to be rendered in the list.

**LoadingListTileBuilder**
* This method should return a Widget to be displayed at the bottom of
  the list, as the next page loads.

**ErrorListTileBuilder**
* This method should return a Widget to be displayed at the bottom of
  the list if there's an error fetching the new page (that is, if the
  PageErrorChecker returns true).

**EmptyListWidgetBuilder**
* This method should return a Widget that displays when there are no
  items.

## Attribution
This package takes heavy inspiration from [UdaraWanasinghe's flutter_paginator package](https://github.com/UdaraWanasinghe/FlutterPaginator),
and the widget constructor is quite similar - migration should be fairly straightforward.  

The difference between that package and mine is that while that package builds the `ListView` or equivalent for you, mine uses a passed-in builder, allowing for more flexibility.

## License
> Copyright 2020 hacker1024
>
> Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
>
> http://www.apache.org/licenses/LICENSE-2.0
>
> Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.