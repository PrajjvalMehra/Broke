import Foundation
import CoreData
import SwiftUI

class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ExpenseModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

extension ExpenseEntity {
    var toExpense: Expense {
        Expense(id: id ?? UUID(), name: name ?? "", amount: amount, date: date ?? Date())
    }
}

struct Expense: Identifiable {
    let id: UUID
    let name: String
    let amount: Double
    let date: Date
}
