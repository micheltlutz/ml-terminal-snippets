import Testing
@testable import {{PROJECT_NAME}}

@Test func greetingIsNonEmpty() {
    #expect(!{{PROJECT_NAME}}().greeting.isEmpty)
}
