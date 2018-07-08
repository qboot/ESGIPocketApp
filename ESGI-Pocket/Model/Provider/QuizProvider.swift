//
//  QuizProvider.swift
//  ESGI-Pocket
//
//  Created by pierre piron on 03/06/2018.
//  Copyright © 2018 pierre piron. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class QuizProvider {
    
    func getQuiz(callback: @escaping ([Quiz]) -> ()) {
        
        let url = URL(string: "https://esgipocket.herokuapp.com/quizzes")!

        let headers: HTTPHeaders = ["authorization": CurrentUser.currentUser.jwt]
        
        Alamofire.request(url, headers: headers).responseJSON { response in
            
            var quizList: [Quiz] = []
            
            if response.result.isSuccess {
                
                let json = JSON(response.result.value)
                
                for (index,subJson):(String, JSON) in json {
                    quizList.append(Quiz(json: subJson))
                }
                callback(quizList)
            }
            else {
                callback(quizList)
            }
        }
    }
}