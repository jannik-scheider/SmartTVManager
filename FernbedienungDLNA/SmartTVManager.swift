//
//  SmartTVManager.swift
//  FernbedienungDLNA
//
//  Created by Jannik Scheider on 15.05.24.
//

import Foundation
import Combine
import SwiftUPnP


class SmartTVManager: ObservableObject {
    private let registry = UPnPRegistry.shared
    private var currentService: UPnPServiceProtocol?
    private var cancellables = Set<AnyCancellable>()
    @Published var currentVolume: Int = 0

    init() {
        setupEventHandlers()
    }

    func startListening() {
        do {
            try registry.startDiscovery()
        } catch {
            print("Discovery could not be started: \(error)")
        }
    }

    private func setupEventHandlers() {
        registry.deviceAdded
            .sink { [weak self] device in
                guard let self = self,
                      let deviceName = device.deviceDefinition?.device.friendlyName else {
                    print("Error: Device definition not found.")
                    return
                }
                print("Detected device: \(deviceName)")
                self.subscribeToVolumeChanges(device: device)
            }
            .store(in: &self.cancellables)
    }

    @MainActor private func subscribeToVolumeChanges(device: UPnPDevice) {
        guard let service = device.services.first(where: { $0.serviceType.contains("RenderingControl") }) else {
            print("RenderingControl service not found.")
            return
        }
        self.currentService = service  // Store the service for later use in volume adjustment

        service.stateSubject
            .sink { [weak self] change in
                guard let volume = change["CurrentVolume"] as? Int else {
                    print("Error: CurrentVolume not found in change dictionary.")
                    return
                }
                self?.currentVolume = volume
                print("Volume updated to \(volume).")
            }
            .store(in: &self.cancellables)

        Task {
            await service.subscribeToEvents()
        }
    }

    func adjustVolume(change: Int) {
        guard let service = currentService else {
            print("No suitable service found for volume adjustment.")
            return
        }

        Task {
            do {
                let newVolume = currentVolume + change
                _ = try await service.sendAction(name: "SetVolume", parameters: ["Channel": "Master", "DesiredVolume": "\(newVolume)"])
                DispatchQueue.main.async {
                    self.currentVolume = newVolume
                }
                print("Volume adjusted to \(newVolume).")
            } catch {
                print("Failed to adjust volume: \(error)")
            }
        }
    }
}
