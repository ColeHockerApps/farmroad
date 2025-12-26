import Combine
import Foundation

final class LoadingViewModel: ObservableObject {
    @Published private(set) var progress: Double = 0
    @Published private(set) var isFinished: Bool = false

    private let finishedSubject = PassthroughSubject<Void, Never>()
    private var bag = Set<AnyCancellable>()

    var finishedPublisher: AnyPublisher<Void, Never> {
        finishedSubject.eraseToAnyPublisher()
    }

    func reset() {
        progress = 0
        isFinished = false
        bag.removeAll()
    }

    func start(duration: TimeInterval = 2.0) {
        reset()

        let fps: Double = 60.0
        let step = 1.0 / (duration * fps)

        Timer.publish(every: 1.0 / fps, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.isFinished == false else { return }

                self.progress = min(1.0, self.progress + step)
                if self.progress >= 1.0 {
                    self.isFinished = true
                    self.finishedSubject.send(())
                    self.bag.removeAll()
                }
            }
            .store(in: &bag)
    }
}
