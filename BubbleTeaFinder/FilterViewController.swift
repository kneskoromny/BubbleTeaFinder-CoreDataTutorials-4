/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreData

// протокол определяет метод делегирования, который уведомит делегата, когда пользователь выберет новую комбинацию сортировки/фильтра.
protocol FilterViewControllerDelegate: AnyObject {
  func filterViewController(
    filter: FilterViewController,
    didSelectPredicate predicate: NSPredicate?,
    sortDescriptor: NSSortDescriptor?)
}

class FilterViewController: UITableViewController {
  @IBOutlet weak var firstPriceCategoryLabel: UILabel!
  @IBOutlet weak var secondPriceCategoryLabel: UILabel!
  @IBOutlet weak var thirdPriceCategoryLabel: UILabel!
  @IBOutlet weak var numDealsLabel: UILabel!

  // MARK: - Price section
  @IBOutlet weak var cheapVenueCell: UITableViewCell!
  @IBOutlet weak var moderateVenueCell: UITableViewCell!
  @IBOutlet weak var expensiveVenueCell: UITableViewCell!
  
  // MARK: - Properties
  var coreDataStack: CoreDataStack!
  // содержит ссылку на делегат
  weak var delegate: FilterViewControllerDelegate?
  // ссылка на дескриптор
  var selectedSortDescriptor: NSSortDescriptor?
  // ссылка на предикат
  var selectedPredicate: NSPredicate?
  
