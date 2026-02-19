//
//  SDKEventListeners.swift
//  SDKQAiOS
//
//  Helper para registrar todos los eventos del SDK en los ejemplos (sin duplicados:
//  para Ads solo onAdEvent + onAdsLoaderInitialize + onAdLoadingError + onAdError).
//

import Foundation
import MediastreamPlatformSDKiOS

enum SDKEventListeners {

    private static func log(_ event: String, info: Any? = nil) {
        if let info = info {
            NSLog("[SDK] %@ %@", event, String(describing: info))
        } else {
            NSLog("[SDK] %@", event)
        }
    }

    /// Registra listeners de todos los eventos del SDK en el EventManager dado.
    /// Para Ads se usa solo onAdEvent (cubre LOADED, STARTED, etc.) más onAdsLoaderInitialize, onAdLoadingError y onAdError.
    static func attachAll(to events: EventManager) {
        // Reproducción
        events.listenTo(eventName: "play") { (info: Any?) in log("play", info: info) }
        events.listenTo(eventName: "pause") { log("pause") }
        events.listenTo(eventName: "finish") { log("finish") }
        events.listenTo(eventName: "seek") { (info: Any?) in log("seek", info: info) }
        events.listenTo(eventName: "ready") { log("ready") }
        events.listenTo(eventName: "buffering") { (info: Any?) in log("buffering", info: info) }
        events.listenTo(eventName: "durationUpdated") { (info: Any?) in log("durationUpdated", info: info) }
        events.listenTo(eventName: "currentTimeUpdate") { (info: Any?) in log("currentTimeUpdate", info: info) }
        events.listenTo(eventName: "failedToPlayToEndTime") { (info: Any?) in log("failedToPlayToEndTime", info: info) }

        // Conexión
        events.listenTo(eventName: "conectionStablished") { log("conectionStablished") }
        events.listenTo(eventName: "conectionLost") { log("conectionLost") }

        // Controles
        events.listenTo(eventName: "forward") { (info: Any?) in log("forward", info: info) }
        events.listenTo(eventName: "backward") { (info: Any?) in log("backward", info: info) }
        events.listenTo(eventName: "volume") { (info: Any?) in log("volume", info: info) }

        // Ads (solo genéricos; onAdEvent cubre LOADED, STARTED, FIRST_QUARTILE, etc.)
        events.listenTo(eventName: "onAdsLoaderInitialize") { (info: Any?) in log("onAdsLoaderInitialize", info: info) }
        events.listenTo(eventName: "onAdLoadingError") { (info: Any?) in log("onAdLoadingError", info: info) }
        events.listenTo(eventName: "onAdEvent") { (info: Any?) in log("onAdEvent", info: info) }
        events.listenTo(eventName: "onAdError") { (info: Any?) in log("onAdError", info: info) }
        events.listenTo(eventName: "onDAIAdEvent") { (info: Any?) in log("onDAIAdEvent", info: info) }

        // Fuentes / carga
        events.listenTo(eventName: "newsourceadded") { log("newsourceadded") }
        events.listenTo(eventName: "localsourceadded") { log("localsourceadded") }
        events.listenTo(eventName: "error") { (info: Any?) in log("error", info: info) }

        // UI
        events.listenTo(eventName: "onFullscreen") { log("onFullscreen") }
        events.listenTo(eventName: "offFullscreen") { log("offFullscreen") }
        events.listenTo(eventName: "onDismissButton") { log("onDismissButton") }
        events.listenTo(eventName: "onSDKRequestDismiss") { log("onSDKRequestDismiss") }

        // Episodios
        events.listenTo(eventName: "nextEpisodeIncoming") { (info: Any?) in log("nextEpisodeIncoming", info: info) }

        // Live / audio
        events.listenTo(eventName: "onLiveAudioCurrentSongChanged") { (info: Any?) in log("onLiveAudioCurrentSongChanged", info: info) }

        // PiP
        events.listenTo(eventName: "pipRestoreFailed") { (info: Any?) in log("pipRestoreFailed", info: info) }
    }

    /// Registra todos los listeners en el SDK (acceso por referencia al SDK).
    static func attachAll(to sdk: MediastreamPlatformSDK) {
        attachAll(to: sdk.events)
    }
}
