//
//  CVEditViewModel.swift
//  ItsME
//
//  Created by MacBook Air on 2023/04/04.
//

import RxSwift
import RxCocoa

final class CVEditViewModel: ViewModelType {
    
    private let cvRepository: CVRepository = CVRepository.shared
    
    let initialCVTitle: String
    let editingType: EditingType
    
    init(
        initialCVTitle: String,
        editingType: EditingType
    ) {
        self.initialCVTitle = initialCVTitle
        self.editingType = editingType
    }
    
    //MARK: - transform
    func transform(input: Input) -> Output {
        let cvTitle = input.cvTitle
            .startWith(initialCVTitle)
        
        let doneHandler = input.doneTrigger
            .withLatestFrom(cvTitle)
            .flatMap { cvTitle -> Signal<Void> in
                return self.endEditing(withCVTitle: cvTitle)
                    .asSignalOnErrorJustComplete()
            }
            .mapToVoid()
        
        let editingType = Driver.just(editingType)
        
        return .init(
            cvTitle: cvTitle,
            doneHandler: doneHandler,
            editingType: editingType
        )
    }
    
    private func endEditing(withCVTitle title: String) -> Single<Void> {
        let todayString = ItsMEStandardDateFormatter.string(from: .now)
        
        switch editingType {
        case .edit(let uuid):
            return cvRepository.saveCVTitle(title, lastModified: todayString, uuid: uuid)
        case .new:
            let cvInfo: CVInfo = .init(title: title, resume: Resume.empty, coverLetter: CoverLetter.empty, lastModified: todayString)
            return cvRepository.saveCVInfo(cvInfo)
        }
    }
}

// MARK: - Input & Output

extension CVEditViewModel {
    
    struct Input {
        let cvTitle: Driver<String>
        let doneTrigger: Signal<Void>
    }
    
    struct Output {
        let cvTitle: Driver<String>
        let doneHandler: Signal<Void>
        let editingType: Driver<EditingType>
    }
}

// MARK: - EditingType

extension CVEditViewModel {
    
    enum EditingType {
        
        /// 기존 CV 정보를 수정할 때 사용하는 열거형 값입니다.
        case edit(uuid: String)
        
        /// 새 CV를 추가할 때 사용하는 열거형 값입니다.
        case new
    }
}