//
//  DiaryDataManager.swift
//  Diary
//
//  Created by zhowkevin on 15/10/5.
//  Copyright © 2015年 kevinzhow. All rights reserved.
//

import UIKit
import CoreData

extension MainViewController: UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    
    func moveToThisMonth() {
        
        let currentMonth = NSCalendar.currentCalendar().component(NSCalendarUnit.Month, fromDate: NSDate())
        
        if (diarys.count > 0){
            let diary = diarys.last as! Diary
            
            let dvc = self.storyboard?.instantiateViewControllerWithIdentifier("MainViewController") as! MainViewController
            
            if (currentMonth >  diary.month.integerValue) {
                
                //Move To Year Beacuse Lack of currentMonth Diary
                
                dvc.interfaceType = .Year
                dvc.year = diary.year.integerValue
                
            }else{
                
                dvc.interfaceType = .Month
                dvc.year = diary.year.integerValue
                dvc.month = diary.month.integerValue
            }
            
            self.navigationController!.pushViewController(dvc, animated: true)
        }else{
            
            let dvc = self.storyboard?.instantiateViewControllerWithIdentifier("MainViewController") as! MainViewController
            
            let filePath = NSBundle.mainBundle().pathForResource("poem", ofType: "json")
            let JSONData = try? NSData(contentsOfFile: filePath!, options: NSDataReadingOptions.MappedRead)
            let jsonObject = (try! NSJSONSerialization.JSONObjectWithData(JSONData!, options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
            var poemsCollection = jsonObject.valueForKey("poems") as! [String: AnyObject]
            
            let poems = currentLanguage == "ja" ?  (poemsCollection["ja"] as! NSArray) : ( poemsCollection["cn"] as! NSArray)
            if let managedContext = DiaryCoreData.sharedInstance.managedContext {
                for poem in poems{
                    
                    let poem =  poem as! NSDictionary
                    let entity =  NSEntityDescription.entityForName("Diary", inManagedObjectContext: managedContext)
                    let diaryID = poem.valueForKey("id") as! String
                    
                    if let _ = fetchDiaryByID(diaryID) {
                        return
                    }
                    
                    let newdiary = Diary(entity: entity!,
                        insertIntoManagedObjectContext:managedContext)
                    
                    newdiary.id = diaryID
                    newdiary.content = poem.valueForKey("content") as! String
                    newdiary.title = poem.valueForKey("title") as? String
                    newdiary.location = poem.valueForKey("location") as? String
                    
                    newdiary.updateTimeWithDate(NSDate())
                    
                    dvc.interfaceType = .Month
                    dvc.month = newdiary.month.integerValue
                    dvc.year = newdiary.year.integerValue
                    
                }
                
                do {
                    try managedContext.save()
                    
                    self.navigationController!.pushViewController(dvc, animated: true)
                } catch let error as NSError {
                    debugPrint("Could not save \(error), \(error.userInfo)")
                }
            }
        }
        
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let interfaceType = interfaceType {
            switch interfaceType {
            case .Home:
                return yearsCount
            case .Year:
                if fetchedResultsController.sections!.count == 0 {
                    return 1
                }else{
                    return fetchedResultsController.sections!.count
                }
            case .Month:
                return diarys.count
            }
        } else {
            return 0
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if let interfaceType = interfaceType {
            switch interfaceType {
            case .Home:
                
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(DiaryCollectionViewCellIdentifier, forIndexPath: indexPath) as! DiaryAutoLayoutCollectionViewCell
                
                let components = NSCalendar.currentCalendar().component(NSCalendarUnit.Year, fromDate: NSDate())
                var year = components
                
                if let sectionInfo = fetchedResultsController.sections?[safe: indexPath.row] {
                    debugPrint("Section info \(sectionInfo.name)")
                    year = Int(sectionInfo.name)!
                }
                
                cell.textInt = year
                
                cell.isYear = true
                
                cell.labelText = "\(numberToChinese(cell.textInt)) 年"
                
                cell.selectCell = { [weak self] in
                    
                    if let strongSelf = self {
                        let dvc = strongSelf.storyboard?.instantiateViewControllerWithIdentifier("MainViewController") as! MainViewController
                        
                        dvc.interfaceType = .Year
                        
                        let components = NSCalendar.currentCalendar().component(NSCalendarUnit.Year, fromDate: NSDate())
                        
                        var year = components
                        
                        if let sectionInfo = strongSelf.fetchedResultsController.sections?[safe: indexPath.row], tempYear = Int(sectionInfo.name) {
                            year = tempYear
                        }
                        
                        dvc.year = year
                        
                        strongSelf.navigationController!.pushViewController(dvc, animated: true)
                    }

                }
                
                // Configure the cell
                
                return cell
                
            case .Year:
                
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(DiaryCollectionViewCellIdentifier, forIndexPath: indexPath) as! DiaryAutoLayoutCollectionViewCell
                    
                if let sectionInfo = fetchedResultsController.sections?[safe: indexPath.row] {
                    let month = Int(sectionInfo.name)
                    cell.labelText = "\(numberToChineseWithUnit(month!)) 月"
                } else {
                    cell.labelText = "\(numberToChineseWithUnit(NSCalendar.currentCalendar().component(NSCalendarUnit.Month, fromDate: NSDate()))) 月"
                }

                cell.selectCell = { [weak self] in
                    if let strongSelf = self {
                        let dvc = strongSelf.storyboard?.instantiateViewControllerWithIdentifier("MainViewController") as! MainViewController
                        dvc.interfaceType = .Month
                        
                        if let sectionInfo = strongSelf.fetchedResultsController.sections?[safe: indexPath.row], month = Int(sectionInfo.name) {
                            dvc.month = month
                        } else {
                            dvc.month = NSCalendar.currentCalendar().component(NSCalendarUnit.Month, fromDate: NSDate())
                        }
                        
                        dvc.year = strongSelf.year
                        strongSelf.navigationController!.pushViewController(dvc, animated: true)
                    }

                }
                
                return cell
                
            case .Month:
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(DiaryCollectionViewCellIdentifier, forIndexPath: indexPath) as! DiaryAutoLayoutCollectionViewCell
                
                if let diary = fetchedResultsController.objectAtIndexPath(indexPath) as? Diary {
                    
                    if let title = diary.title {
                        cell.labelText = title
                    }else{
                        cell.labelText = "\(numberToChineseWithUnit(NSCalendar.currentCalendar().component(NSCalendarUnit.Day, fromDate: diary.created_at))) 日"
                    }
                    
                    cell.selectCell = { [weak self] in
                        if let strongSelf = self {
                            let dvc = strongSelf.storyboard?.instantiateViewControllerWithIdentifier("DiaryViewController") as! DiaryViewController
                            dvc.diary = diary
                            strongSelf.navigationController!.pushViewController(dvc, animated: true)
                        }
                    }
                }
                
                return cell
            }
        } else {
            
            return UICollectionViewCell()
            
        }
        
    }
    
    func calInsets(portrait: Bool, forSize size: CGSize) -> UIEdgeInsets {
        
        let insetLeft = (size.width - collectionViewWidth)/2.0
        
        var numberOfCells:Int = fetchedResultsController.sections!.count > 0 ? fetchedResultsController.sections!.count : 1
        
        if interfaceType == .Month {
            numberOfCells = self.diarys.count
        }
        
        var edgeInsets: CGFloat = 0
        
        if (numberOfCells >= collectionViewDisplayedCells) {
            
            edgeInsets = insetLeft
            
        } else {
            edgeInsets = insetLeft + (collectionViewWidth - (CGFloat(numberOfCells)*itemWidth))/2.0
        }
        
        debugPrint(edgeInsets)
        
        return UIEdgeInsetsMake(0, edgeInsets, 0, edgeInsets)
    }
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        self.refetch()
        
        self.collectionView.reloadData()
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        self.resetCollectionView()
    }
    
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        debugPrint(size)
        
        if portrait {
            self.collectionView.contentInset = calInsets(true, forSize: size)
        }else {
            self.collectionView.contentInset = calInsets(false, forSize: size)
        }
        
        if size.height < 480 {
            self.subLabelCenter.constant = 50
        } else {
            self.subLabelCenter.constant = -15
        }
        
        self.collectionView.contentOffset = CGPoint(x: -collectionView.contentInset.left, y: 0)
        
        if let layout = self.collectionView.collectionViewLayout as? DiaryLayout {
            layout.collectionViewLeftInsetsForLayout = self.collectionView.contentInset.left
        }
        
        DiaryNavTransactionAnimator.animator.newSize = size
        
        view.layoutIfNeeded()
        
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
    
}