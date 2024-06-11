//
//  ContentView.swift
//  SwiftUIFlowCoordinatorPattern
//
//  Created by Hakob Ghlijyan on 11.06.2024.
//

import SwiftUI

struct ContentViewMain: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentViewMain()
}

// Координация навигации по вью в SwiftUI с помощью паттерна Flow Coordinator

/*
 
  
  В этой статье я продемонстрирую, как можно использовать паттерн Flow Coordinator (далее флоу-координатор) в SwiftUI, чтобы отделить логику навигации от логики представления.
  В UIKit этот шаблон был очень популярен - координаторы такого рода позволяют легко заменять или создавать новые вью-контроллеры (view controller), отделяя эту работу от кода вью-контроллеров и вью-моделей (view model). Это позволяет разделить во вью-контроллере код, затрагивающий саму вьюху, и навигацию, что в свою очередь облегчает изменение “потока приложения” (того самого флоу).
  В некоторой степени подобное можно реализовать и в SwiftUI.
  

  1. Навигационные примитивы в SwiftUI
  Большую часть навигации в SwiftUI можно выполнить с помощью @Binding, сохраняющего состояние активации навигации, а также специальных модификаторов и вьюх SwiftUI, таких как fullScreenCover, sheet, alert, confirmationDialog или NavigationLink:
  
  
  NavigationLink( “Purple”, destination: ColorDetail(color: .purple), isActive: $shouldShowPurple)
  NavigationLink(tag: .firstLink, selection: activeLink, destination: firstDestination) { EmptyView() }
  
  
  И для представления модальных окон мы можем использовать что-то вроде это:
  
  view .sheet(isPresented: $isShowingSheet, onDismiss: didDismiss) {
    Text(“License Agreement”)
   }
  view.sheet(item: sheetItem, content: sheetContent)

  
  2. Вью и вью-модель
  Обычно мы отделяем логику вью от бизнес-логики (или подготовки данных вью) путем разделения кода на непосредственно вью (View) и вью-модель (ViewModel).
  Вью-модель должна подготовить все необходимые данные для отображения во вью (выходные данные) и обрабатывать все экшены, поступающие из вью (входные данные).
  Вью же должно просто обрабатывать отображение этих данных и размещение их на экране.
  Простое вью может выглядеть следующим образом:
  

  
  example ->
  
  struct ContentView<VM: ContentViewModelProtocol>: View {

      @StateObject var viewModel: VM

      var body: some View {
          ZStack {
              Color.white.ignoresSafeArea()

              VStack {
                  Text(viewModel.text)

                  Button("First view >", action: viewModel.firstAction)
              }
          }
          .navigationBarTitle("Title", displayMode: .inline)
      }
  }
  


 // Вью-модель для этого вью будет подготавливать текст для отображения и обрабатывать firstAction следующим образом:


  
  protocol ContentViewModelProtocol: ObservableObject {
      var text: String { get }

      func firstAction()
  }

  final class ContentViewModel: ContentViewModelProtocol {

      let text: String = "Content View"

      init() { }

      func firstAction() {
          // handle action
      }
  }

  
  3. Создаем флоу-координатор
  В SwiftUI, чтобы все корректно работало, все примитивы навигации должны вызываться в контексте вью. Таким образом, мы можем сразу сделать некоторые выводы о наших флоу-координаторах:
  1. Флоу-координатор — это вью.
  2. У нас должны быть флоу-координаторы для каждого экрана.
  3. События навигации должны передаваться флоу-координатору из вью-модели.
  4. Нам потребуется какое-нибудь перечисление, которое будет содержать эти события навигации.

  
  3.1 Создаем протокол, представляющий состояние флоу-координатора
  Этот протокол позволяет нам передавать события навигации из вью-модели во флоу-координатор.
  


 protocol ContentFlowStateProtocol: ObservableObject {
     var activeLink: ContentLink? { get set }
 }



  
  ContentLink — это перечисление, представляющее различные навигационные события/экшены.
  
  Этот протокол должен быть реализован нашей вью-моделью. Таким образом, вью-модель в ответ на действия пользователя (экшены) будет обрабатывать их и передавать навигационные события флоу-координатору через FlowStateProtocol.
  
  Итак, наша полная ContentViewModel, обрабатывающая несколько пользовательских действий и реализующая ContentFlowStateProtocol, может выглядеть следующим образом:
  

 protocol ContentViewModelProtocol: ObservableObject {
     var text: String { get }

     func firstAction()
     func secondAction()
     func thirdAction()
     func sheetAction()
 }

 final class ContentViewModel: ContentViewModelProtocol, ContentFlowStateProtocol {

     // MARK: - Flow State
     @Published var activeLink: ContentLink?

     // MARK: - View Model
     let text: String = "Content View"

     init() { }

     func firstAction() {
         activeLink = .firstLinkParametrized(text: "Some param")
     }

     func secondAction() {
         activeLink = .secondLinkParametrized(number: 2)
     }

     func thirdAction() {
         activeLink = .thirdLink
     }

     func sheetAction() {
         activeLink = .sheetLink(item: "Sheet param")
     }
 }
  
  3.2 Создаем перечисления ContentLink для навигационных событий
  Это перечисление определяет различные навигационные события, которые могут происходить в рамках экрана нашего приложения. Этим событиям могут передаваться параметры. Кроме того перечисление ContentLink должно быть Identifiable и Hashable.
  



 enum ContentLink: Hashable, Identifiable {
     case firstLink
     case firstLinkParametrized(text: String)
     case secondLink
     case secondLinkParametrized(number: Int)
     case thirdLink

     case sheetLink(item: String)

     var navigationLink: ContentLink {
         switch self {
         case .firstLinkParametrized:
             return .firstLink
         case .secondLinkParametrized:
             return .secondLink
         default:
             return self
         }
     }

     var sheetItem: ContentLink? {
         switch self {
         case .sheetLink:
             return self
         default:
             return nil
         }
     }

     var id: String {
         switch self {
         case .firstLink, .firstLinkParametrized:
             return "first"
         case .secondLink, .secondLinkParametrized:
             return "second"
         case .thirdLink:
             return "third"
         case let .sheetLink(item):
             return item
         }
     }
 }

  
  В этом перечислении мы определяем несколько вычисляемых свойств, а именно id для реализации протокола Identifiable, navigationLink для сопоставления параметризованных событий с соответствующими кейсами, sheetLink для выделения и сопоставления случаев которые должны отображаться с использованием модального представления.
  
  
  3.3 Реализуем вью флоу-координаторов для каждого экрана
  Наиболее важной частью нашего паттерна флоу-координатора является вью ContentFlowCoordinator. Оно будет обрабатывать всю логику навигации по экрану.
  Сначала я покажу, как может выглядеть такой координатор, а затем объясню некоторые детали:
  



 struct ContentFlowCoordinator<State: ContentFlowStateProtocol, Content: View>: View {

     @ObservedObject var state: State
     let content: () -> Content

     private var activeLink: Binding<ContentLink?> {
         $state.activeLink.map(get: { $0?.navigationLink }, set: { $0 })
     }

     private var sheetItem: Binding<ContentLink?> {
         $state.activeLink.map(get: { $0?.sheetItem }, set: { $0 })
     }

     var body: some View {
         NavigationView {
             ZStack {
                 content()
                     .sheet(item: sheetItem, content: sheetContent)

                 navigationLinks
             }
         }
         .navigationViewStyle(.stack)
     }

     @ViewBuilder private var navigationLinks: some View {
         NavigationLink(tag: .firstLink, selection: activeLink, destination: firstDestination) { EmptyView() }
         NavigationLink(tag: .secondLink, selection: activeLink, destination: secondDestination) { EmptyView() }
         NavigationLink(tag: .thirdLink, selection: activeLink, destination: secondDestination) { EmptyView() }
     }

     private func firstDestination() -> some View {
         var text: String?
         if case let .firstLinkParametrized(param) = state.activeLink {
             text = param
         }

         let viewModel = FirstViewModel(text: text)
         let view = FirstView(viewModel: viewModel)
         return view
     }

     private func secondDestination() -> some View {
         var number: Int?
         if case let .secondLinkParametrized(param) = state.activeLink {
             number = param
         }

         let viewModel = SecondViewModel(number: number)
         let view = SecondView(viewModel: viewModel)
         return view
     }

     private func thirdDestination() -> some View {
         let viewModel = ThirdViewModel()
         let view = ThirdView(viewModel: viewModel)
         return view
     }

     @ViewBuilder private func sheetContent(sheetItem: ContentLink) -> some View {
         switch sheetItem {
         case let .sheetLink(item):
             SheetView(viewModel: SheetViewModel(text: item))
         default:
             EmptyView()
         }
     }
 }


  
  
  Во-первых, его init (здесь неявная) должна иметь параметры, использующие дженерики.
  1. state типа реализующего ContentFlowStateProtocol.
  2. content, которое будет @ViewBuilder экранного вью.
  Во-вторых state должно быть сохранено как @ObservedObject и оно не должно быть @StateObject, поскольку ContentFlowStateProtocol реализуется ContentViewModel, и эта вью-модель уже будет сохранена как @StateObject на экранном ContentView.
  В-третьих, у нас есть вспомогательные биндинги, созданные как вычисляемые свойства, для NavigationLink, т.е. activeLink, и для представления страницы, т.е. sheetItem.
  Вся логика навигации реализована внутри вычисляемого свойства тела ContentFlowCoordinator. Там мы можем наблюдать добавленное NavigationView, встроенное свойство navigationLinks и прикрепленный модификатор sheet(item:…).
  И последнее, но не менее важное: у нас есть фабричные функции (factory functions), которые создают наши вью назначения/контента. Они извлекают возможные параметры навигационного события, создают с их помощью вью-модель и, наконец, с помощью этой вью-модели само вью.
  
  


  
  4. Использование флоу-координатора с вью
  Последний шаг, который остается сделать для завершения экрана ContentView, — собрать все вместе и реализовать это вью. Это то же вью, что и в начале этого туториала, но с добавлением нашего нового ContentFlowCoordinator и расширенного универсального типа вью-модели, требующего реализации ContentFlowStateProtocol.
  
  

 struct ContentView<VM: ContentViewModelProtocol & ContentFlowStateProtocol>: View {

     @StateObject var viewModel: VM

     var body: some View {
         ContentFlowCoordinator(state: viewModel, content: content)
     }

     @ViewBuilder private func content() -> some View {
         ZStack {
             Color.white.ignoresSafeArea()

             VStack {
                 Text(viewModel.text)

                 Button("First view >", action: viewModel.firstAction)
                 Button("Second view >", action: viewModel.secondAction)
                 Button("Third view >", action: viewModel.thirdAction)
                 Button("Sheet view", action: viewModel.sheetAction)
             }
         }
         .navigationBarTitle("Title", displayMode: .inline)
     }
 }

 
 
 */

