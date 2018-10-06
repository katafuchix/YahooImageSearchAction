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
    var searchWord: Variable<String?> { get }
    // 検索トリガ
    var searchTrigger: PublishSubject<Void> { get }
}

protocol ViewModelOutputs {
    // 検索結果
    var items: Observable<[Img]> { get }
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
    let searchWord = Variable<String?>(nil)     // 検索キーワード
    let searchTrigger = PublishSubject<Void>()  // 検索トリガ

    // Output Sources
    let items: Observable<[Img]>                    // 検索結果
    let isSearchButtonEnabled: Observable<Bool>     // 検索ボタンの押下可否
    let isLoading: Observable<Bool>                 // 検索中か
    let error: Observable<ActionError>              // エラー

    private let action: Action<String, [Img]>       // 動作実態部分定義
    private let disposeBag = DisposeBag()
    private let _items = Variable<[Img]>([])        // 検索結果内部変数

    init() {
        self.items = self._items.asObservable()

        // 検索キーワード3文字以上で検索可能に
        self.isSearchButtonEnabled = self.searchWord.asObservable()
            .filterNil()
            .map { $0.count >= 3 }

        // アクション定義
        self.action = Action { keyword in
            // Yahoo画像検索
            let urlStr =  "https://search.yahoo.co.jp/image/search?n=60&p=\(keyword)"
            let url = URL(string:urlStr.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)!

            // User-Agentに自分のメールアドレスをセットしておく
            var request = URLRequest(url: url)
            request.addValue(Constants.mail, forHTTPHeaderField: "User-Agent")

            // 検索結果のHTMLをパースしてimgタグのsrcを配列で返す
            return URLSession.shared.rx.response(request: request)
                .filter{ $0.response.statusCode == 200 }
                .map{ $0.data }
                .map{ try! HTML(html: $0 as Data, encoding: .utf8) }
                .map{ $0.css("img").compactMap { $0["src"] }.filter { $0.hasPrefix("https://msp.c.yimg.jp") } }
                .map{ $0.compactMap{ Img(src:$0) } }
                .asObservable()
        }

        // 検索トリガ：検索可能な場合に検索キーワードをActionのinputsに渡す
        self.searchTrigger.withLatestFrom(self.searchWord.asObservable())
            .filterNil()
            .bind(to:self.action.inputs)
            .disposed(by: disposeBag)

        // Actionのoutputsを検索結果に渡す
        self.action.elements
            .bind(to: self._items)
        .disposed(by: disposeBag)

        // 検索中
        self.isLoading = action.executing.startWith(false)

        // エラー
        self.error = action.errors
    }
}
