//
//  GithubSearchViewReactor.swift
//  GithubSearch
//
//  Created by 유준상 on 8/20/24.
//

import ReactorKit
import RxSwift
import RxCocoa

final class GithubSearchViewReactor: Reactor {
    
    enum Action {
        // 서치바에서 텍스트가 변경될때 query를 update하기 위한 액션
        case updateQuery(String?)
        // 테이블뷰의 스크롤을 어느정도 특정만큼 내렸을때 다음 페이지의 데이터를 불러오기 위한 액션
        case loadNextPage
    }
    
    enum Mutation {
        // 데이터를 불러오기 위한 query를 설정
        case setQuery(String?)
        // 검색 결과를 보여주기 위해 repos를 설정
        case setRepos([String], nextPage: Int?)
        // 검색 결과에 또 다른 repo를 append
        case appendRepos([String], nextPage: Int?)
        //
        case setLoadingNextPage(Bool)
    }
    
    struct State {
        // action -> State로 변경
        // mutation의 setQuery를 통해 set
        var query: String?
        // 초기 repos 뷰로 보여줌
        // mutation의 setRepos를 통해 set
        // mutation의 appendRepos를 통해 repos 배열에 결과를 더함
        var repos: [String] = []
        // mutation의 setRepos, appendRepos를 통해 nextPage 값 변화
        var nextPage: Int?
        // loadNextPage 액션을 통해 데이터를 부를지 결정을 위해 필요. false일때만 데이터를 load
        var isLoadingNextPage: Bool = false
    }
    
    let initialState: State = .init()
    let service: GithubSearchService = .init()
    
    // action을 mutation으로 변경
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateQuery(let query):
            // concat은 여러 Observable을 연결하는 오퍼레이터
            return Observable.concat([
                Observable.just(Mutation.setQuery(query)),
                
                // 첫번째 페이지의 데이터를 부름
                service.search(query: query, page: 1)
                // take는 처음 발생하는 n개의 이벤트만 받고 나머지는 무시
                // trigger 시퀀스가 until의 소스에 들어가고 trigger시퀀스에 이벤트가 발생하면 이후 이벤트는 무시된다.
                // 즉, query가 update되면 이후 이벤트가 무시. api는 한번만 불리게 된다.
                    .take(until: self.action.filter(Action.isUpdateQueryAction))
                // (repo: [String], nextPage: Int?)를 받아 repo를 set해줌
                    .map { Mutation.setRepos($0, nextPage: $1) },
                // 다음 페이지를 load 하는것을 방지
                Observable.just(Mutation.setLoadingNextPage(false))
            ])
            
        case .loadNextPage:
            // nextPage가 nil이 아니고, isLoadingNextPage가 false일때 다음 페이지를 load
            guard !self.currentState.isLoadingNextPage else { return Observable.empty() }
            guard let page = self.currentState.nextPage else { return Observable.empty() }
            
            return Observable.concat([
                Observable.just(Mutation.setLoadingNextPage(true)),
                
                service.search(query: self.currentState.query, page: page)
                    .take(until: self.action.filter(Action.isUpdateQueryAction))
                    .map { Mutation.appendRepos($0, nextPage: $1) },
                
                Observable.just(Mutation.setLoadingNextPage(false))
            ])
        }
    }
    
    // state, mutation을 통해 새로운 state return
    func reduce(state: State, mutation: Mutation) -> State {
        switch mutation {
        case .setQuery(let query):
            var newState = state
            newState.query = query
            return newState
            
        case .setRepos(let repos, let nextPage):
            var newState = state
            newState.repos = repos
            newState.nextPage = nextPage
            return newState
            
        case .appendRepos(let repos, let nextPage):
            var newState = state
            newState.repos.append(contentsOf: repos)
            newState.nextPage = nextPage
            return newState
            
        case .setLoadingNextPage(let isLoadingNextPage):
            var newState = state
            newState.isLoadingNextPage = isLoadingNextPage
            return newState
            
        }
    }
    
}

extension GithubSearchViewReactor.Action {
    // updateQuery 액션이 들어왔을때 변경되었는가를 bool type으로 return
    // case로는 구현 불가하기 때문에 extension을 해주고 구현
    static func isUpdateQueryAction(_ action: GithubSearchViewReactor.Action) -> Bool {
        if case .updateQuery = action {
            return true
        } else {
            return false
        }
    }
}
