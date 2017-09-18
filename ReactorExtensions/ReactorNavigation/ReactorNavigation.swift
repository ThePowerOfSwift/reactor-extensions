//
//  ReactorNavigation.swift
//  Navigation
//
//  Created by Matthew McArthur on 8/17/17.
//  Copyright © 2017 McArthur. All rights reserved.
//

import UIKit
import Reactor

// MARK: Navigation State Protocol

protocol NavigationState: State {
    var rootViewContainer: ViewContainerState { get set }
    static func viewContainerForState(_ viewContainerState: ViewContainerState) -> UIViewController
}

protocol ViewStateConvertible {
    func state() -> ReactorViewState
}

protocol Identifiable {
    var uniqueId: String { get }
}

// View State
protocol ReactorViewState: Identifiable {
    func viewController() -> UIViewController
}

// View Containers
protocol ViewContainer {
    var containerTag: ViewContainerTag { get }
    var modalContainerState: ViewContainerState? { get }
    var isAnimatingModal: Bool { get set }
}

protocol ViewContainerModel {
    func fireEvent(_ event: Event)
    func viewController(forState state: ViewContainerState) -> UIViewController
}

protocol ViewContainerTag: Identifiable {}
extension ViewContainerTag {
    var uniqueId: String {
        return "\(type(of: self))"
    }
}

protocol ViewContainerState: State {
    var containerTag: ViewContainerTag { get }
    var modal: ViewContainerState? { get set }
}

extension ViewContainerState {
    
    func findSubstateWithId(_ id: ViewContainerTag) -> ViewContainerState?{
        if id.uniqueId == self.containerTag.uniqueId{
            return self
        }else if let tabContainer = self as? TabControllerState {
            for tab in tabContainer.tabs {
                if let foundState = tab.tab.findSubstateWithId(id) {
                    return foundState
                }
            }
            if let foundState = modal?.findSubstateWithId(id){
                return foundState
            }
        }else if let navContainer = self as? NavigationControllerState {
            if navContainer.containerTag.uniqueId == id.uniqueId {
                return navContainer
            }
            if let foundState = modal?.findSubstateWithId(id){
                return foundState
            }
        }
        return nil
    }
}

struct TabControllerState: ViewContainerState {
    var containerTag: ViewContainerTag
    var selectedIndex: Int
    var tabs: [TabState]
    var modal: ViewContainerState? = nil
    
    init(containerTag: ViewContainerTag, selectedIndex: Int, tabs: [TabState]) {
        self.containerTag = containerTag
        self.selectedIndex = selectedIndex
        self.tabs = tabs
    }
}

struct TabState: Equatable {

    static func ==(lhs: TabState, rhs: TabState) -> Bool {
        return lhs.tab.containerTag.uniqueId == rhs.tab.containerTag.uniqueId && lhs.hidden == rhs.hidden
    }

    var tab: NavigationControllerState
    var hidden: Bool
    let tabTitle: String
    
}

struct NavigationControllerState: ViewContainerState {
    var containerTag: ViewContainerTag
    var viewStates: [ReactorViewState]
    var modal: ViewContainerState? = nil
    
    init(containerTag: ViewContainerTag, viewStates: [ReactorViewState]) {
        self.containerTag = containerTag
        self.viewStates = viewStates
    }
}

// View Container State

extension TabControllerState {
    
    mutating func react(to event: Event) {
        if let event = event as? NavigationEvent {
            if event.containerId.uniqueId == self.containerTag.uniqueId {
                switch event {
                case let event as ChangeTabEvent:
                    self.selectedIndex = event.selectedIndex
                case let event as ModalToViewEvent:
                    self.modal = event.modal
                case is DismissModalEvent:
                    self.modal = nil
                default:
                    break
                }
            }else{
                for index in 0..<tabs.count {
                    tabs[index].tab.react(to: event)
                }
                modal?.react(to: event)
            }
        }
    }
}

extension NavigationControllerState {
    
    mutating func react(to event: Event) {
        if let event = event as? NavigationEvent {
            if event.containerId.uniqueId == self.containerTag.uniqueId {
                switch event {
                case let event as PushViewEvent:
                    self.viewStates.append(event.view)
                case is PopViewEvent:
                    if self.viewStates.count > 1 {
                        _ = self.viewStates.popLast()
                    }
                case let event as ModalToViewEvent:
                    self.modal = event.modal
                case is DismissModalEvent:
                    self.modal = nil
                default:
                    break
                }
            }else {
                modal?.react(to: event)
            }
        }
    }
    
}

// State Events

protocol NavigationEvent: Event {
    var containerId: ViewContainerTag { get set }
}

// Shared events
struct ModalToViewEvent: NavigationEvent {
    let modal: ViewContainerState
    var containerId: ViewContainerTag
}

struct DismissModalEvent: NavigationEvent {
    var containerId: ViewContainerTag
}

// Tab Events
struct ChangeTabEvent: NavigationEvent {
    let selectedIndex: Int
    var containerId: ViewContainerTag
}

// Navigation Controller Events
struct PushViewEvent: NavigationEvent {
    let view: ReactorViewState
    var containerId: ViewContainerTag
}

struct PopViewEvent: NavigationEvent {
    var containerId: ViewContainerTag
}
