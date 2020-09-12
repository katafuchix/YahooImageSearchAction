//
//  ViewModel.swift
//  YahooImageSearchAction
//
//  Created by cano on 2018/10/04.
//  Copyright © 2018年 developer. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import RxOptional
import Kanna

protocol ViewModelInputs {
    // 検索キーワード
    var searchWord: BehaviorRelay<String> { get }
    // 検索トリガ
    var searchTrigger: PublishSubject<Void> { get }
}

protocol ViewModelOutputs {
    // 検索結果
    var items: Observable<[String]> { get }
    var values: BehaviorRelay<[String]> { get }
    // 検索ボタンの押下可否
    var isSearchButtonEnabled: Observable<Bool> { get }
    // 検索中か
    var isLoading: Observable<Bool> { get }
    // エラー
    var error: Observable<ActionError> { get }
}

protocol ViewModelType {
    var inputs: ViewModelInputs { get }
    var outputs: ViewModelOutputs { get }
}


class ViewModel: ViewModelType, ViewModelInputs, ViewModelOutputs {

    // MARK: - Properties
    var inputs: ViewModelInputs { return self }
    var outputs: ViewModelOutputs { return self }

    // Input Sources
    let searchWord = BehaviorRelay<String>(value: "")     // 検索キーワード
    let searchTrigger = PublishSubject<Void>()  // 検索トリガ

    // Output Sources
    let items: Observable<[String]>                    // 検索結果
    let values = BehaviorRelay<[String]>(value: [])
    let isSearchButtonEnabled: Observable<Bool>     // 検索ボタンの押下可否
    let isLoading: Observable<Bool>                 // 検索中か
    let error: Observable<ActionError>              // エラー

    private let action: Action<String, [String]>       // 動作実態部分定義
    private let disposeBag = DisposeBag()

    init() {
        //self.values = BehaviorRelay<[Img]>(value: [])
        self.items = self.values.asObservable()

        // 検索キーワード3文字以上で検索可能に
        self.isSearchButtonEnabled = self.searchWord.asObservable()
            //.filterNil()
            .map { $0.count >= 3 }

        // アクション定義
        self.action = Action { keyword in
            // Yahoo画像検索
            //let urlStr =  "https://search.yahoo.co.jp/image/search?n=60&p=\(keyword)"
            let urlStr =  "https://search.yahoo.co.jp/image/search?ei=UTF-8&p=\(keyword)"
            let url = URL(string:urlStr.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)!

            // User-Agentに自分のメールアドレスをセットしておく
            var request = URLRequest(url: url)
            request.addValue(Constants.mail, forHTTPHeaderField: "User-Agent")

            // 検索結果のHTMLをパースしてimgタグのsrcを配列で返す
            return URLSession.shared.rx.response(request: request)
                .filter{ $0.response.statusCode == 200 }
                .map{ $0.data }
                
                /*.map{ try! HTML(html: $0 as Data, encoding: .utf8) }
                .map{ $0.css("img").compactMap { $0["src"] }.filter { $0.hasPrefix("https://msp.c.yimg.jp") } }
                .map{ $0.compactMap{ Img(src:$0) } }*/
                
                .map { String(data: $0, encoding: .utf8) }
                .map { $0! }
                .compactMap { str in
                    let pattern = "(https?)://msp.c.yimg.jp/([A-Z0-9a-z._%+-/]{2,1024}).jpg"
                    let regex = try! NSRegularExpression(pattern: pattern, options: [])
                    let results = regex.matches(in: str, options: [], range: NSRange(0..<str.count))
                    
                    return results.map { result in
                        let start = str.index(str.startIndex, offsetBy: result.range(at: 0).location)
                        let end = str.index(start, offsetBy: result.range(at: 0).length)
                        let text = String(str[start..<end])
                        return text
                    }.reduce([], { $0.contains($1) ? $0 : $0 + [$1] })
                }.asObservable()
        }

        // 検索トリガ：検索可能な場合に検索キーワードをActionのinputsに渡す
        self.searchTrigger.withLatestFrom(self.searchWord.asObservable())
            //.filterNil()
            .bind(to:self.action.inputs)
            .disposed(by: disposeBag)

        // Actionのoutputsを検索結果に渡す
        self.action.elements
            .bind(to: self.values)
            .disposed(by: disposeBag)

        // 検索中
        self.isLoading = action.executing.startWith(false)

        // エラー
        self.error = action.errors
    }
}
