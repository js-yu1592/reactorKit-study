//
//  CounterViewController.swift
//  Counter
//
//  Created by 유준상 on 8/19/24.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

class CounterViewController: UIViewController, View {
    
    let decreaseButton: UIButton = .init()
    let increaseButton: UIButton = .init()
    let valueLabel: UILabel = .init()
    let activityIndicator: UIActivityIndicatorView = .init()
    
    var disposeBag: DisposeBag = .init()

    init(reactor: CounterViewReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attribute()
        layout()
    }

    func bind(reactor: CounterViewReactor) {
        // Action
        increaseButton.rx.tap
            .throttle(
                .milliseconds(500),
                latest: false,
                scheduler: MainScheduler.instance
            )
            .map { Reactor.Action.increase }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        decreaseButton.rx.tap
            .throttle(
                .milliseconds(500),
                latest: false,
                scheduler: MainScheduler.instance
            )
            .map { Reactor.Action.decrease }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // State
        reactor.state.map { $0.value }
            .distinctUntilChanged()
            .map { "\($0)" }
            .bind(to: valueLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$alertMessage)
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] message in
                let alertController = UIAlertController(
                    title: nil,
                    message: message,
                    preferredStyle: .alert
                )
                alertController.addAction(
                    UIAlertAction(title: "OK", style: .default, handler: nil)
                )
                self?.present(alertController, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - View
    private func attribute() {
        view.backgroundColor = .systemBackground
        
        decreaseButton.setImage(UIImage(systemName: "minus"), for: .normal)
        
        increaseButton.setImage(UIImage(systemName: "plus"), for: .normal)
        
        valueLabel.textColor = .label
        valueLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
    }
    
    private func layout() {
        [
            valueLabel,
            increaseButton,
            decreaseButton
        ].forEach { view.addSubview($0) }
        
        valueLabel.snp.makeConstraints {
            $0.center.equalTo(view)
        }
        
        decreaseButton.snp.makeConstraints {
            $0.leading.equalTo(view).inset(30)
            $0.centerY.equalTo(view)
            $0.width.height.equalTo(40)
        }
        
        increaseButton.snp.makeConstraints {
            $0.trailing.equalTo(view).inset(30)
            $0.centerY.equalTo(view)
            $0.width.height.equalTo(40)
        }
    }
}

