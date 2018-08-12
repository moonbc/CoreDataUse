//
//  ListVC.swift
//  CoreDataUse
//
//  Created by 402-07 on 2018. 8. 11..
//  Copyright © 2018년 moonbc. All rights reserved.
//

import UIKit
import CoreData

class ListVC: UITableViewController {
    //네비게이션 바의 오른쪽 바 버튼 아이템을 클릭하면 호출될 메소드(selector)
    
    
    //Object 1개를 받아서 core data에서 삭제하는 메소드
    
    
    @objc func delete(object: NSManagedObject) ->Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        //데이터 삭제
        context.delete(object)
        
        //예외처리를 할 때 try! 를 이용하면 catch가 없어도 됩니다.
        do {
            //예외가 발생할 가능성이 있는 코드
            //저장소에 현재까지 작업 내용 반영 - commit
            try context.save()
            return true
        }
        catch {
            //예외가 발생했을 때 수행될 코드
            //현재까지 작업 내용 취소 - rollback
            context.rollback()
            return false
        }
    }
    
    @objc func add(_ sender: Any) {
        
        let alert = UIAlertController(title: "게시글", message: nil, preferredStyle: .alert)
        
        alert.addTextField(){$0.placeholder="제목"}
        alert.addTextField(){$0.placeholder="내용"}
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default){
            (_) in
            guard let title = alert.textFields?.first?.text, let content = alert.textFields?.last?.text
                else {
                    return
            }
            self.save(title: title, content: content)
            self.tableView.reloadData()
        })
        
        
        self.present(alert, animated: true)
    }
    
    
    

    //읽어온 데이터를 저장할 변수
    lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    
    //title과 contents를 매개변수로 받아서 저장하는 메소드
    
    func save(title:String, content:String) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //새로 추가할 데이터 만들기
        let board = NSEntityDescription.insertNewObject(forEntityName: "Board", into: context)
        board.setValue(title, forKey: "title")
        board.setValue(content, forKey: "content")
        board.setValue(Date(), forKey: "regdate")
        
        
        let logObject = NSEntityDescription.insertNewObject(forEntityName: "Log", into: context) as! LogMO
        logObject.regdate = Date()
        logObject.type = LogType.create.rawValue
        
        (board as! BoardMO).addToLogs(logObject)
        
        
        //coreData 삽입
        try! context.save()
//        self.list.append(board)
        
        self.list.insert(board, at: 0)
        return true
        
    }
    
    
    //Board Entity의 모든 데이터를 가져오는 메소드
    
    func fetch() -> [NSManagedObject] {
        //AppDelegate에 대한 포인터 만들기
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        //CoreData의 DAO 역할을 수행하는 ViewContext 포인터 가져오기
        let context = appDelegate.persistentContainer.viewContext
        //데이터를 가져올 query만들기
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Board")
        //데이터 가져오기
        let result = try! context.fetch(fetchRequest)
        return result
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
	
        //바 버튼 아이템을 코드로 생성
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(_:)))

        self.navigationItem.rightBarButtonItem = addBtn
        
        self.title = "게시판"

        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    //테이블 뷰의 섹션 개수를 설정하는 메소드
    //이 메소드는 선택적으로 구현하면 됩니다.
    //구현을 하지 않으면 1을 return 합니다.
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    //테이블 뷰의 필수 메소드
    //섹션 별 행의 개수를 설정하는 메소드
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.list.count
    }

    //셀의 모양을 결정하는 메소드
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Configure the cell...
        let record = self.list[indexPath.row]
        
        let title = record.value(forKey: "title") as? String
        let contents = record.value(forKey: "content") as? String
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = contents

        return cell
    }
    
    

    //편집 버튼의 모양을 설정하는 메소드
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return .delete
    }
    
    //편집 버튼을 누르고 나오는 버튼을 눌렀을 때 호출되는 메소드
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        //행 번호에 해당하는 데이터 찾아오기
        let object = self.list[indexPath.row]
        
        //데이터 삭제
        self.delete(object: object)
        
        self.list.remove(at: indexPath.row)
        self.tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        //행번호에 해당하는 데이터 가져오기
        let object = self.list[indexPath.row]
        
        //하위 뷰 컨트롤러 만들기
        let uvc = self.storyboard?.instantiateViewController(withIdentifier: "LogVC") as! LogVC
        uvc.board = object as! BoardMO
        
        self.navigationController?.pushViewController(uvc, animated: true)
        
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