protocol ContentFlowStateProtocol: ObservableObject {
    var activeLink: ContentLink? { get set }
}

enum ContentLink: Hashable, Identifiable {
    case firstLink
    case firstLinkParametrized(text: String)
    case secondLink
    case secondLinkParametrized(number: Int)
    case thirdLink

    case sheetLink(item: String)

    var navigationLink: ContentLink {
        switch self {
        case .firstLinkParametrized:
            return .firstLink
        case .secondLinkParametrized:
            return .secondLink
        default:
            return self
        }
    }

    var sheetItem: ContentLink? {
        switch self {
        case .sheetLink:
            return self
        default:
            return nil
        }
    }

    var id: String {
        switch self {
        case .firstLink, .firstLinkParametrized:
            return "first"
        case .secondLink, .secondLinkParametrized:
            return "second"
        case .thirdLink:
            return "third"
        case let .sheetLink(item):
            return item
        }
    }
}

struct ContentFlowCoordinator<State: ContentFlowStateProtocol, Content: View>: View {

    @ObservedObject var state: State
    let content: () -> Content

    private var activeLink: Binding<ContentLink?> {
        $state.activeLink.map(get: { $0?.navigationLink }, set: { $0 })
    }

    private var sheetItem: Binding<ContentLink?> {
        $state.activeLink.map(get: { $0?.sheetItem }, set: { $0 })
    }

