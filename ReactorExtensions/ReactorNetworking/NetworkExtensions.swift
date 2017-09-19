//
//  NetworkExtensions.swift
//  ReactorExtensions
//
//  Created by Matthew McArthur on 9/14/17.
//  Copyright © 2017 McArthur. All rights reserved.
//

import Foundation
import Reactor

public enum RequestState: String {
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

public struct NetworkingState: State {
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
    
    mutating public func react(to event: Event) {
        if let event = event as? NetworkingChangeEvent {
            observedCommands[event.commandKey] = event.requestState
            if let error = event.error {
                errorMessages[event.commandKey] = error
            }
        }
    }
}

public struct NetworkingChangeEvent: Event, CustomStringConvertible {
    
    public var description: String {
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

public protocol NetworkObservableCommand: Command {}

extension Command where Self: NetworkObservableCommand{
    public static var commandKey: String {
        get {
            return "\(type(of: self))"
        }
    }
    public var commandKey: String {
        get {
            return "\(type(of: self).commandKey)"
        }
    }
}
