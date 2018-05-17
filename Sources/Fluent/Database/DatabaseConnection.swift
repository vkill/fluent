extension DatabaseConnection {
    /// Create a `QueryBuilder` for the specified `Model` using this connection.
    public func query<M>(_ model: M.Type) -> Query<M.Database>.Builder<M, M>
        where M.Database.Connection == Self
    {
        return M.query(on: eventLoop.newSucceededFuture(result: self))
    }
}

extension DatabaseConnection {
    /// The current pipeline future.
    fileprivate var pipeline: Future<Void> {
        get { return extend.get(\DatabaseConnection.pipeline, default: .done(on: self)) }
        set { extend.set(\DatabaseConnection.pipeline, to: newValue) }
    }

    /// Enqueues a Fluent operation.
    internal func fluentOperation<T>(_ work: @escaping () -> Future<T>) -> Future<T> {
        /// perform this work when the current pipeline future is completed
        let new = pipeline.flatMap(to: T.self) {
            work()
        }

        /// append this work to the pipeline, discarding errors as the pipeline
        /// does not care about them
        pipeline = new.transform(to: ()).catchMap { err in
            return ()
        }

        /// return the newly enqueued work's future result
        return new
    }
}
