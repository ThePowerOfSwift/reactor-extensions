//
//  NetworkExtensions.swift
//  ReactorExtensions
//
//  Created by Matthew McArthur on 9/14/17.
//  Copyright © 2017 McArthur. All rights reserved.
//

import Foundation

enum RequestState: String {
    case requested = "Requested"
    case found = "Completed Succesfully"
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
    private var errorMessages = [String : String]()
    
    func requestStateForCommand(key: String) -> RequestState{
        if let requestState = observedCommands[key] {
            return requestState
        }else{
            return .none
        }
    }
    
    func errorMessageForCommand(key: String) -> String? {
        return errorMessages[key]
    }
    
    mutating func react(to event: Event) {
        if let event = event as? NetworkingObservableStateChangeEvent {
            observedCommands[event.commandKey] = event.requestState
            if let errorMessage = event.errorMessage {
                errorMessages[event.commandKey] = errorMessage
            }
        }
    }
}

struct NetworkingObservableStateChangeEvent: Event, CustomStringConvertible {
    
    var description: String {
        get {
            return "\(self.commandKey): \(requestState.rawValue) \(errorMessage ?? "")"
        }
    }
    
    var commandKey: String
    var requestState: RequestState
    var errorMessage: String?
    var errorCode: Int?
    var errorDescription: String?
    
    init(commandKey: String, requestState: RequestState) {
        self.commandKey = commandKey
        self.requestState = requestState
    }
    init(commandKey: String, requestState: RequestState, errorMessage: String?) {
        self.commandKey = commandKey
        self.requestState = requestState
        self.errorMessage = errorMessage
    }
    init(commandKey: String, requestState: RequestState, errorCode: Int?, errorDescription: String?) {
        self.commandKey = commandKey
        self.requestState = requestState
        self.errorCode = errorCode
        self.errorDescription = errorDescription
    }
    init(commandKey: String, requestState: RequestState, errorMessage: String?, errorCode: Int?, errorDescription: String?) {
        self.commandKey = commandKey
        self.requestState = requestState
        self.errorMessage = errorMessage
        self.errorCode = errorCode
        self.errorDescription = errorDescription
    }
}

protocol NetworkObservableCommand {}

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
