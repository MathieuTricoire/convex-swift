import Convex

// struct or class ?
// struct copy, but what happens for a closure in a struct?
// is it copied too?
// Not happy with this name
struct StateSubscribe {
    let queryToken: QueryToken
    let modification: ClientMessage.ModifyQuerySet?
    let unsubscribe: () -> ClientMessage.ModifyQuerySet?

    init(queryToken: QueryToken, unsubscribe: @escaping () -> ClientMessage.ModifyQuerySet?) {
        self.queryToken = queryToken
        modification = nil
        self.unsubscribe = unsubscribe
    }

    init(queryToken: QueryToken, modification: ClientMessage.ModifyQuerySet, unsubscribe: @escaping () -> ClientMessage.ModifyQuerySet?) {
        self.queryToken = queryToken
        self.modification = modification
        self.unsubscribe = unsubscribe
    }
}

class LocalQuery {
    let id: QueryId
    let token: QueryToken
    //   canonicalizedUdfPath: string;
    //   args: (If used the simple arg object not as an array);
    var numSubscribers: UInt = 1
    var journal: QueryJournal

    init(id: QueryId, token: QueryToken, journal: QueryJournal) {
        self.id = id
        self.token = token
        self.journal = journal
    }

    func addSubscriber() {
        numSubscribers += 1
    }

    func removeSubscriber() {
        if numSubscribers > 0 {
            numSubscribers -= 1
        }
    }
}

struct QueryToken: Equatable, Hashable {
    let path: CanonicalizedUdfPath
    let args: FunctionArgs
}

struct SubscribeResult {
    let modifyQuerySet: ClientMessage.ModifyQuerySet?
    let existingQueryId: QueryId?

    init(modifyQuerySet: ClientMessage.ModifyQuerySet?) {
        self.modifyQuerySet = modifyQuerySet
        existingQueryId = nil
    }

    init(modifyQuerySet: ClientMessage.ModifyQuerySet?, existingQueryId: QueryId) {
        self.modifyQuerySet = modifyQuerySet
        self.existingQueryId = existingQueryId
    }

    init(existingQueryId: QueryId) {
        modifyQuerySet = nil
        self.existingQueryId = existingQueryId
    }
}
@MainActor
class LocalSyncState {
    private var _nextQueryId: QueryId = 0
    private var _currentQuerySetVersion: UInt = 0
    // private var identityVersion: UInt = 0
    // // TODO: rename that queries or activeQueries
    // private var querySet: [QueryToken: LocalQuery] = [:]
    // private var queryIdToToken: [UInt: QueryToken] = [:]

    // Can directly set Publisher + QueryId as value, to not have an intermediate collection Token -> QueryId -> Publisher
    // QueryId is only necessary for Convex.
    var tokenToQueryId: [QueryToken: QueryId] = [:] // How to remove unsubscribed queryTokenToQueryId?
    var queryIdToToken: [QueryId: QueryToken] = [:] // How to remove unsubscribed queryTokenToQueryId?
    // var publishers: [QueryId: QueryPublisher] = [:]
    var subscriberToQueryId: [QuerySubscriber.Id: QueryId] = [:]

    // name this prop `resultHandlers` or `subscriptions` possible to make decoding stuff once?
    var resultHandlers: [QueryId: [QuerySubscriber.Id: QuerySubscriber.ResultHandler]] = [:]

