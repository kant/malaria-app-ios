import Foundation
import UIKit
import QuartzCore

import Charts

@IBDesignable class PillsStatsViewController : UIViewController {
    
    @IBOutlet weak var adherenceSliderTable: UITableView!
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var graphFrame: UIView!
    @IBOutlet weak var loadingGraphView: CircleProgressView!
    
    @IBInspectable var NoDataText: String = "No entries"
    @IBInspectable var NumberRecentMonths: Int = 4
    @IBInspectable var GraphFillColor: UIColor = UIColor(hex: 0xA1D4E2)
    @IBInspectable var XAxisLineColor: UIColor = UIColor(hex: 0x8A8B8A)
    @IBInspectable var RightYAxisLineColor: UIColor = UIColor(red: 0.894, green: 0.429, blue: 0.442, alpha: 1.0)
    @IBInspectable var LeftYAxisLineColor: UIColor = UIColor(hex: 0x8A8B8A)
    @IBInspectable var AxisFontColor: UIColor = UIColor(hex: 0x705246)
    
    let TextFont = UIFont(name: "AmericanTypewriter", size: 11.0)!
    
    var isPillStatsUpdated: Bool {
        let data = CachedStatistics.sharedInstance
        return data.isMonthlyAdherenceDataUpdated && data.isGraphViewDataUpdated && data.isCalendarViewDataUpdated
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationEvents.ObserveEnteredForeground(self, selector: "refreshScreen")
        
        configureChart()
    }
    
    deinit{
        NSNotificationEvents.UnregisterAll(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshScreen()
    }
    
    func refreshScreen() {
        println("Refreshing screen")
        
        self.graphFrame.bringSubviewToFront(self.chartView)
        
        if !isPillStatsUpdated {
            refreshData()
        }else{
            configureData(CachedStatistics.sharedInstance.adherencesPerDay)
            adherenceSliderTable.reloadData()
        }
    }
    
    func refreshData() {
        graphFrame.bringSubviewToFront(loadingGraphView)
        
        chartView.clear()
        
        let cachedStats = CachedStatistics.sharedInstance
        cachedStats.refreshContext()
        
        cachedStats.setupBeforeCaching()
        
        cachedStats.retrieveTookMedicineStats()
        
        cachedStats.retrieveMonthsData(NumberRecentMonths){
            self.adherenceSliderTable.reloadData()
        }
        
        cachedStats.retrieveCachedStatistics({(progress: Float) in
            self.loadingGraphView!.valueProgress = progress
        }, completition: { _ in
            self.configureData(CachedStatistics.sharedInstance.adherencesPerDay)
            self.graphFrame.bringSubviewToFront(self.chartView)
        })
    }
}

extension PillsStatsViewController: UITableViewDelegate, UITableViewDataSource{

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CachedStatistics.sharedInstance.monthAdhrence.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let data = CachedStatistics.sharedInstance.monthAdhrence[indexPath.row]
        let month = data.0
        let adherenceValue = data.1
        
        let cell = tableView.dequeueReusableCellWithIdentifier("AdherenceHorizontalBarCell") as! AdherenceHorizontalBarCell
        cell.configureCell(month, adhrenceValue: adherenceValue)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let monthView = UIStoryboard.instantiate(viewControllerClass: MonthlyViewController.self)
        monthView.startDay = CachedStatistics.sharedInstance.monthAdhrence[indexPath.row].0
        monthView.callback = refreshScreen
        presentViewController(
            monthView,
            animated: true,
            completion: nil
        )
    }
}

/* Graph View related methods */
extension PillsStatsViewController{
    func configureData(points: [(NSDate, Float)]){
        let xValues = points.map({$0.0.formatWith("yyyy.MM.dd")})
        let values = points.map({$0.1})
        
        var dataEntries: [ChartDataEntry] = []
        for i in 0..<values.count {
            dataEntries.append(ChartDataEntry(value: values[i], xIndex: i))
        }
        
        let adherenceData = configureCharDataSet(dataEntries, label: "")
        let data = LineChartData(xVals: xValues, dataSets: [adherenceData])

        chartView.data = data
    }
    
    func configureChart() {
        configureCharView()
        configureLegend()
        configureXAxis()
        configureLeftYAxis()
        configureRightYAxis()
    }
    
    func configureCharDataSet(dataEntries: [ChartDataEntry], label: String) -> ChartDataSet{
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: label)
        lineChartDataSet.colors = [UIColor.clearColor()]
        lineChartDataSet.drawFilledEnabled = true
        lineChartDataSet.drawCirclesEnabled = false
        lineChartDataSet.drawValuesEnabled = false
        
        lineChartDataSet.fillColor = GraphFillColor
        lineChartDataSet.fillAlpha = 1
        
        return lineChartDataSet
    }
    
    func configureLegend(){
        chartView.legend.enabled = false
    }
    
    
    func configureCharView(){
        chartView.descriptionText = ""
        chartView.noDataText = NoDataText
        
        chartView.scaleYEnabled = false
        chartView.doubleTapToZoomEnabled = false
        
        chartView.drawGridBackgroundEnabled = false
        chartView.highlightEnabled = false
        chartView.highlightIndicatorEnabled = false
    }
    
    func configureXAxis(){
        chartView.xAxis.labelPosition = .Bottom
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.labelTextColor = AxisFontColor
        chartView.xAxis.labelFont = TextFont
        chartView.xAxis.axisLineColor = XAxisLineColor
        chartView.xAxis.axisLineWidth = 1.0
        chartView.xAxis.avoidFirstLastClippingEnabled = true
    }
    
    func configureRightYAxis(){
        chartView.rightAxis.axisLineColor = RightYAxisLineColor
        chartView.rightAxis.drawGridLinesEnabled = false
        chartView.rightAxis.drawLabelsEnabled = false
        chartView.rightAxis.axisLineWidth = 1.0
    }
    
    func configureLeftYAxis(){
        chartView.leftAxis.axisLineColor = LeftYAxisLineColor
        chartView.leftAxis.drawGridLinesEnabled = false
        chartView.leftAxis.axisLineWidth = 1.0
        chartView.leftAxis.customAxisMin = 0
        chartView.leftAxis.customAxisMax = 100
        chartView.leftAxis.labelFont = TextFont
        chartView.leftAxis.labelTextColor = AxisFontColor
        
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = NSNumberFormatterStyle.PercentStyle
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.multiplier = 1
        
        chartView.leftAxis.valueFormatter = numberFormatter
    }
}