  // предикаты для ключа ценовой категории
  lazy var cheapVenuePredicate: NSPredicate = {
    return NSPredicate(format: "%K == %@",
      #keyPath(Venue.priceInfo.priceCategory), "$")
  }()
  lazy var moderateVenuePredicate: NSPredicate = {
    return NSPredicate(format: "%K == %@",
      #keyPath(Venue.priceInfo.priceCategory), "$$")
  }()
  lazy var expensiveVenuePredicate: NSPredicate = {
    return NSPredicate(format: "%K == %@",
      #keyPath(Venue.priceInfo.priceCategory), "$$$")
  }()
  // предикат для показа мест с одной и более продажами
  lazy var offeringDealPredicate: NSPredicate = {
    return NSPredicate(format: "%K > 0",
      #keyPath(Venue.specialCount))
  }()
  // предикат для показа мест с дистанцией 500 и менее метров
  lazy var walkingDistancePredicate: NSPredicate = {
    return NSPredicate(format: "%K < 500",
      #keyPath(Venue.location.distance))
  }()
  // предикат для мест с одним и более отзывом
  lazy var hasUserTipsPredicate: NSPredicate = {
    return NSPredicate(format: "%K > 0",
      #keyPath(Venue.stats.tipCount))
  }()

  // MARK: - Most popular section
  @IBOutlet weak var offeringDealCell: UITableViewCell!
  @IBOutlet weak var walkingDistanceCell: UITableViewCell!
  @IBOutlet weak var userTipsCell: UITableViewCell!

  // MARK: - Sort section
  @IBOutlet weak var nameAZSortCell: UITableViewCell!
  @IBOutlet weak var nameZASortCell: UITableViewCell!
  @IBOutlet weak var distanceSortCell: UITableViewCell!
  @IBOutlet weak var priceSortCell: UITableViewCell!

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // использует fetchRequest для запроса количества объектов
    populateCheapVenueCountLabel()
    populateModerateVenueCountLabel()
    populateExpensiveVenueCountLabel()
    populateDealsCountLabel()
  }
}

// MARK: - IBActions
extension FilterViewController {
  @IBAction func search(_ sender: UIBarButtonItem) {
    delegate?.filterViewController(
      filter: self,
      didSelectPredicate: selectedPredicate,
      sortDescriptor: selectedSortDescriptor
    )
    dismiss(animated: true)
  }
}

// MARK: - UITableViewDelegate
extension FilterViewController {
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) else {
      return
  }
    
    switch cell {
    // Price section
    // при нажатии на конкретную ячейку задаем соотв значение selectedPredicate
    case cheapVenueCell:
      selectedPredicate = cheapVenuePredicate
    case moderateVenueCell:
      selectedPredicate = moderateVenuePredicate
    case expensiveVenueCell:
      selectedPredicate = expensiveVenuePredicate
      
    // Most Popular section
     case offeringDealCell:
       selectedPredicate = offeringDealPredicate
     case walkingDistanceCell:
       selectedPredicate = walkingDistancePredicate
     case userTipsCell:
       selectedPredicate = hasUserTipsPredicate
     default: break
     
    }
    cell.accessoryType = .checkmark
  }
}
// MARK: - Helper methods
extension FilterViewController {
  func populateCheapVenueCountLabel() {
    let fetchRequest =
      // тк необходим countResultType тип запроса должен быть NSNumber
      NSFetchRequest<NSNumber>(entityName: "Venue")
    fetchRequest.resultType = .countResultType
    fetchRequest.predicate = cheapVenuePredicate
    do {
      // в массиве NSNumber содержится единственное число - кол-во объектов согласно запросу
      let countResult =
        try coreDataStack.managedContext.fetch(fetchRequest)
      // получаем это число
      let count = countResult.first?.intValue ?? 0
      // крутая запись, получаем стринг в заисимости от значения count
      let pluralized = count == 1 ? "place" : "places"
      firstPriceCategoryLabel.text =
        "\(count) bubble tea \(pluralized)"
    } catch let error as NSError {
      print("count not fetched \(error), \(error.userInfo)")
    }
  }
  func populateModerateVenueCountLabel() {
    let fetchRequest =
      NSFetchRequest<NSNumber>(entityName: "Venue")
    fetchRequest.resultType = .countResultType
    fetchRequest.predicate = moderateVenuePredicate
    do {
      let countResult =
        try coreDataStack.managedContext.fetch(fetchRequest)
      let count = countResult.first?.intValue ?? 0
      let pluralized = count == 1 ? "place" : "places"
      secondPriceCategoryLabel.text =
        "\(count) bubble tea \(pluralized)"
    } catch let error as NSError {
      print("count not fetched \(error), \(error.userInfo)")
    }
  }
  // способ сделать проще, без указания типа запроса
  func populateExpensiveVenueCountLabel() {
    let fetchRequest: NSFetchRequest<Venue> = Venue.fetchRequest()
    fetchRequest.predicate = expensiveVenuePredicate
    do {
      // возвращаемое значение count - Int, можно сразу подставить в лейбл
      let count =
        try coreDataStack.managedContext.count(for: fetchRequest)
      let pluralized = count == 1 ? "place" : "places"
      thirdPriceCategoryLabel.text =
        "\(count) bubble tea \(pluralized)"
    } catch let error as NSError {
      print("count not fetched \(error), \(error.userInfo)")
    }
  }
  // считает сумму атрибутов Venue.specialCount для всех экземпляров, не создавая массив и не проходя по нему циклом
  func populateDealsCountLabel() {
  // запрос загрузки по имени сущности с возвращаемым типом данных - массив NSDictionary
    let fetchRequest =
      NSFetchRequest<NSDictionary>(entityName: "Venue")
    // указываем тип результата
    fetchRequest.resultType = .dictionaryResultType
  // создаем экземпляр NSExpressionDescription для запроса суммы
    let sumExpressionDesc = NSExpressionDescription()
    // даем имя, чтобы можно было прочитать его результат из словаря результатов
    sumExpressionDesc.name = "sumDeals"
  // создаем аргумент для подсчета по ключу Venue.specialCount
    let specialCountExp =
      NSExpression(forKeyPath: #keyPath(Venue.specialCount))
    // указываем тип выражения - сумма, какой аргумент считать - specialCountExp
    sumExpressionDesc.expression =
      NSExpression(forFunction: "sum:",
                   arguments: [specialCountExp])
    // задаем тип возвращаемого значения - Int32
    sumExpressionDesc.expressionResultType =
      .integer32AttributeType
  // в свойство начального запроса ставим созданный запрос суммы
    fetchRequest.propertiesToFetch = [sumExpressionDesc]
  // выполняем запрос
    do {
      let results =
        try coreDataStack.managedContext.fetch(fetchRequest)
      // возвращаемое значение массив, получаем первый элемент из него
      let resultDict = results.first
      // вытаскиваем значение из словаря по ключу и кастим до Int
      let numDeals = resultDict?["sumDeals"] as? Int ?? 0
      // меняем окончания в зависимости от числа сделок
      let pluralized = numDeals == 1 ?  "deal" : "deals"
      numDealsLabel.text = "\(numDeals) \(pluralized)"
    } catch let error as NSError {
      print("count not fetched \(error), \(error.userInfo)")
    }
  }
}

