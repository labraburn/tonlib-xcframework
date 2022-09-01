# ton-swift
## Swift builder for [tonlib](https://github.com/labraburn/ton/tree/labraburn) repository

This is package helps to build **TON.xcframework** and **OpenSSL.xcframework**

## Requirements

- **Xcode** 13.2 +
- **CMake** 3 +
- **Swift** 5.6+

## Supported platfroms

- macOS/simulator/arm64
- iOS/simulator
- macCatalyst/simulator
- watchOS/simulator
- tvOS/simulator

## Usage

Go to repository directory and run:

```sh
swift run builder --output ./build --clean
```


## Notes
- Should be builded with Rosetta on M1 chip
- Default version of OpenSSL used here is 1.1.1i
