pub contract WebaverseAccount {

    pub resource interface WebaverseAccountStatePublic {
        pub var keyValueMap: {String: String}
    }

    pub resource State : WebaverseAccountStatePublic {

        pub var keyValueMap: {String: String}

        init() {
            self.keyValueMap = {}
        }
    }

    pub fun createState() : @State {
        return <-create State()
    }

    init() {
    }
}
