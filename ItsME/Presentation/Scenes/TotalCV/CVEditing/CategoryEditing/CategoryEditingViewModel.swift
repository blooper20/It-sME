//
//  CategoryEditingViewModel.swift
//  ItsME
//
//  Created by MacBook Air on 2023/03/07.
//

import RxSwift
import RxCocoa

protocol CategoryEditingViewModelDelegate: AnyObject {
    func categoryEditingViewModelDidEndEditing(with resumeItem: ResumeItem, at indexPath: IndexPath?)
    func categoryEditingViewModelDidAppend(resumeItem: ResumeItem)
}

final class CategoryEditingViewModel: ViewModelType {
    
    let resumeItem: ResumeItem
    let editingType: EditingType
    private weak var delgate: CategoryEditingViewModelDelegate?
    
    init(
        resumeItem: ResumeItem,
        editingType: EditingType,
        delegate: CategoryEditingViewModelDelegate? = nil
    ) {
        self.resumeItem = resumeItem
        self.editingType = editingType
        self.delgate = delegate
    }
    
    func transform(input: Input) -> Output {
        
        let endDateString = Driver.merge(
            input.endDate.startWith((year: resumeItem.endYear ?? 0, month: resumeItem.endMonth ?? 0))
                .map { return "\($0.year).\($0.month.toLeadingZero(digit: 2))" },
            input.enrollmentSelection.startWith(())
                .map { return "진행중" },
            input.endSelection
                .map {
                    let year = Calendar.current.currentYear
                    let month = Calendar.current.currentMonth
                    return "\(year).\(month.toLeadingZero(digit: 2))"
                }
        )
        
        let resumeItem = Driver.combineLatest(
            input.title,
            input.secondTitle,
            input.description,
            input.entranceDate
                .startWith((
                    year: resumeItem.entranceYear ?? Calendar.current.currentYear,
                    month: resumeItem.entranceMonth ?? Calendar.current.currentMonth
                )),
            endDateString
        ) {
            (title, secondTitle, description, entranceDate, endDate) -> ResumeItem in
            let period = "\(entranceDate.year).\(entranceDate.month.toLeadingZero(digit: 2)) - \(endDate)"
            return .init(period: period, title: title, secondTitle: secondTitle, description: description)
        }
            .startWith(resumeItem)
        
        let doneHandler = input.doneTrigger
            .withLatestFrom(resumeItem)
            .do(onNext: endEditing(with:))
            .mapToVoid()
        
        return .init(
            resumeItem: resumeItem,
            doneHandler: doneHandler
        )
    }
    
    
    private func endEditing(with resumeItem: ResumeItem) {
        switch editingType {
        case .edit(let indexPath):
            delgate?.categoryEditingViewModelDidEndEditing(with: resumeItem, at: indexPath)
        case .new:
            delgate?.categoryEditingViewModelDidAppend(resumeItem: resumeItem)
        }
    }
}

//    let resumeItem = behaviorRelay.asDriver()
//    return .init(resumeItem: resumeItem)
//}
//
//let behaviorRelay: BehaviorRelay<ResumeItem>
//
//var totalCVViewModel: TotalCVViewModel
//
//var resumeItem: ResumeItem {
//    behaviorRelay.value
//}
//
//init(resumeItem: ResumeItem?, totalCVVM: TotalCVViewModel) {
//    self.behaviorRelay = .init(value: resumeItem ?? ResumeItem(period: "", title: "", secondTitle: "", description: ""))
//    self.totalCVViewModel = totalCVVM
//}
//}

//MARK: - Input & Output
extension CategoryEditingViewModel {
    
    struct Input {
        let title: Driver<String>
        let secondTitle: Driver<String>
        let description: Driver<String>
        let entranceDate: Driver<(year: Int, month: Int)>
        let endDate: Driver<(year: Int, month: Int)>
        let doneTrigger: Signal<Void>
        let enrollmentSelection: Driver<Void>
        let endSelection: Driver<Void>
    }
    
    struct Output {
        let resumeItem: Driver<ResumeItem>
        let doneHandler: Signal<Void>
    }
}

//MARK: - EditingType
extension CategoryEditingViewModel {
    
    enum EditingType {
        
        /// 기존 카테고리 정보를 수정할 때 사용하는 열거형 값입니다.
        case edit(indexPath: IndexPath? = nil)
        
        /// 새 카테고리를 추가할 때 사용하는 열거형 값입니다.
        case new
    }
}
