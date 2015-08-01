import XCTest
import malaria_ios

class TestTimedInsertions: XCTestCase {
    var m: MedicineManager!
    
    let d1 = NSDate.from(2015, month: 6, day: 6) + NSCalendar.currentCalendar().firstWeekday.day //start of the week
    let weeklyPill = Medicine.Pill.Mefloquine
    let dailyPill = Medicine.Pill.Malarone
    
    var daily: Medicine!
    var weekly: Medicine!
    
    var dailyRegistriesManager: RegistriesManager!
    var weeklyRegistriesManager: RegistriesManager!
    
    var currentContext: NSManagedObjectContext!
    
    
    override func setUp() {
        super.setUp()

        currentContext = CoreDataHelper.sharedInstance.createBackgroundContext()
        m = MedicineManager(context: currentContext)
        
        m.registerNewMedicine(weeklyPill)
        m.registerNewMedicine(dailyPill)
        
        if let m1 = m.getMedicine(dailyPill),
           let m2 = m.getMedicine(weeklyPill){
            daily = m1
            weekly = m2
        }else{
            XCTFail("Fail initializing:")
        }
        
        dailyRegistriesManager = daily.registriesManager(currentContext)        
        weeklyRegistriesManager = weekly.registriesManager(currentContext)
        
        
    }
    
    override func tearDown() {
        super.tearDown()
        m.clearCoreData()
        UserSettingsManager.clear()
    }

    func testDailyInsert(){
        
        XCTAssertTrue(dailyRegistriesManager.addRegistry(d1, tookMedicine: false))
        //modify entry with same value, should return true
        XCTAssertTrue(dailyRegistriesManager.addRegistry(d1, tookMedicine: false))

        //modify entry with different value
        XCTAssertFalse(dailyRegistriesManager.addRegistry(d1, tookMedicine: true))
        
        XCTAssertEqual(1, dailyRegistriesManager.getRegistries().count)
        
        
        XCTAssertTrue(dailyRegistriesManager.addRegistry(d1 - 1.day, tookMedicine: false))
        XCTAssertTrue(dailyRegistriesManager.addRegistry(d1 + 1.day, tookMedicine: false))
        
        XCTAssertEqual(3, dailyRegistriesManager.getRegistries().count)
        
    }
    
    func testWeeklyInsert(){
        XCTAssertTrue(weeklyRegistriesManager.addRegistry(d1, tookMedicine: false))
        XCTAssertTrue(weeklyRegistriesManager.addRegistry(d1 + 1.day, tookMedicine: true))
        
        XCTAssertFalse(weeklyRegistriesManager.addRegistry(d1 + 2.day, tookMedicine: true))
        XCTAssertFalse(weeklyRegistriesManager.addRegistry(d1 + 3.day, tookMedicine: true))
        XCTAssertFalse(weeklyRegistriesManager.addRegistry(d1 + 4.day, tookMedicine: true))
        XCTAssertFalse(weeklyRegistriesManager.addRegistry(d1 + 5.day, tookMedicine: true))
        XCTAssertFalse(weeklyRegistriesManager.addRegistry(d1 + 6.day, tookMedicine: true))
        
        XCTAssertEqual(2, weeklyRegistriesManager.getRegistries().count)
        XCTAssertTrue(weeklyRegistriesManager.addRegistry(d1 + 1.week, tookMedicine: true))
        XCTAssertEqual(3, weeklyRegistriesManager.getRegistries().count)
    }
    
    func testDailyModifyPastEntry(){
        XCTAssertTrue(weeklyRegistriesManager.addRegistry(d1, tookMedicine: false))
        XCTAssertTrue(weeklyRegistriesManager.addRegistry(d1, tookMedicine: true, modifyEntry: true))
        XCTAssertEqual(1, weeklyRegistriesManager.getRegistries().count)
        XCTAssertTrue(weeklyRegistriesManager.getRegistries()[0].tookMedicine)
    }
    
    func testDifferentTimes(){
        XCTAssertTrue(dailyRegistriesManager.addRegistry(d1, tookMedicine: false))
        let b = d1 + 1.minute
        XCTAssertEqual(1, dailyRegistriesManager.getRegistries(date1: b, date2: b).count)
    }
}
