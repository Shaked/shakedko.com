# shakedko.com local-runtime context

For rendered blog changes, use the checkout's `make review` target when it is
available and verify the private review succeeds. Return the emitted URL and do not push until the user explicitly approves the push after that successful private review. Never commit machine-specific paths, hostnames, addresses, network topology, or credentials.
