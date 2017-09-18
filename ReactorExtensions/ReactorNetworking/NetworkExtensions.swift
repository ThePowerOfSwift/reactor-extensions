//
//  NetworkExtensions.swift
//  ReactorExtensions
//
//  Created by Matthew McArthur on 9/14/17.
//  Copyright © 2017 McArthur. All rights reserved.
//

import Foundation
import Reactor

enum RequestState: String {
    case requested = "Requested"
    case success = "Completed Successfully"
    case error = "Error Occurred:"
    case none = "Reset Network State"
    
    func canMoveToState(_ state: RequestState) -> Bool {
        switch self {
        case .requested:
            return state != .requested
        default:
            return true
        }
    }
}

struct NetworkingState: State {
    private var observedCommands = [String : RequestState]()
    private var errorMessages = [String : Error]()
    
    func requestState(forKey key: String) -> RequestState{
        if let requestState = observedCommands[key] {
            return requestState
        }else{
            return .none
        }
    }
    
    func error(forKey key: String) -> Error? {
        return errorMessages[key]
    }
    
    mutating func react(to event: Event) {
        if let event = event as? NetworkingObservableStateChangeEvent {
            observedCommands[event.commandKey] = event.requestState
            if let error = event.error {
                errorMessages[event.commandKey] = error
            }
        }
    }
}

struct NetworkingObservableStateChangeEvent: Event, CustomStringConvertible {
    
    var description: String {
        get {
            return "\(self.commandKey): \(requestState.rawValue) \(error?.localizedDescription ?? "")"
        }
    }
    
    var commandKey: String
    var requestState: RequestState
    var error: Error?
    
    init(commandKey: String, requestState: RequestState, error: Error? = nil) {
        self.commandKey = commandKey
        self.requestState = requestState
        self.error = error
    }
}

protocol NetworkObservableCommand: Command {}

extension Command where Self: NetworkObservableCommand{
    internal static var commandKey: String {
        get {
            return "\(type(of: self))"
        }
    }
    var commandKey: String {
        get {
            return "\(type(of: self).commandKey)"
        }
    }
}
