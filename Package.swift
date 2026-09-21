// swift-tools-version: 5.9
//
//  Package.swift
//  KitoIslandBar
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "KitoIslandBar",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoIslandBar", targets: ["KitoIslandBar"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "KitoIslandBar", dependencies: [.product(name: "KitoCore", package: "KitoCore")]),
        .testTarget(name: "KitoIslandBarTests", dependencies: ["KitoIslandBar"]),
    ]
)
