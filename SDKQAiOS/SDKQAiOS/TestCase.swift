//
//  TestCase.swift
//  SDKQAiOS
//
//  Modelo de casos de prueba para la suite QA del SDK (alineado con Android).
//

import Foundation

/// Representa un caso de prueba en la suite QA del SDK.
struct TestCase {
    let type: TestCaseType
    let title: String
    let category: Category

    enum Category: String, CaseIterable {
        case audio = "Audio"
        case video = "Video"

        var displayName: String { rawValue }
    }

    enum TestCaseType: String, CaseIterable {
        case audioAodSimple
        case audioAodWithService
        case audioEpisode
        case audioLocal
        case audioLocalWithService
        case audioLive
        case audioLiveWithService
        case audioLiveDvr
        case audioMixed
        case audioMixedWithService
        case videoVodSimple
        case videoNextEpisode
        case videoLocal
        case videoLocalWithService
        case videoEpisode
        case videoLive
        case videoLiveDvr
        case videoMixed
        case videoMixedWithService
        case videoReels
    }

    /// Título para mostrar en la lista (categoría + título).
    var displayTitle: String {
        "\(category.displayName): \(title)"
    }

    /// Lista de todos los casos de prueba (mismo orden que Android).
    static func getAllTestCases() -> [TestCase] {
        [
            // Audio
            TestCase(type: .audioAodSimple, title: "AOD Simple", category: .audio),
            TestCase(type: .audioAodWithService, title: "AOD with Service", category: .audio),
            TestCase(type: .audioEpisode, title: "Episode", category: .audio),
            TestCase(type: .audioLocal, title: "Local Audio", category: .audio),
            TestCase(type: .audioLocalWithService, title: "Local Audio with Service", category: .audio),
            TestCase(type: .audioLive, title: "Live Audio", category: .audio),
            TestCase(type: .audioLiveWithService, title: "Live Audio with Service", category: .audio),
            TestCase(type: .audioLiveDvr, title: "Live Audio DVR", category: .audio),
            TestCase(type: .audioMixed, title: "Mixed Audio", category: .audio),
            TestCase(type: .audioMixedWithService, title: "Mixed Audio with Service", category: .audio),
            // Video
            TestCase(type: .videoVodSimple, title: "VOD Simple", category: .video),
            TestCase(type: .videoNextEpisode, title: "Next Episode", category: .video),
            TestCase(type: .videoLocal, title: "Local Video", category: .video),
            TestCase(type: .videoLocalWithService, title: "Local Video with Service", category: .video),
            TestCase(type: .videoEpisode, title: "Episode", category: .video),
            TestCase(type: .videoLive, title: "Live Video", category: .video),
            TestCase(type: .videoLiveDvr, title: "Live Video DVR", category: .video),
            TestCase(type: .videoMixed, title: "Mixed Video", category: .video),
            TestCase(type: .videoMixedWithService, title: "Mixed Video with Service", category: .video),
            TestCase(type: .videoReels, title: "Reels", category: .video)
        ]
    }
}
