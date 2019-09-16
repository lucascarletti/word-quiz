import XCTest
@testable import WordQuiz

class WordQuizTests: XCTestCase {
//MARK: - Successfull tests
    func testInitialState() {
        let dataMock = DataMockSuccess()
        let viewModel = QuizViewModel(service: dataMock)
        XCTAssertTrue(viewModel.hittenWords.count == 0)
        XCTAssertTrue(viewModel.wordsDataSource.count == 0)
        XCTAssertTrue(viewModel.state == nil)
    }
    
    func testRunningState() {
        let dataMock = DataMockSuccess()
        let viewModel = QuizViewModel(service: dataMock)
        
        viewModel.shouldChangeQuizState()
        XCTAssertTrue(viewModel.state == .running)
    }
    
    func testStoppedState() {
        let dataMock = DataMockSuccess()
        let viewModel = QuizViewModel(service: dataMock)
        
        viewModel.shouldChangeQuizState()
        viewModel.shouldChangeQuizState()
        XCTAssertTrue(viewModel.state == .stopped)
    }
    
    func testHittingWord() {
        let dataMock = DataMockSuccess()
        let viewModel = QuizViewModel(service: dataMock)
        viewModel.initialize()
        
        viewModel.didUpdateTextField(withText: "case")
        XCTAssertTrue(viewModel.hittenWords.contains("case"))
        XCTAssertTrue(viewModel.hittenWords.count == 1)
    }
    
    func testHittingRepeatedWord() {
        let dataMock = DataMockSuccess()
        let viewModel = QuizViewModel(service: dataMock)
        viewModel.initialize()
        
        viewModel.didUpdateTextField(withText: "case")
        viewModel.didUpdateTextField(withText: "case")
        viewModel.didUpdateTextField(withText: "case")
        XCTAssertTrue(viewModel.hittenWords.contains("case"))
        XCTAssertTrue(viewModel.hittenWords.count == 1)
    }
    
    func testHittingTwoWords() {
        let dataMock = DataMockSuccess()
        let viewModel = QuizViewModel(service: dataMock)
        viewModel.initialize()
        
        viewModel.didUpdateTextField(withText: "byte")
        viewModel.didUpdateTextField(withText: "case")
        XCTAssertTrue(viewModel.hittenWords.count == 2)
    }
    
    func testDataSourceCount() {
        let validationSource = ["abstract",
                                "assert",
                                "boolean",
                                "break",
                                "byte",
                                "case"]
        
        let dataMock = DataMockSuccess()
        let viewModel = QuizViewModel(service: dataMock)
        viewModel.initialize()
        
        XCTAssertTrue(viewModel.wordsDataSource.count == validationSource.count)
    }

    func testShouldAllowReplacement() {
        let dataMock = DataMockSuccess()
        let viewModel = QuizViewModel(service: dataMock)
        viewModel.initialize()
        
        viewModel.didUpdateTextField(withText: "case")
        XCTAssertTrue(viewModel.shouldAllowTextFieldReplacementString(fromText: "case"))
    }

    func testDataSourceStateFailure() {
        let dataMock = DataMockFailure()
        let viewModel = QuizViewModel(service: dataMock)
        viewModel.initialize()
        
        XCTAssertTrue(viewModel.hittenWords.isEmpty)
        XCTAssertTrue(viewModel.wordsDataSource.isEmpty)
        XCTAssertTrue(viewModel.state == nil)
    }
}

struct DataMockSuccess: QuizServiceProtocol {
    func getQuestions(endpoint: QuizEndPoint, completion: ((Quiz?, String?) -> Void)?) {
        let q = Quiz()
        
        q.answer = ["abstract",
                    "assert",
                    "boolean",
                    "break",
                    "byte",
                    "case"]
        
        q.question = "What are all the answers in java?"
        
        completion?(q, nil)
    }
}

struct DataMockFailure: QuizServiceProtocol {
    func getQuestions(endpoint: QuizEndPoint, completion: ((Quiz?, String?) -> Void)?) {
        completion?(nil, "Something Went Wrong")
    }
}
