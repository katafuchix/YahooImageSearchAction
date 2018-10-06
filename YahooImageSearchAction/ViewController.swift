//
//  ViewController.swift
//  YahooImageSearchAction
//
//  Created by cano on 2018/10/04.
//  Copyright © 2018年 developer. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MBProgressHUD

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!

    private let viewModel = ViewModel()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.bind()
    }

    func bind() {
        // 入力欄の値を検索キーワードにbind
        self.textField.rx.text.orEmpty
            .bind(to: self.viewModel.inputs.searchWord)
            .disposed(by: self.disposeBag)

        // キーボードを下げる
        self.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .drive(onNext: { [weak self] _ in
                self?.textField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)

        // 検索ボタン押下時に検索トリガを起動
        self.searchButton.rx.tap.asDriver()
            .drive(self.viewModel.searchTrigger)
            .disposed(by: self.disposeBag)

        // 検索可能な場合は検索ボタンを押下可能に
        self.viewModel.outputs.isSearchButtonEnabled
            .asObservable()
            .bind(to: self.searchButton.rx.isEnabled)
            .disposed(by: self.disposeBag)

        // 検索結果をコレクションで表示
        self.viewModel.outputs.items.asObservable()
            .bind(to: self.collectionView.rx.items(cellIdentifier: "ImageItemCell", cellType: ImageItemCell.self)) {
            (index, element, cell) in
                cell.configure(URL(string: element.src)!)
            }.disposed(by: self.disposeBag)

        // 検索中はMBProgressHUDを表示
        self.viewModel.outputs.isLoading.asDriver(onErrorJustReturn: false)
            .drive(MBProgressHUD.rx.isAnimating(view: self.view))
            .disposed(by: disposeBag)

        // エラー表示 検索ボタンの連打で動作確認可能
        self.viewModel.outputs.error
            .subscribe(onNext: { [weak self] error in
                let alert = UIAlertController(title: "エラー", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }

}
