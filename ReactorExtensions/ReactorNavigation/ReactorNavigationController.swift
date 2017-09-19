//
//  ReactorNavigationController.swift
//  Navigation
//
//  Created by Matthew McArthur on 8/17/17.
//  Copyright © 2017 McArthur. All rights reserved.
//

import UIKit
import Reactor


public class ReactorNavigationController: UINavigationController, UINavigationBarDelegate, ViewContainer {
    
    private var viewStates: [ReactorViewState] = []
    
    private var viewModel: ViewContainerModelProtocol
    
    // View Container
    public var containerTag: ViewContainerTag
    public var isAnimatingModal = false
    public var modalContainerState: ViewContainerState?
    
    public init(containerTag: ViewContainerTag,viewModel: ViewContainerModelProtocol){
        self.viewModel = viewModel
        self.containerTag = containerTag
        super.init(nibName: nil, bundle: Bundle(for: type(of: self)))
        self.viewModel.delegate = self
    }
    
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    public func update(with state: ViewContainerState) {
        guard let state = state as? NavigationControllerState else {
            return
        }
        checkNavStateChanges(viewControllerStates: state.viewStates)
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
    
    private func checkNavStateChanges(viewControllerStates: [ReactorViewState]){
        if !viewControllerStates.elementsEqual(viewStates, by: { $0.uniqueId == $1.uniqueId }){
            viewStates = viewControllerStates
            updateViewControllers()
        }
    }
    
    private func updateViewControllers() {
        if viewControllers.count < viewStates.count, let pushedState = viewStates.last {
            //Push
            pushViewController(pushedState.viewController(), animated: true)
        }else if viewControllers.count > viewStates.count, let popToState = viewStates.last {
            //Pop/Unwind
            let popToVC = viewControllers.first(){
                if let vcConvertible = $0 as? ViewStateConvertible {
                    return vcConvertible.state().uniqueId == popToState.uniqueId
                }
                return false
            }
            if let popToVC = popToVC{
                popToViewController(popToVC, animated: true)
            }
        }
    }
    
    public func navigationBar(_ navigationBar: UINavigationBar, didPop item: UINavigationItem) {
        if viewStates.count > viewControllers.count {
            viewModel.fireEvent(PopViewEvent(containerId: containerTag))
        }
    }
}
