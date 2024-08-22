//
//  GithubSearchService.swift
//  GithubSearch
//
//  Created by 유준상 on 8/22/24.
//

import Foundation
import RxSwift
import RxCocoa

struct GithubSearchService {
    // api function
    private func url(for query: String?, page: Int) -> URL? {
        guard let query = query, !query.isEmpty else { return nil }
        return URL(string: "https://api.github.com/search/repositories?q=\(query)&page=\(page)")
    }
    
    // repo와 nextPage를 담은 Observable을 return
    func search(query: String?, page: Int) -> Observable<(repo: [String], nextPage: Int?)> {
        let emptyResult: ([String], Int?) = ([], nil)
        guard let url = self.url(for: query, page: page) else { return .just(emptyResult) }
        
        return URLSession.shared.rx.json(url: url)
            .map { json -> ([String], Int?) in
                guard let dict = json as? [String: Any] else { return emptyResult}
                guard let items = dict["items"] as? [[String: Any]] else { return emptyResult}
                let repos = items.compactMap { $0["full_name"] as? String }
                let nextPage = repos.isEmpty ? nil : page + 1
                return (repos, nextPage)
            }
        // 특정 이벤트가 발생했을때 실행되는 콜백 함수를 등록하고 싶을때 do(on:) 메서드 사용
        // Side Effetcts
        // do(onError:)는 에러 이벤트가 발생했을때 사용
            .do(onError: { error in
                if case let .some(.httpRequestFailed(response, _)) = error as? RxCocoaURLError,
                   response.statusCode == 403 {
                    print("⚠️ GitHub API rate limit exceeded. Wait for 60 seconds and try again.")
                }
            })
        // error가 발생했을때 어떤 가공이 들어가지 않고 바로 element를 방출할 때 사용
            .catchAndReturn(emptyResult)
    }
}
