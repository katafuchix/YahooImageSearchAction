# YahooImageSearchAction
## Getting Started
edit Constants.swift like this.
```
struct Constants {
    // e-mail address
    static let mail          = "xxx@yyyy.com"
}
```

after put Constants.swift in this project, pod install.

### Examples in this xcode project
- getting items from Yahoo Image Search
- creating table with RxSwift, Action
- extended MBProgressHUD with Reactive.
- example of MVVM base.

### Screen capture
<div>
<img src="https://user-images.githubusercontent.com/6063541/46567972-9c47a680-c978-11e8-83cc-7acda380e224.png" width="200">
<img src="https://user-images.githubusercontent.com/6063541/46567973-9c47a680-c978-11e8-9306-9eeb232f44a0.png" width="200">
<img src="https://user-images.githubusercontent.com/6063541/46567974-9c47a680-c978-11e8-9d40-1d13bae914d6.png" width="200">
<img src="https://user-images.githubusercontent.com/6063541/46567975-9c47a680-c978-11e8-946a-7e381c8f3dbf.png" width="200">
</div>

- ViewModel

```

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
        self.items = self.values.asObservable()

        // 検索キーワード3文字以上で検索可能に
        self.isSearchButtonEnabled = self.searchWord.asObservable()
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
```
