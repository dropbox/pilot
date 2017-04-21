# Pilot: Cross-platform MVVM in Swift

If you squint, any modern client application can viewed as a "scrollable list of stuff from the internet". Whether it's a scrollable list of food, photos, videos, merchandise, cats, or cat merchandise -- all applications share common scaffolding.

Pilot provides a suite of robust components to take care of this common scaffolding so you can focus on what matters: your data (`Model`), business logic (`ViewModel`), and presentation (`View`).

These components are not overly-prescriptive to any particular application architecture, so you can adopt them without having to rewrite or commit to Pilot forever.

## Component Libraries

Pilot is modularized into components providing building blocks for fast and safe application development (see [flight plan](Documentation/FlightPlan.md) for upcoming components).

- **Pilot**: Provides a core MVVM stack, various model collections, diff engine, action handling, along with some minimal async, observable, and logging components. This is a Foundation-only framework (i.e. No UIKit or AppKit)
- **PilotUI**: UI layer components built atop `Pilot` for both Mac and iOS. Contains collection view bindings and other macOS/iOS extensions for Pilot development.

## Usage

See the [Getting Started](Documentation/GettingStarted.md) guide for a basic walkthrough of core concepts.

There is a [Sample Project](Examples/iTunesSearch) which demonstrates macOS app and iOS app built from the same Pilot MVVM stack.

Otherwise, please see type documentation and let us know if anything is unclear.

## Requirements

- Xcode 8.2
- Swift 3.0
- iOS 9.0+ / macOS 10.11+

## Installation

[![Travis CI](https://travis-ci.org/dropbox/pilot.svg?branch=master)](https://travis-ci.org/dropbox/pilot)

### Xcode

- Drag `Pilot.xcodeproj` into Project Navigator
- Go to `Project > Targets > General > Embed Frameworks`, click `+`, and select `Pilot [Platform]` and `PilotUI [platform]` targets.
- In `Project > Targets > Build Phases > Target Dependencies`, ensure `Pilot [Platform]` and ``PilotUI [Platform]` are there.

## License

[Apache 2.0](LICENSE)


