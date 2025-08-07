fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the app for testing

### ios test

```sh
[bundle exec] fastlane ios test
```

Run unit tests

### ios ui_test

```sh
[bundle exec] fastlane ios ui_test
```

Run UI tests

### ios test_all

```sh
[bundle exec] fastlane ios test_all
```

Run all tests (unit and UI)

### ios ci

```sh
[bundle exec] fastlane ios ci
```

Build and test

### ios clean

```sh
[bundle exec] fastlane ios clean
```

Clean derived data and build folders

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