    // return messages to send
    func subscribe(
        subscriber: QuerySubscriber,
        args: FunctionArgs?,
        resultHandler: @escaping QuerySubscriber.ResultHandler
    ) -> SubscribeResult {
        let args = args ?? [:]
        let token = QueryToken(path: subscriber.path, args: args)
        let existingQueryId = tokenToQueryId[token]
        let currentSubscriberQueryId = subscriberToQueryId[subscriber.id]

        switch (existingQueryId, currentSubscriberQueryId) {
        case let (.some(existingQueryId), .some(currentSubscriberQueryId)):
            if existingQueryId == currentSubscriberQueryId {
                // the subscription is actually the same, just update the result handler
                resultHandlers[currentSubscriberQueryId]![subscriber.id] = resultHandler
                return SubscribeResult(existingQueryId: existingQueryId)
            } else {
                let modification = removeSubscription(subscriberId: subscriber.id)
                addSubscription(subscriberId: subscriber.id, queryId: existingQueryId, resultHandler: resultHandler)
                return SubscribeResult(
                    modifyQuerySet: modification.map { modifyQuerySet(modifications: [$0]) },
                    existingQueryId: existingQueryId
                )
            }
        case let (.some(existingQueryId), .none):
            addSubscription(subscriberId: subscriber.id, queryId: existingQueryId, resultHandler: resultHandler)
            return SubscribeResult(existingQueryId: existingQueryId)
        case (.none, .some(_)):
            var modifications: [ClientMessage.ModifyQuerySet.Modification] = []
            if let modification = removeSubscription(subscriberId: subscriber.id) {
                modifications.append(modification)
            }
            modifications.append(newSubscription(subscriber: subscriber, token: token, resultHandler: resultHandler))
            return SubscribeResult(modifyQuerySet: modifyQuerySet(modifications: modifications))
        case (.none, .none):
            let modification = newSubscription(subscriber: subscriber, token: token, resultHandler: resultHandler)
            return SubscribeResult(modifyQuerySet: modifyQuerySet(modifications: [modification]))
        }
    }

    func unsubscribe(subscriberId: QuerySubscriber.Id) -> ClientMessage.ModifyQuerySet? {
        removeSubscription(subscriberId: subscriberId).map {
            let version = nextQuerySetVersion()
            return ClientMessage.ModifyQuerySet(
                baseVersion: version.base,
                newVersion: version.new,
                modifications: [$0]
            )
        }
    }

    func removeSubscription(subscriberId: QuerySubscriber.Id) -> ClientMessage.ModifyQuerySet.Modification? {
        if let queryId = subscriberToQueryId.removeValue(forKey: subscriberId) {
            if var handlers = resultHandlers[queryId] {
                handlers.removeValue(forKey: subscriberId)
                if handlers.isEmpty {
                    if let token = queryIdToToken.removeValue(forKey: queryId) {
                        tokenToQueryId.removeValue(forKey: token)
                    }
                    resultHandlers.removeValue(forKey: queryId)
                    return .remove(ClientMessage.ModifyQuerySet.Modification.Remove(queryId: queryId))
                } else {
                    resultHandlers[queryId] = handlers
                }
            }
        }
        return nil
    }

    func newSubscription(subscriber: QuerySubscriber, token: QueryToken, resultHandler: @escaping QuerySubscriber.ResultHandler) -> ClientMessage.ModifyQuerySet.Modification {
        let queryId = nextQueryId()

        subscriberToQueryId[subscriber.id] = queryId
        tokenToQueryId[token] = queryId
        queryIdToToken[queryId] = token
        resultHandlers[queryId] = [subscriber.id: resultHandler]

        return .add(ClientMessage.ModifyQuerySet.Modification.Add(
            queryId: queryId,
            udfPath: subscriber.path,
            args: subscriber.args,
            journal: nil // TODO:
        ))
    }

    func addSubscription(subscriberId: QuerySubscriber.Id, queryId: QueryId, resultHandler: @escaping QuerySubscriber.ResultHandler) {
        subscriberToQueryId[subscriberId] = queryId
        resultHandlers[queryId]![subscriberId] = resultHandler
    }

    private func modifyQuerySet(modifications: [ClientMessage.ModifyQuerySet.Modification]) -> ClientMessage.ModifyQuerySet {
        if modifications.isEmpty { fatalError("Cannot create a ModifyQuerySet with no modifications") }
        let version = nextQuerySetVersion()
        return ClientMessage.ModifyQuerySet(
            baseVersion: version.base,
            newVersion: version.new,
            modifications: modifications
        )
    }

    private func nextQueryId() -> UInt {
        let id = _nextQueryId
        _nextQueryId += 1
        return id
    }

    private func nextQuerySetVersion() -> (base: UInt, new: UInt) {
        let base = _currentQuerySetVersion
        _currentQuerySetVersion += 1
        let new = _currentQuerySetVersion
        return (base, new)
    }

    // func queryToken(queryId: QueryId) -> QueryToken? {
    //     queryIdToToken[queryId]
    // }
}
