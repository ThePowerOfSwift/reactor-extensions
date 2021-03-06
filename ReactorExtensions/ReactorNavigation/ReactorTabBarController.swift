//
//  ReactiveTabBarController.swift
//  Navigation
//
//  Created by Matthew McArthur on 8/16/17.
//  Copyright © 2017 McArthur. All rights reserved.
//

import UIKit
import Reactor

public class ReactorTabBarController: UITabBarController, UITabBarControllerDelegate, ViewContainer {
    
    private var viewModel: ViewContainerModelProtocol
    private var tabStates: [TabState] = []
    private var tabViewControllers: [UIViewController?] = []
    
    // MARK: ViewContainer Protocol
    public var containerTag: ViewContainerTag
    public var modalContainerState: ViewContainerState?
    public var isAnimatingModal = false
    
    public init(containerTag: ViewContainerTag, viewModel: ViewContainerModelProtocol){
        self.containerTag = containerTag
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: Bundle(for: type(of: self)))
    }
    
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        delegate = self
        viewModel.delegate = self
    }
    
    public func update(with state: ViewContainerState) {
        guard let state = state as? TabControllerState else {
            return
        }
        checkTabStateChanges(tabs: state.tabs, index: state.selectedIndex)
        checkModalChange(modalSate: state.modal)
    }
    
    private func checkModalChange(modalSate: ViewContainerState?){
        guard isAnimatingModal == false else {
            return
        }
        if let modalSate = modalSate, self.modalContainerState == nil {
            isAnimatingModal = true
            self.modalContainerState = modalSate
            let vc = viewModel.viewController(forState: modalSate)
            present(vc, animated: true, completion: { [weak self] in
                self?.isAnimatingModal = false
            })
        }else if modalSate == nil && self.modalContainerState != nil {
            isAnimatingModal = true
            self.modalContainerState = nil
            dismiss(animated: true, completion: { [weak self] in
                self?.isAnimatingModal = false
            })
        }
    }
    
    // use delegate method to control tab selection with reactor
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = viewControllers?.index(of: viewController)
        if let index = index {
            self.viewModel.fireEvent(ChangeTabEvent(containerId: containerTag, selectedIndex: index))
        }
        return false
    }
    
    private func checkTabStateChanges(tabs: [TabState], index: Int){
        
        if tabs != tabStates {
            tabStates = tabs
            updateViewControllers()
        }
        if index != self.selectedIndex && index < viewControllers?.count ?? 0 {
            selectedIndex = index
        }
    }
    
    private func updateViewControllers() {
        
        if tabStates.count != tabViewControllers.count {
            tabViewControllers.removeAll()
            for i in 0..<tabStates.count {
                let tabState = tabStates[i]
                if tabState.hidden {
                    tabViewControllers.append(nil)
                }else{
                    let vc = viewModel.viewController(forState: tabState.tab)
                    vc.tabBarItem = UITabBarItem(title: tabState.tabTitle, image: nil, tag: i)
                    tabViewControllers.append(vc)
                }
            }
        }else{
            for i in 0..<tabStates.count {
                let tabState = tabStates[i]
                var currentVC = tabViewControllers[i]
                if tabState.hidden {
                    currentVC = nil
                    continue
                }else if currentVC == nil {
                    let vc = viewModel.viewController(forState: tabState.tab)
                    currentVC = vc
                }
                tabViewControllers[i] = currentVC
            }
        }
        setViewControllers(tabViewControllers.flatMap({ $0 }), animated: true)
    }
}
