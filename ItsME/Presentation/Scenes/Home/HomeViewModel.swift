//
//  HomeViewModel.swift
//  It'sME
//
//  Created by Jaewon Yun on 2022/11/09.
//

import RxSwift
import RxCocoa

final class HomeViewModel: ViewModelType {
    
    struct Input {
        let viewDidLoad: Signal<Void>
        let viewWillAppear: Signal<Void>
    }
    
    struct Output {
        let userInfo: Driver<UserInfo>
        let cvsInfo: Driver<[CVInfo]>
    }
    
    private let userRepository: UserRepository = .shared
    private let cvRepository: CVRepository = .shared
    
    private(set) var userInfo: UserInfo = .empty
    
    func removeCV(cvInfo: CVInfo) -> Observable<Void> {
        return self.cvRepository.removeCV(by: cvInfo.uuid).asObservable()
    }
        
    func transform(input: Input) -> Output {
        let userInfo = Signal.merge(input.viewDidLoad, input.viewWillAppear.skip(1))
            .flatMap { _ in
                return self.userRepository.getUserInfo()
                    .asDriverOnErrorJustComplete()
                    .doOnNext { self.userInfo = $0 }
            }
        
        let cvsInfo = Signal.merge(input.viewDidLoad, input.viewWillAppear.skip(1))
            .flatMapLatest { _ in
                return self.cvRepository.getAllCV()
                    .asDriver(onErrorDriveWith: .empty())
            }
        
        return Output(
            userInfo: userInfo,
            cvsInfo: cvsInfo
        )
    }
}

