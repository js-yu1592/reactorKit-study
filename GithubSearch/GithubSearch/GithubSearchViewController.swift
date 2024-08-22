//
//  GithubSearchViewController.swift
//  GithubSearch
//
//  Created by 유준상 on 8/20/24.
//

import SafariServices
import UIKit

import ReactorKit
import RxSwift
import RxCocoa

class GithubSearchViewController: UIViewController, StoryboardView {
    
    @IBOutlet weak var tableView: UITableView!
    let searchController = UISearchController(searchResultsController: nil)
    
    var disposeBag: DisposeBag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 14, *) {
            tableView.verticalScrollIndicatorInsets.top = tableView.contentInset.top
        } else {
            tableView.scrollIndicatorInsets.top = tableView.contentInset.top
        }
        
        // 검색하는 화면과 결과 화면이 같다면 이 프로퍼티를 false로 설정하는걸 추천함.
        if #available(iOS 13, *) {
            searchController.obscuresBackgroundDuringPresentation = false
        } else {
            searchController.dimsBackgroundDuringPresentation = false
        }
        
        navigationItem.searchController = searchController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 뷰의 애니메이션을 끄는 기능인데...왜 사용했을까? 화면 결과는 비슷해보임
        UIView.setAnimationsEnabled(false)
        searchController.isActive = true
        searchController.isActive = false
        UIView.setAnimationsEnabled(true)
    }

    func bind(reactor: GithubSearchViewReactor) {
        // Action
        // UISearchResultUpdating 프로토콜의 updateSearchResult 메서드를 사용해서 searchBar의 text 변화를 관찰할 수도 있음
        searchController.searchBar.rx.text
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.updateQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        tableView.rx.contentOffset
        // 스크롤한 y와 테이블뷰의 높이를 더한 값이 테이블뷰 내용의 높이 - 100만큼보다 클때 다음 페이지를 부르는 액션으로 변경
            .filter { [weak self] offset in
                guard let `self` = self else { return false}
                guard self.tableView.frame.height > 0 else { return false }
                return offset.y + self.tableView.frame.height >= self.tableView.contentSize.height - 100
            }
            .map { _ in Reactor.Action.loadNextPage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // State
        reactor.state.map { $0.repos }
            .bind(to: tableView.rx.items(cellIdentifier: "cell")) { indexPath, repo, cell in
                cell.textLabel?.text = repo
            }
            .disposed(by: disposeBag)
        
        // View
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self, weak reactor] indexPath in
                guard let `self` = self else { return }
                self.view.endEditing(true)
                self.tableView.deselectRow(at: indexPath, animated: false)
                guard let repo = reactor?.currentState.repos[indexPath.row] else { return }
                guard let url = URL(string: "https://github.com/\(repo)") else { return }
                let viewController = SFSafariViewController(url: url)
                self.searchController.present(viewController, animated: true)
            })
            .disposed(by: disposeBag)
    }

}

