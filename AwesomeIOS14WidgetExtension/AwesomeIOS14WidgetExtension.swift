//
//  AwesomeIOS14WidgetExtension.swift
//  AwesomeIOS14WidgetExtension
//
//  Created by 吴迪玮 on 2020/6/24.
//

import WidgetKit
import SwiftUI
import Intents

// intentdefinition 自动生成了
//@available(iOS 12.0, macOS 10.16, watchOS 5.0, *) @available(tvOS, unavailable)
//@objc(LastCommitIntent)
//public class LastCommitIntent: INIntent {
//    @NSManaged public var account: String?
//    @NSManaged public var repo: String?
//    @NSManaged public var branch: String?
//}

struct PlaceholderView : View {
    var body: some View {
        Text("加载中...")
    }
}

@main
struct AwesomeIOS14WidgetExtension: Widget {
    private let kind: String = "AwesomeIOS14WidgetExtension"

    public var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: LastCommitIntent.self, provider: CommitTimeline(), placeholder: PlaceholderView()) { entry in
            RepoBranchCheckerEntryView(entry: entry)
        }
        .configurationDisplayName("DGeneration的最新提交")
        .description("展示DGeneration开源库的最新提交")
    }
}

struct Commit {
    let message: String
    let author: String
    let date: String
}
struct CommitLoader {
    static func fetch(account: String, repo: String, branch: String, completion: @escaping (Result<Commit, Error>) -> Void) {
        completion(.success(Commit(message: "fake result", author: "Faker", date: "2020-06-24")))
//        let branchContentsURL = URL(string: "https://api.github.com/repos/\(account)/\(repo)/branches/\(branch)")!
//        let task = URLSession.shared.dataTask(with: branchContentsURL) { (data, response, error) in
//            guard error == nil else {
//                completion(.failure(error!))
//                return
//            }
//            let commit = getCommitInfo(fromData: data!)
//            completion(.success(commit))
//        }
//        task.resume()
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

struct CommitTimeline: IntentTimelineProvider {
    typealias Intent = LastCommitIntent
    typealias Entry = LastCommit
    public func snapshot(for configuration: LastCommitIntent, with context: Context, completion: @escaping (LastCommit) -> ()) {
        let fakeCommit = Commit(message: "Fixed stuff", author: "David Woo", date: "2020-06-23")
        let entry = LastCommit(
            date: Date(),
            commit: fakeCommit,
            branch: RepoBranch(
                account: "yuezaixz",
                repo: "DGeneration",
                branch: "master"
            )
        )
        completion(entry)
    }
    public func timeline(for configuration: LastCommitIntent, with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        guard let account = configuration.account,
              let repo = configuration.repo,
              let branch = configuration.branch
        else {
            let commit = Commit(message: "加载失败", author: "", date: "")
            let entry = LastCommit(date: currentDate, commit: commit, branch: RepoBranch(
                account: "--",
                repo: "--",
                branch: "--"
            ))
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
            return
        }
        CommitLoader.fetch(account: account, repo: repo, branch: branch) { result in
            let commit: Commit
            if case .success(let fetchedCommit) = result {
                commit = fetchedCommit
            } else {
                commit = Commit(message: "加载失败", author: "", date: "")
            }
            let entry = LastCommit(date: currentDate, commit: commit, branch: RepoBranch(
                account: account,
                repo: repo,
                branch: branch
            ))
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct RepoBranch {
    let account: String
    let repo: String
    let branch: String
}
struct LastCommit: TimelineEntry {
    public let date: Date
    public let commit: Commit
    public let branch: RepoBranch
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

struct RepoBranchCheckerEntryView : View {
    var entry: CommitTimeline.Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(entry.branch.account)/\(entry.branch.repo)'s \(entry.branch.branch) Latest Commit")
                .font(.system(.title3))
                .foregroundColor(.black)
            Text("\(entry.commit.message)")
                .font(.system(.callout))
                .foregroundColor(.black)
                .bold()
            Text("by \(entry.commit.author) at \(entry.commit.date)")
                .font(.system(.caption))
                .foregroundColor(.black)
            Text("Updated at \(Self.format(date:entry.date))")
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
