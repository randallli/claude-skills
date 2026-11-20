# Issue #993: Persist the counter across restarts

**Labels:** agent-should-plan

The counter resets to 0 on every app restart. It must keep its value.

Introduce a `CounterStore` abstraction with two implementations: an in-memory
one for tests and a `shared_preferences`-backed one for the app. `Counter`
loads its value from the store on creation and saves after every
`increment()`. The counter screen must show the restored value after a
restart.

## Comments

(none)
