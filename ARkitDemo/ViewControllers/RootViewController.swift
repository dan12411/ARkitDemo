//
//  RootViewController.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/12.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    
    var dataSource: Array<Array<String>>!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "ARkit Demo"
        
        let featuresTableView: UITableView = UITableView(frame: self.view.frame)
        featuresTableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        featuresTableView.delegate = self
        featuresTableView.dataSource = self
        self.view.addSubview(featuresTableView)
        
        dataSource = [["Record Video"]]
        
    }
}

// MARK: UITableViewDatasource

extension RootViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40;
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle: String?
        switch section {
        case 0:
            sectionTitle = "ARKit"
        default:
            sectionTitle = ""
        }
        
        return sectionTitle
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String? = "cellIdentifier"
        var cell:UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier!)
        if cell == nil
        {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
        }
        
        cell!.selectionStyle = UITableViewCellSelectionStyle.none
        cell!.textLabel!.text = dataSource[indexPath.section][indexPath.row]
        
        return cell!
    }
}

// MARK: UITableViewDelegate

extension RootViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            let recordVC = UIStoryboard.main().instantiateViewController(withIdentifier:"RecordVideoViewController") as! RecordVideoViewController
            self.navigationController?.pushViewController(recordVC, animated: true)
        default:
            break
        }
    }
}
