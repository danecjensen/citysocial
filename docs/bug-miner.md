# Local bug miner

`bin/bug-mine` is a deterministic robustness and performance smoke suite for CitySocial. It runs three complementary fuzzers against the test database:

1. **Property fuzzing (PropCheck)** checks pure Elo, event fingerprint, and calendar-export invariants and shrinks failures.
2. **Public request fuzzing** sends malformed and extreme read-only requests, failing on exceptions, 5xx responses, slow requests, or excessive SQL.
3. **Stateful journey fuzzing** replays random pickup-sports joins, leaves, cancellations, capacity changes, and time changes against an in-memory oracle.

## Run it

```bash
bin/bug-mine
```

Run a longer campaign:

```bash
DEEP=1 bin/bug-mine
```

Reproduce a journey or request failure with the seed printed in its output. The same seed also fixes RSpec example order:

```bash
FUZZ_SEED=71945213 bin/bug-mine
```

PropCheck uses its own generator randomness and instead prints a shrunken counterexample. Copy that minimal input into a focused regression spec before fixing the defect.

Tune one dimension or budget:

```bash
PROP_CHECK_RUNS=2000 \
FUZZ_REQUESTS=1000 \
FUZZ_STEPS=1000 \
FUZZ_MAX_REQUEST_MS=750 \
FUZZ_MAX_SINGLE_REQUEST_MS=2500 \
FUZZ_MAX_SQL_QUERIES=60 \
bin/bug-mine
```

Defaults intentionally make the normal suite fast enough for `bin/verify`. Deep campaigns are for local bug mining rather than every edit.

## Diagnose a slow page

`rack-mini-profiler` is enabled in development. Open the affected HTML page locally to inspect request timing and SQL, then rerun the same fuzz seed after fixing it.

## Adding coverage

- Prefer invariants over “does not raise.”
- Use a local `Random` initialized from `FUZZ_SEED`; never use global randomness in stateful fuzzers.
- Put side-effect-free rules in PropCheck specs so failures shrink.
- Keep request fuzzing read-only and run state changes in the transactional test database.
- Include the seed, action/request, parameters, timing, and query count in every failure.
- Turn every discovered defect into a focused regression spec before fixing it.