    var body: some View {
        NavigationView {
            ZStack {
                content()
                    .sheet(item: sheetItem, content: sheetContent)

                navigationLinks
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder private var navigationLinks: some View {
        NavigationLink(tag: .firstLink, selection: activeLink, destination: firstDestination) { EmptyView() }
        NavigationLink(tag: .secondLink, selection: activeLink, destination: secondDestination) { EmptyView() }
        NavigationLink(tag: .thirdLink, selection: activeLink, destination: secondDestination) { EmptyView() }
    }

    private func firstDestination() -> some View {
        var text: String?
        if case let .firstLinkParametrized(param) = state.activeLink {
            text = param
        }

        let viewModel = FirstViewModel(text: text)
        let view = FirstView(viewModel: viewModel)
        return view
    }

    private func secondDestination() -> some View {
        var number: Int?
        if case let .secondLinkParametrized(param) = state.activeLink {
            number = param
        }

        let viewModel = SecondViewModel(number: number)
        let view = SecondView(viewModel: viewModel)
        return view
    }

    private func thirdDestination() -> some View {
        let viewModel = ThirdViewModel()
        let view = ThirdView(viewModel: viewModel)
        return view
    }

    @ViewBuilder private func sheetContent(sheetItem: ContentLink) -> some View {
        switch sheetItem {
        case let .sheetLink(item):
            SheetView(viewModel: SheetViewModel(text: item))
        default:
            EmptyView()
        }
    }
}

extension Binding {
    func map<T>(get: @escaping (Value) -> T?, set: @escaping (T?) -> Value) -> Binding<T?> {
        Binding<T?>(
            get: {
                get(wrappedValue)
            },
            set: {
                wrappedValue = set($0)
            }
        )
    }
}

struct ContentView<VM: ContentViewModelProtocol & ContentFlowStateProtocol>: View {

    @StateObject var viewModel: VM

    var body: some View {
        ContentFlowCoordinator(state: viewModel, content: content)
    }

    @ViewBuilder private func content() -> some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
                Text(viewModel.text)

                Button("First view >", action: viewModel.firstAction)
                Button("Second view >", action: viewModel.secondAction)
                Button("Third view >", action: viewModel.thirdAction)
                Button("Sheet view", action: viewModel.sheetAction)
            }
        }
        .navigationBarTitle("Title", displayMode: .inline)
    }
}


