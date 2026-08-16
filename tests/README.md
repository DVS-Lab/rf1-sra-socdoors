# Tests

`test_workflow.sh` creates a temporary synthetic BIDS events dataset, verifies all four relevant trial types, confirms that a missing `decision-missed` event is legitimate, rejects a negative duration, resolves Linux2-style L1 inputs, asserts exact L1-to-L2 output/input agreement, and checks that a readiness manifest feeds both batch wrappers. It downloads no data and contains no participant values.
