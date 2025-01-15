.PHONY: record_snapshots
record_snapshots:
	bazel test //Tests/... \
		--config=record_snapshots \
		--test_env=BUILD_WORKSPACE_DIRECTORY=$$(pwd) \
		--test_env=SNAPSHOT_DIRECTORY="$$(pwd)/Tests/SignHereLibraryTests" \
		--test_env=RERECORD_SNAPSHOTS=TRUE