protocol ContentViewModelProtocol: ObservableObject {
    var text: String { get }

    func firstAction()
    func secondAction()
    func thirdAction()
    func sheetAction()
}

final class ContentViewModel: ContentViewModelProtocol, ContentFlowStateProtocol {

    // MARK: - Flow State
    @Published var activeLink: ContentLink?

    // MARK: - View Model

    let text: String = "Content View"

    init() { }

    func firstAction() {
        activeLink = .firstLinkParametrized(text: "Some param")
    }

    func secondAction() {
        activeLink = .secondLinkParametrized(number: 2)
    }

    func thirdAction() {
        activeLink = .thirdLink
    }

    func sheetAction() {
        activeLink = .sheetLink(item: "Sheet param")
    }
}


// First View


protocol FirstFlowStateProtocol: ObservableObject {
    var activeLink: FirstLink? { get set }
}

enum FirstLink: Hashable { }

struct FirstFlowCoordinator<State: FirstFlowStateProtocol, Content: View>: View {

    @ObservedObject var state: State
    let content: () -> Content

    var body: some View {
        content()
    }
}

struct FirstView<VM: FirstViewModelProtocol & FirstFlowStateProtocol>: View {

    @StateObject var viewModel: VM

    var body: some View {
        FirstFlowCoordinator(state: viewModel, content: content)
    }

