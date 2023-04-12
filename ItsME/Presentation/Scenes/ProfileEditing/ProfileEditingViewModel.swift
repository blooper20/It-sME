//
//  ProfileEditingViewModel.swift
//  ItsME
//
//  Created by Jaewon Yun on 2022/12/01.
//

import FirebaseAuth
import FirebaseStorage
import RxSwift
import RxCocoa
import Then

final class ProfileEditingViewModel: ViewModelType {
    
    struct Input {
        let tapEditingCompleteButton: Signal<Void>
        let userName: Driver<String>
        let viewDidLoad: Driver<Void>
        let logoutTrigger: Signal<Void>
        let newProfileImageData: Driver<Data?>
    }
    
    struct Output {
        let profileImageData: Driver<Data?>
        let userName: Driver<String>
        let userInfoItems: Driver<[UserInfoItem]>
        let educationItems: Driver<[EducationItem]>
        let tappedEditingCompleteButton: Signal<Void>
        let viewDidLoad: Driver<Void>
        let logoutComplete: Signal<Void>
    }
    
    private let userRepository: UserRepository = .shared
    
    private let initalProfileImage: Data
    private let userInfoRelay: BehaviorRelay<UserInfo>
    
    var currentBirthday: Date {
        let birthday = userInfoRelay.value.birthday.contents
        let dateFormatter = DateFormatter.init().then {
            $0.dateFormat = "yyyy.MM.dd."
        }
        return dateFormatter.date(from: birthday) ?? .now
    }
    var currentEmail: String {
        userInfoRelay.value.email.contents
    }
    var currentPhoneNumber: String {
        userInfoRelay.value.phoneNumber.contents
    }
    var currentAddress: String {
        userInfoRelay.value.address.contents
    }
    var currentOtherItems: [UserInfoItem] {
        userInfoRelay.value.otherItems
    }
    var currentAllItems: [UserInfoItem] {
        userInfoRelay.value.allItems
    }
    var currentEducationItems: [EducationItem] {
        userInfoRelay.value.educationItems
    }
    
    init(initalProfileImage: Data?, userInfo: UserInfo) {
        self.initalProfileImage = initalProfileImage ?? .init()
        self.userInfoRelay = .init(value: userInfo)
    }
    
    func transform(input: Input) -> Output {
        let userInfoDriver = userInfoRelay.asDriver()
        
        let viewDidLoad = input.viewDidLoad
            .filter { self.userInfoRelay.value == .empty }
            .flatMapLatest { _ -> Driver<Void> in
                return self.userRepository.getUserInfo()
                    .doOnSuccess { self.userInfoRelay.accept($0) }
                    .mapToVoid()
                    .asDriverOnErrorJustComplete()
            }
        
        let profileImageData = Driver.merge(
            input.newProfileImageData,
            userInfoDriver.flatMap {
                Storage.storage().reference().child($0.profileImageURL).rx.getData().map { $0 }
                    .asDriverOnErrorJustComplete()
            }
        )
            .startWith(initalProfileImage)
            
        let userName = Driver.merge(input.userName,
                                    userInfoDriver.map { $0.name })
            .startWith(userInfoRelay.value.name)
            .doOnNext { self.userInfoRelay.value.name = $0 }
        let userInfoItems = userInfoDriver.map { $0.allItems }
        let educationItems = userInfoDriver.map { $0.educationItems }
        let tappedEditingCompleteButton = input.tapEditingCompleteButton // TODO: Error 처리 고려
            .asObservable()
            .withLatestFrom(profileImageData)
            .compactMap { $0 }
            .flatMap { data in
                let path = try StoragePath().userProfileImage
                return Storage.storage().reference().child(path).rx.putData(data)
            }
            .compactMap { $0.path }
            .flatMap { path in
                let userInfo = self.userInfoRelay.value
                userInfo.profileImageURL = path
                return self.userRepository.saveCurrentUserInfo(userInfo)
            }
            .asSignalOnErrorJustComplete()
        
        let logoutComplete = input.logoutTrigger
            .doOnNext {
                try? Auth.auth().signOut()
                ItsMEUserDefaults.removeAppleUserID()
                ItsMEUserDefaults.isLoggedInAsApple = false
            }
        
        return .init(
            profileImageData: profileImageData,
            userName: userName,
            userInfoItems: userInfoItems,
            educationItems: educationItems,
            tappedEditingCompleteButton: tappedEditingCompleteButton,
            viewDidLoad: viewDidLoad,
            logoutComplete: logoutComplete
        )
    }
}

// MARK: - Internal Functions

extension ProfileEditingViewModel {
    
    func deleteEducationItem(at indexPath: IndexPath) {
        let userInfo = userInfoRelay.value
        userInfo.educationItems.remove(at: indexPath.row)
        userInfoRelay.accept(userInfo)
    }
    
    func updateBirthday(_ userInfoItem: UserInfoItem) {
        let userInfo = userInfoRelay.value
        userInfo.birthday = userInfoItem
        userInfoRelay.accept(userInfo)
    }
    
    func updateEmail(_ email: String) {
        let userInfo = userInfoRelay.value
        userInfo.email.contents = email
        userInfoRelay.accept(userInfo)
    }
    
    func updatePhoneNumber(_ phoneNumber: String) {
        let userInfo = userInfoRelay.value
        userInfo.phoneNumber.contents = phoneNumber
        userInfoRelay.accept(userInfo)
    }
    
    func updateAddress(_ address: String) {
        let userInfo = userInfoRelay.value
        userInfo.address.contents = address
        userInfoRelay.accept(userInfo)
    }
}

// MARK: - EducationEditingViewModelDelegate

extension ProfileEditingViewModel: EducationEditingViewModelDelegate {
    
    func educationEditingViewModelDidEndEditing(with educationItem: EducationItem, at index: IndexPath.Index) {
        let userInfo = userInfoRelay.value
        if userInfo.educationItems.indices ~= index {
            userInfo.educationItems[index] = educationItem
            userInfoRelay.accept(userInfo)
        }
    }
    
    func educationEditingViewModelDidAppend(educationItem: EducationItem) {
        let userInfo = userInfoRelay.value
        userInfo.educationItems.append(educationItem)
        userInfoRelay.accept(userInfo)
    }
    
    func educationEditingViewModelDidDeleteEducationItem(at index: IndexPath.Index) {
        let userInfo = userInfoRelay.value
        userInfo.educationItems.remove(at: index)
        userInfoRelay.accept(userInfo)
    }
}

// MARK: - OtherItemEditingViewModelDelegate

extension ProfileEditingViewModel: OtherItemEditingViewModelDelegate {
    
    func otherItemEditingViewModelDidEndEditing(with otherItem: UserInfoItem, at index: IndexPath.Index) {
        let userInfo = userInfoRelay.value
        if userInfo.otherItems.indices ~= index {
            userInfo.otherItems[index] = otherItem
            userInfoRelay.accept(userInfo)
        }
    }
    
    func otherItemEditingViewModelDidAppend(otherItem: UserInfoItem) {
        let userInfo = userInfoRelay.value
        userInfo.otherItems.append(otherItem)
        userInfoRelay.accept(userInfo)
    }
    
    func otherItemEditingViewModelDidDeleteOtherItem(at index: IndexPath.Index) {
        let userInfo = userInfoRelay.value
        userInfo.otherItems.remove(at: index)
        userInfoRelay.accept(userInfo)
    }
}
