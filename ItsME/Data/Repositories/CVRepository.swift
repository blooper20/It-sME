//
//  CVRepository.swift
//  ItsME
//
//  Created by Jaewon Yun on 2022/11/26.
//

import FirebaseAuth
import RxSwift

final class CVRepository {
    
    // MARK: Make to Singleton
    
    static let shared: CVRepository = .init()
    
    private init() {
        self.database = .shared
    }
    
    // MARK: Dependencies
    private let database: DatabaseReferenceManager
    
    // MARK: API
    func getAllCV(byUID uid: String) -> Observable<[CVInfo]> {
        let observable = database.cvsRef(uid).rx.dataSnapshot
            .compactMap { $0.value as? [String: Any] }
            .map { $0.map { key, value in
                return value
            }}
            .map { jsonObject in
                return try LoggedJsonDecoder.decode([CVInfo].self, withJSONObject: jsonObject)
            }
        return observable
    }
    
    func getAllCVOfCurrentUser() -> Observable<[CVInfo]> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .empty()
        }
        return getAllCV(byUID: uid)
    }
    
    func saveCVInfo(_ cvInfo: CVInfo, byUID uid: String) -> Observable<Void> {
        return .create { observer in
            do {
                let data = try JSONEncoder().encode(cvInfo)
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                self.database.cvsRef(uid).child(cvInfo.uuid).setValue(jsonObject)
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func saveCurrentCVInfo(_ cvInfo: CVInfo) -> Observable<Void> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .empty()
        }
        return saveCVInfo(cvInfo, byUID: uid)
    }
    
    func saveCVTitle(_ cvTitle: String, lastModified: String, byUID uid: String, uuid: String) -> Observable<Void> {
        return .create { observer in
            self.database.cvsRef("\(uid)/\(uuid)/title").setValue(cvTitle)
            self.database.cvsRef("\(uid)/\(uuid)/lastModified").setValue(lastModified)
            observer.onNext(())
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func saveCurrentCVTitle(_ cvTitle: String, lastModified: String, uuid: String) -> Observable<Void> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .empty()
        }
        return saveCVTitle(cvTitle, lastModified: lastModified, byUID: uid, uuid: uuid)
    }
    
    func removeCV(_ uuid: String, byUID uid: String) -> Observable<Void> {
        return .create { observer in
            self.database.cvsRef(uid).child(uuid).removeValue()
            observer.onNext(())
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func removeCurrentCVInfo(_ uuid: String) -> Observable<Void> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .empty()
        }
        return removeCV(uuid, byUID: uid)
    }
}