    @ViewBuilder private func content() -> some View {
        ZStack {
            Color.red.ignoresSafeArea()
            Text(viewModel.text)
        }
    }
}

protocol FirstViewModelProtocol: ObservableObject {
    var text: String { get }
}

final class FirstViewModel: FirstViewModelProtocol, FirstFlowStateProtocol {

    // MARK: - Flow State
    @Published var activeLink: FirstLink?

    // MARK: - View Model

    @Published var text: String

    init(text: String?) {
        if let text = text {
            self.text = "First View with text: \(text)"
        } else {
            self.text = "Default First View"
        }
    }
}


// Second View

protocol SecondFlowStateProtocol: ObservableObject {
    var activeLink: SecondLink? { get set }
}

enum SecondLink: Hashable { }

struct SecondFlowCoordinator<State: SecondFlowStateProtocol, Content: View>: View {

    @ObservedObject var state: State
    let content: () -> Content

    var body: some View {
        content()
    }
}


struct SecondView<VM: SecondViewModelProtocol & SecondFlowStateProtocol>: View {

    @StateObject var viewModel: VM

    var body: some View {
        SecondFlowCoordinator(state: viewModel, content: content)
    }

    @ViewBuilder private func content() -> some View {
        ZStack {
            Color.green.ignoresSafeArea()
            Text(viewModel.text)
        }
    }
}

protocol SecondViewModelProtocol: ObservableObject {
    var text: String { get }
}

final class SecondViewModel: SecondViewModelProtocol, SecondFlowStateProtocol {

    @Published var activeLink: SecondLink?

    @Published var text: String

    init(number: Int?) {
        if let number = number {
            self.text = "Second View with number: \(number)"
        } else {
            self.text = "Default Second View"
        }
    }
}



// Sheet View


protocol SheetFlowStateProtocol: ObservableObject {
    var activeLink: ThirdLink? { get set }
}

enum SheetLink: Hashable { }

struct SheetFlowCoordinator<State: SheetFlowStateProtocol, Content: View>: View {

    @ObservedObject var state: State
    let content: () -> Content

    var body: some View {
        content()
    }
}

struct SheetView<VM: SheetViewModelProtocol & SheetFlowStateProtocol>: View {

    @StateObject var viewModel: VM

    var body: some View {
        SheetFlowCoordinator(state: viewModel, content: content)
    }

    @ViewBuilder private func content() -> some View {
        ZStack {
            Color.yellow.ignoresSafeArea()
            Text(viewModel.text)
        }
    }
}

protocol SheetViewModelProtocol: ObservableObject {
    var text: String { get }
}

final class SheetViewModel: SheetViewModelProtocol, SheetFlowStateProtocol {

    @Published var activeLink: ThirdLink?

    @Published var text: String

    init(text: String) {
        self.text = "Sheet view with \(text)"
    }
}



// Third View


protocol ThridFlowStateProtocol: ObservableObject {
    var activeLink: ThirdLink? { get set }
}

enum ThirdLink: Hashable { }

struct ThirdFlowCoordinator<State: ThridFlowStateProtocol, Content: View>: View {

    @ObservedObject var state: State
    let content: () -> Content

    var body: some View {
        content()
    }
}

struct ThirdView<VM: ThirdViewModelProtocol & ThridFlowStateProtocol>: View {

    @StateObject var viewModel: VM

    var body: some View {
        ThirdFlowCoordinator(state: viewModel, content: content)
    }

    @ViewBuilder private func content() -> some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            Text(viewModel.text)
        }
    }
}



protocol ThirdViewModelProtocol: ObservableObject {
    var text: String { get }
}

final class ThirdViewModel: ThirdViewModelProtocol, ThridFlowStateProtocol {

    @Published var activeLink: ThirdLink?

    let text = "Default Third View"

    init() { }
}
