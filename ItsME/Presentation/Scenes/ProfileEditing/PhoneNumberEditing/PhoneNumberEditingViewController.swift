//
//  PhoneNumberEditingViewController.swift
//  ItsME
//
//  Created by Jaewon Yun on 2023/01/10.
//

import SnapKit
import Then
import UIKit

final class PhoneNumberEditingViewController: UIViewController {
    
    private let viewModel: ProfileEditingViewModel
    
    // MARK: - UI Components
    
    private lazy var inputTableView: IntrinsicHeightTableView = .init(style: .insetGrouped).then {
        $0.dataSource = self
        $0.backgroundColor = .clear
    }
    
    var inputCell: ContentsInputCell? {
        inputTableView.visibleCells[ifExists: 0] as? ContentsInputCell
    }
    
    private lazy var completeBarButton: UIBarButtonItem = .init().then {
        $0.primaryAction = .init(title: "완료", handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
            self?.updatePhoneNumber()
        })
    }
    
    // MARK: - Initalizer
    
    init(viewModel: ProfileEditingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemGroupedBackground
        configureSubviews()
        configureNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputCell?.contentsTextField.becomeFirstResponder()
    }
}

// MARK: - Private Functions

private extension PhoneNumberEditingViewController {
    
    func configureSubviews() {
        let safeArea = self.view.safeAreaLayoutGuide
        self.view.addSubview(inputTableView)
        inputTableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeArea)
        }
    }
    
    func configureNavigationBar() {
        self.navigationItem.title = "전화번호 편집"
        self.navigationItem.rightBarButtonItem = completeBarButton
        self.navigationItem.rightBarButtonItem?.style = .done
    }
    
    func updatePhoneNumber() {
        let phoneNumber = inputCell?.contentsTextField.text ?? ""
        viewModel.updatePhoneNumber(phoneNumber)
    }
}

// MARK: - UITableViewDataSource

extension PhoneNumberEditingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ContentsInputCell = .init().then {
            $0.titleLabel.text = "전화번호"
            $0.contentsTextField.text = viewModel.currentPhoneNumber
            $0.contentsTextField.placeholder = "전화"
            $0.contentsTextField.keyboardType = .phonePad
            $0.contentsTextField.delegate = self
        }
        return cell
    }
}

// MARK: - UITextFieldDelegate

extension PhoneNumberEditingViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if range.length > 0 {
            guard
                var currentText = textField.text,
                let removeRange = Range<String.Index>.init(range, in: currentText)
            else {
                return true
            }
            
            currentText.removeSubrange(removeRange)
            let formattedText = formatPhoneNumber(currentText)
            textField.text = formattedText
            return false
        } else {
            let expectedText = (textField.text ?? "") + string
            let formattedText = formatPhoneNumber(expectedText)
            textField.text = formattedText
            return false
        }
    }
}
