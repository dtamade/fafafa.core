// Wide dot helpers intentionally stay on the base scalar slots until NEON owns
// a real implementation. Backend-local scalar forwarders add no runtime value
// and make dispatch ownership harder to audit.
