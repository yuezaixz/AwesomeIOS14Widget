//
//  AwesomeIOS14WidgetExtension.swift
//  AwesomeIOS14WidgetExtension
//
//  Created by 吴迪玮 on 2020/6/24.
//

import WidgetKit
import SwiftUI

struct PlaceholderView : View {
    var body: some View {
        Text("加载中...")
    }
}

@main
struct AwesomeIOS14WidgetExtension: Widget {
    private let kind: String = "AwesomeIOS14WidgetExtension"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CommitTimeline(), placeholder: PlaceholderView()) { entry in
            CommitCheckerWidgetView(entry: entry)
        }
        .configurationDisplayName("Swift's Latest Commit")
        .description("Shows the last commit at the Swift repo.")
    }
}

struct Commit {
    let message: String
    let author: String
    let date: String
}
struct CommitLoader {
    static func fetch(completion: @escaping (Result<Commit, Error>) -> Void) {
        let branchContentsURL = URL(string: "https://api.github.com/repos/yuezaixz/DGeneration/branches/master")!
        let task = URLSession.shared.dataTask(with: branchContentsURL) { (data, response, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            let commit = getCommitInfo(fromData: data!)
            completion(.success(commit))
        }
        task.resume()
    }
    static func getCommitInfo(fromData data: Foundation.Data) -> Commit {
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let commitParentJson = json["commit"] as! [String: Any]
        let commitJson = commitParentJson["commit"] as! [String: Any]
        let authorJson = commitJson["author"] as! [String: Any]
        let message = commitJson["message"] as! String
        let author = authorJson["name"] as! String
        let date = authorJson["date"] as! String
        return Commit(message: message, author: author, date: date)
    }
}

struct LastCommitEntry: TimelineEntry {
    public let date: Date
    public let commit: Commit
}

struct CommitTimeline: TimelineProvider {
    
    typealias Entry = LastCommitEntry
    
    public func snapshot(with context: Context, completion: @escaping (LastCommitEntry) -> ()) {
        // mock数据
        let fakeCommit = Commit(message: "Fixed stuff", author: "David Woo", date: "2020-06-23")
        let entry = LastCommitEntry(date: Date(), commit: fakeCommit)
        completion(entry)
    }
    
    public func timeline(with context: Context, completion: @escaping (Timeline<LastCommitEntry>) -> ()) {
        let currentDate = Date()
        // 15秒访问一次
        let refreshDate = Calendar.current.date(byAdding: .second, value: 15, to: currentDate)!
        CommitLoader.fetch { result in
            let commit: Commit
            if case .success(let fetchedCommit) = result {
                commit = fetchedCommit
            } else {
                commit = Commit(message: "加载失败", author: "", date: "")
            }
            let entry = LastCommitEntry(date: currentDate, commit: commit)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct LastCommit: TimelineEntry {
    public let date: Date
    public let commit: Commit
    var relevance: TimelineEntryRelevance? {
        return TimelineEntryRelevance(score: 10) // 0 - not important | 100 - very important
    }
}

struct CommitCheckerWidgetView : View {
    let entry: LastCommitEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DGeneration的最新提交")
                .font(.system(.title3))
                .foregroundColor(.black)
            Text(entry.commit.message)
                .font(.system(.callout))
                .foregroundColor(.black)
                .bold()
            Text("\(entry.commit.author) 修改于 \(entry.commit.date)")
                .font(.system(.caption))
                .foregroundColor(.black)
            Text("根据与 \(Self.format(date:entry.date))")
                .font(.system(.caption2))
                .foregroundColor(.black)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [.orange, .yellow]), startPoint: .top, endPoint: .bottom))
    }
    static func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm"
        return formatter.string(from: date)
    }
}
