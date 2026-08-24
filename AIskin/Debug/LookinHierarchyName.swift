//
//  LookinHierarchyName.swift
//  AIskin
//
//  Semantic hierarchy markers for Lookin. These markers only exist in Debug
//  builds and do not affect the production view hierarchy.
//

import SwiftUI

#if DEBUG
import UIKit

private struct LookinHierarchyMarker: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> LookinNamedView {
        LookinNamedView(name: name)
    }

    func updateUIView(_ uiView: LookinNamedView, context: Context) {
        uiView.name = name
    }
}

private final class LookinNamedView: UIView {
    var name: String {
        didSet {
            accessibilityIdentifier = name
            layer.name = name
        }
    }

    init(name: String) {
        self.name = name
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityIdentifier = name
        layer.name = name
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// LookinServer reads this selector dynamically and uses `title` as the
    /// node title in the hierarchy panel.
    @objc func lookin_customDebugInfos() -> [String: Any]? {
        [
            "title": name,
            "properties": [
                [
                    "section": "Debug Identity",
                    "title": "Semantic Path",
                    "value": name,
                    "valueType": "string"
                ]
            ]
        ]
    }

    /// The marker carries identity only, so Lookin does not need to capture a
    /// transparent screenshot for it.
    @objc func lookin_shouldCaptureImage() -> Bool {
        false
    }
}
#endif

extension View {
    /// Adds a stable semantic node to Lookin without changing the visible UI.
    /// Use dot-separated paths: `screen.section.component`.
    @ViewBuilder
    func lookinName(_ name: String) -> some View {
#if DEBUG
        background {
            LookinHierarchyMarker(name: name)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
#else
        self
#endif
    }
}
