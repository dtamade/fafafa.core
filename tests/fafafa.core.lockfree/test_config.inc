{ Centralized test feature flags }

{$DEFINE FAFAFA_CORE_IFACE_FACTORIES}

{ Enable concurrency tests (per suite methods) }
{ $DEFINE FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS }

{ Enable queue test suites (classes and methods) }
{$DEFINE FAFAFA_CORE_ENABLE_QUEUE_TESTS}


{ Optional: enable 1-second real concurrency stress tests (disabled by default) }
{ $DEFINE FAFAFA_CORE_ENABLE_STRESS_TESTS }

{ Enable minimal concurrency smoke tests (very small, safe) }
{ $DEFINE FAFAFA_CORE_ENABLE_CONCURRENCY_SMOKE }
