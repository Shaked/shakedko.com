# Agent instructions

For any change that affects the rendered blog, run the normal checks and the
local checkout's `make review` target when available. Verify the private review
succeeds, include its emitted URL in the final response, and do not push until
the user explicitly approves the push after that successful private review.

Never commit machine-specific paths, hostnames, addresses, network topology, or
credentials. Keep local integrations in the checkout's Git-local support area.
