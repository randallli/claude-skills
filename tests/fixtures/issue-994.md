# Issue #994: Counter.increment adds one per tap

**Labels:** agent-should-plan

`Counter.increment()` sets the value to 1 instead of adding to it. Each tap
must add 1: after two taps the value is 2, after three it is 3.

## Comments

(none)
